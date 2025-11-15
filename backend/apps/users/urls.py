from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from apps.users.views import UserViewSet, register

router = DefaultRouter()
router.register(r'', UserViewSet, basename='user')

urlpatterns = [
    # JWT认证
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', register, name='register'),
    
    # 用户相关
    path('me/', UserViewSet.as_view({'get': 'me'}), name='user-me'),
    path('me/update/', UserViewSet.as_view({'put': 'update_me', 'patch': 'update_me'}), name='user-update-me'),
    path('partner/', UserViewSet.as_view({'get': 'partner'}), name='user-partner'),
]

