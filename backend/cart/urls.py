from django.urls import include, path
from rest_framework.routers import DefaultRouter
from .views import CartItemViewSet, WishlistItemViewSet

router = DefaultRouter()
router.register('cart', CartItemViewSet, basename='cart')
router.register('wishlist', WishlistItemViewSet, basename='wishlist')

urlpatterns = [
    path('', include(router.urls)),
]