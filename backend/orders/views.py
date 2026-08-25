from django.contrib.auth.models import User
from django.db import transaction
from django.db.models import Count, Sum
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from cart.models import CartItem
from products.models import Product
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
        confirmed = Order.objects.filter(
            status=Order.STATUS_CONFIRMED
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
            'confirmed_orders': confirmed_orders,
            'total_revenue': total_revenue,
            'total_products_sold': total_products_sold,
        })
    
class AdminDashboardView(generics.GenericAPIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        status_counts = {
            item['status']: item['total']
            for item in Order.objects.values('status').annotate(total=Count('id'))
        }

        products = Product.objects.select_related('category').values(
            'id',
            'name',
            'brand',
            'category__name',
            'price',
            'stock',
            'is_available',
        )

        users = User.objects.annotate(order_count=Count('orders')).values(
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'is_staff',
            'order_count',
            'date_joined',
        )

        orders = Order.objects.prefetch_related('items').all()
        order_list = []

        for order in orders:
            order_list.append({
                'id': order.id,
                'username': order.user.username,
                'full_name': order.full_name,
                'phone': order.phone,
                'address': order.address,
                'payment_method': order.payment_method,
                'status': order.status,
                'total_amount': order.total_amount,
                'ordered_at': order.ordered_at,
                'items': list(order.items.values(
                    'product_name',
                    'price',
                    'quantity',
                )),
            })

        total_revenue = Order.objects.filter(
            status=Order.STATUS_DELIVERED
        ).aggregate(total=Sum('total_amount'))['total'] or 0

        return Response({
            'total_products': Product.objects.count(),
            'available_products': Product.objects.filter(is_available=True).count(),
            'low_stock_products': Product.objects.filter(stock__lte=5).count(),

            'confirmed_orders': status_counts.get(Order.STATUS_CONFIRMED, 0),
            'processing_orders': status_counts.get(Order.STATUS_PROCESSING, 0),
            'shipped_orders': status_counts.get(Order.STATUS_SHIPPED, 0),
            'in_transit_orders': status_counts.get(Order.STATUS_IN_TRANSIT, 0),
            'delivered_orders': status_counts.get(Order.STATUS_DELIVERED, 0),

            'registered_users': User.objects.filter(is_staff=False).count(),
            'admin_users': User.objects.filter(is_staff=True).count(),
            'users_with_orders': User.objects.annotate(
                order_count=Count('orders')
            ).filter(order_count__gt=0, is_staff=False).count(),
            'users_without_orders': User.objects.annotate(
                order_count=Count('orders')
            ).filter(order_count=0, is_staff=False).count(),

            'total_revenue': total_revenue,
            'products': list(products),
            'users': list(users),
            'orders': order_list,
        })


class AdminOrderStatusUpdateView(generics.GenericAPIView):
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return Response(
                {'detail': 'Order not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        new_status = request.data.get('status')

        valid_statuses = [
            Order.STATUS_CONFIRMED,
            Order.STATUS_PROCESSING,
            Order.STATUS_SHIPPED,
            Order.STATUS_IN_TRANSIT,
            Order.STATUS_DELIVERED,
        ]

        if new_status not in valid_statuses:
            return Response(
                {'detail': 'Invalid status.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        order.status = new_status
        order.save()

        return Response({
            'id': order.id,
            'status': order.status,
            'detail': 'Order status updated successfully.',
        })