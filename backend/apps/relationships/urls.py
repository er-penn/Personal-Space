from django.urls import path
from rest_framework.routers import DefaultRouter
from apps.relationships import views

router = DefaultRouter()
# router.register(r'', views.RelationshipViewSet, basename='relationship')

urlpatterns = [
    # 关系管理
    path('invite/', views.invite_relationship, name='relationship-invite'),
    path('accept/', views.accept_relationship, name='relationship-accept'),
    path('', views.get_relationship, name='relationship-get'),
    path('end/', views.end_relationship, name='relationship-end'),
    
    # Maybe清单
    path('maybe-items/', views.get_maybe_items, name='maybe-items-list'),
    path('maybe-items/create/', views.create_maybe_item, name='maybe-items-create'),
    path('maybe-items/<uuid:item_id>/', views.update_maybe_item, name='maybe-items-update'),
    path('maybe-items/<uuid:item_id>/delete/', views.delete_maybe_item, name='maybe-items-delete'),
    
    # 成长花园
    path('growth-garden/', views.get_growth_garden, name='growth-garden-get'),
    path('growth-garden/water/', views.water_garden, name='growth-garden-water'),
]

