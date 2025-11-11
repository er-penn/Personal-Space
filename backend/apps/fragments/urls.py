from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.fragments import views

router = DefaultRouter()

urlpatterns = [
    path('', views.create_fragment, name='fragment-create'),
    path('list/', views.list_fragments, name='fragment-list'),
    path('<uuid:fragment_id>/read/', views.mark_fragment_read, name='fragment-read'),
    path('<uuid:fragment_id>/withdraw/', views.withdraw_fragment, name='fragment-withdraw'),
]

