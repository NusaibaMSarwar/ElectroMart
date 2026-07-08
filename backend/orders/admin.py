from django.contrib import admin
from .models import Order, OrderItem


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'product_name', 'price', 'quantity')


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'full_name',
        'phone',
        'status',
        'payment_method',
        'total_amount',
        'ordered_at',
    )
    list_filter = ('status', 'payment_method', 'ordered_at')
    search_fields = ('user__username', 'full_name', 'phone')
    readonly_fields = ('user', 'total_amount', 'ordered_at', 'updated_at')
    inlines = [OrderItemInline]


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('order', 'product_name', 'price', 'quantity')
    search_fields = ('product_name', 'order__user__username')