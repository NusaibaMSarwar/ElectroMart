from django.contrib import admin
from .models import Category, Product


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'created_at')
    search_fields = ('name',)
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'category',
        'brand',
        'price',
        'stock',
        'rating',
        'is_available',
        'created_at',
    )
    list_filter = ('category', 'brand', 'is_available')
    search_fields = ('name', 'brand', 'description')
    prepopulated_fields = {'slug': ('name',)}