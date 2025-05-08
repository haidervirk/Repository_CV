from django.urls import path, include
from rest_framework import routers
from .views import create_user, get_user, update_user, delete_user

router = routers.DefaultRouter()

urlpatterns = [
  path('', include(router.urls)),
  path('create/', create_user, name='create_user'),
  path('<str:uid>/', get_user, name='get_user'),
  path('<str:uid>/update/', update_user, name='update_user'),
  path('<str:uid>/delete/', delete_user, name='delete_user'),
]