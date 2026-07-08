from django.db.models import Avg
from rest_framework import permissions, viewsets
from rest_framework.exceptions import PermissionDenied
from orders.models import OrderItem
from .models import Review
from .serializers import ReviewSerializer


class ReviewViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Review.objects.all()

    def perform_create(self, serializer):
        product = serializer.validated_data['product']

        has_purchased = OrderItem.objects.filter(
            order__user=self.request.user,
            order__status='delivered',
            product=product
        ).exists()

        if not has_purchased:
            raise PermissionDenied(
                'Only verified buyers with delivered orders can review this product.'
            )

        review = serializer.save(user=self.request.user)
        self.update_product_rating(review.product)

    def perform_update(self, serializer):
        review = serializer.save()
        self.update_product_rating(review.product)

    def perform_destroy(self, instance):
        product = instance.product
        instance.delete()
        self.update_product_rating(product)

    def update_product_rating(self, product):
        average_rating = product.reviews.aggregate(
            average=Avg('rating')
        )['average'] or 0
        product.rating = round(average_rating, 2)
        product.save()