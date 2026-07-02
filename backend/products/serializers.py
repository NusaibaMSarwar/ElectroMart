from rest_framework import serializers
from .models import Category, Product


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'description']


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Product
        fields = [
            'id',
            'category',
            'category_id',
            'name',
            'slug',
            'brand',
            'description',
            'price',
            'stock',
            'image',
            'rating',
            'is_available',
            'created_at',
            'updated_at',
        ]