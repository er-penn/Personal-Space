from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.gift_boxes import views

router = DefaultRouter()

urlpatterns = [
    path('', views.create_gift_box, name='gift-box-create'),
    path('list/', views.list_gift_boxes, name='gift-box-list'),
    path('<uuid:gift_box_id>/respond/', views.respond_gift_box, name='gift-box-respond'),
    path('<uuid:gift_box_id>/withdraw/', views.withdraw_gift_box, name='gift-box-withdraw'),
]

