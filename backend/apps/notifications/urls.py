from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.notifications import views

router = DefaultRouter()

urlpatterns = [
    path('', views.list_notifications, name='notification-list'),
    path('<uuid:notification_id>/read/', views.mark_notification_read, name='notification-read'),
    path('<uuid:notification_id>/', views.delete_notification, name='notification-delete'),
]

