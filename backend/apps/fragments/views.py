from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.db.models import Q
from apps.fragments.models import Fragment
from apps.relationships.models import Relationship
from apps.websocket.utils import send_new_fragment


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_fragment(request):
    """发送碎片"""
    # 检查今日发送数量（最多2个）
    today = timezone.now().date()
    today_count = Fragment.objects.filter(
        created_by=request.user,
        created_at__date=today
    ).count()
    
    if today_count >= 2:
        return Response(
            {'detail': '今日已发送2个碎片，请明天再试'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    partner = relationship.get_partner(request.user)
    
    fragment = Fragment.objects.create(
        created_by=request.user,
        target_user=partner,
        content=request.data.get('content'),
        image_url=request.data.get('image_url'),
        link_url=request.data.get('link_url')
    )
    
    # 发送WebSocket通知（可选，根据用户设置）
    send_new_fragment(partner.id, {
        'fragment_id': str(fragment.id),
        'content': fragment.content[:50]  # 预览
    })
    
    return Response({
        'id': str(fragment.id),
        'created_at': fragment.created_at
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_fragments(request):
    """获取碎片列表"""
    fragment_type = request.query_params.get('type', 'all')
    
    if fragment_type == 'sent':
        fragments = Fragment.objects.filter(created_by=request.user)
    elif fragment_type == 'received':
        fragments = Fragment.objects.filter(target_user=request.user)
    else:
        fragments = Fragment.objects.filter(
            Q(created_by=request.user) | Q(target_user=request.user)
        )
    
    data = [{
        'id': str(f.id),
        'content': f.content,
        'is_read': f.is_read,
        'created_at': f.created_at
    } for f in fragments]
    
    return Response({'fragments': data})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_fragment_read(request, fragment_id):
    """标记碎片为已读"""
    fragment = Fragment.objects.get(id=fragment_id)
    
    if fragment.target_user != request.user:
        return Response(
            {'detail': '无权操作'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    fragment.is_read = True
    fragment.read_at = timezone.now()
    fragment.save()
    
    return Response({'message': '已标记为已读'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def withdraw_fragment(request, fragment_id):
    """撤回碎片（仅未读可撤回）"""
    fragment = Fragment.objects.get(id=fragment_id)
    
    if fragment.created_by != request.user:
        return Response(
            {'detail': '无权撤回'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    if fragment.is_read:
        return Response(
            {'detail': '对方已读，无法撤回'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    fragment.is_withdrawn = True
    fragment.save()
    
    return Response({'message': '碎片已撤回'})

