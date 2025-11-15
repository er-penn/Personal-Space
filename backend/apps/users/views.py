from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from apps.users.models import User
from apps.users.serializers import UserSerializer, UserUpdateSerializer, UserCreateSerializer
from apps.relationships.models import Relationship


class UserViewSet(viewsets.ModelViewSet):
    """用户视图集"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return User.objects.filter(id=self.request.user.id)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """获取当前用户信息"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put', 'patch'])
    def update_me(self, request):
        """更新当前用户信息"""
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        # 如果更新了能量状态，通知伴侣
        if 'current_energy_level' in serializer.validated_data:
            self._notify_partner_energy_change(request.user)
        
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def partner(self, request):
        """获取伴侣信息"""
        relationship = Relationship.get_active_relationship(request.user)
        if not relationship:
            return Response(
                {'detail': '未找到活跃的关系'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        partner = relationship.get_partner(request.user)
        serializer = self.get_serializer(partner)
        return Response(serializer.data)
    
    def _notify_partner_energy_change(self, user):
        """通知伴侣能量状态变更"""
        from apps.websocket.utils import send_energy_level_changed
        
        relationship = Relationship.get_active_relationship(user)
        if relationship:
            partner = relationship.get_partner(user)
            send_energy_level_changed(partner.id, user.current_energy_level)


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """用户注册"""
    serializer = UserCreateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    
    return Response({
        'id': str(user.id),
        'phone': user.phone,
        'nickname': user.nickname,
        'message': '注册成功'
    }, status=status.HTTP_201_CREATED)

