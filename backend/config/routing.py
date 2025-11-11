"""
WebSocket路由配置
"""
from django.urls import path
from apps.websocket import consumers

websocket_urlpatterns = [
    path('ws/energy/', consumers.EnergyStatusConsumer.as_asgi()),
    path('ws/notifications/', consumers.NotificationConsumer.as_asgi()),
]

