from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.moments import views

router = DefaultRouter()

urlpatterns = [
    path('', views.create_moment, name='moment-create'),
    path('list/', views.list_moments, name='moment-list'),
]

