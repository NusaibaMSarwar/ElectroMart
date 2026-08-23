from django.urls import path
from .views import CheckoutView, InvoiceDetailView, OrderDetailView, OrderListView, SalesReportView, AdminDashboardView, AdminOrderStatusUpdateView

urlpatterns = [
    path('checkout/', CheckoutView.as_view(), name='checkout'),
    path('orders/', OrderListView.as_view(), name='order-list'),
    path('orders/<int:pk>/', OrderDetailView.as_view(), name='order-detail'),
    path('orders/<int:pk>/invoice/', InvoiceDetailView.as_view(), name='order-invoice'),
    path('admin/sales-report/', SalesReportView.as_view(), name='sales-report'),
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
path('admin/orders/<int:pk>/status/', AdminOrderStatusUpdateView.as_view(), name='admin-order-status-update'),
]