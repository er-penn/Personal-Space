"""
URL configuration for boundary_capsule project.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # API文档
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    
    # API路由
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/users/', include('apps.users.urls')),
    path('api/v1/relationships/', include('apps.relationships.urls')),
    path('api/v1/energy/', include('apps.energy.urls')),
    path('api/v1/invitations/', include('apps.invitations.urls')),
    path('api/v1/peaceful-closures/', include('apps.closures.urls')),
    path('api/v1/gift-boxes/', include('apps.gift_boxes.urls')),
    path('api/v1/fragments/', include('apps.fragments.urls')),
    path('api/v1/moments/', include('apps.moments.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),
    path('api/v1/maybe-items/', include('apps.relationships.urls')),  # Maybe清单在relationships app中
    path('api/v1/growth-garden/', include('apps.relationships.urls')),  # 成长花园在relationships app中
]

