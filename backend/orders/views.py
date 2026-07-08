from django.db import transaction
from django.db.models import Sum
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from cart.models import CartItem
from .models import Order, OrderItem
from .serializers import CheckoutSerializer, OrderSerializer


class OrderListView(generics.ListAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user)


class OrderDetailView(generics.RetrieveAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user)


class CheckoutView(generics.GenericAPIView):
    serializer_class = CheckoutSerializer
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        cart_items = CartItem.objects.filter(user=request.user)

        if not cart_items.exists():
            return Response(
                {'detail': 'Cart is empty.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        order = Order.objects.create(
            user=request.user,
            full_name=serializer.validated_data['full_name'],
            phone=serializer.validated_data['phone'],
            address=serializer.validated_data['address'],
        )

        total_amount = 0

        for cart_item in cart_items:
            product = cart_item.product

            if product.stock < cart_item.quantity:
                return Response(
                    {'detail': f'Not enough stock for {product.name}.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            OrderItem.objects.create(
                order=order,
                product=product,
                product_name=product.name,
                price=product.price,
                quantity=cart_item.quantity,
            )

            total_amount += product.price * cart_item.quantity
            product.stock -= cart_item.quantity
            product.save()

        order.total_amount = total_amount
        order.save()

        cart_items.delete()

        return Response(
            OrderSerializer(order).data,
            status=status.HTTP_201_CREATED
        )
class InvoiceDetailView(generics.RetrieveAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user)
    
class SalesReportView(generics.GenericAPIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        total_orders = Order.objects.count()
        delivered_orders = Order.objects.filter(
            status=Order.STATUS_DELIVERED
        ).count()
        pending_orders = Order.objects.filter(
            status=Order.STATUS_PENDING
        ).count()

        total_revenue = Order.objects.filter(
            status=Order.STATUS_DELIVERED
        ).aggregate(total=Sum('total_amount'))['total'] or 0

        total_products_sold = OrderItem.objects.filter(
            order__status=Order.STATUS_DELIVERED
        ).aggregate(total=Sum('quantity'))['total'] or 0

        return Response({
            'total_orders': total_orders,
            'delivered_orders': delivered_orders,
            'pending_orders': pending_orders,
            'total_revenue': total_revenue,
            'total_products_sold': total_products_sold,
        })