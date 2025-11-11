from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.closures import views

router = DefaultRouter()

urlpatterns = [
    path('', views.create_closure, name='closure-create'),
    path('list/', views.list_closures, name='closure-list'),
    path('<uuid:closure_id>/respond/', views.respond_closure, name='closure-respond'),
]

