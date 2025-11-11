from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.db.models import Q
from apps.gift_boxes.models import GiftBox
from apps.relationships.models import Relationship
from apps.websocket.utils import send_new_gift_box


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_gift_box(request):
    """创建心意盒"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    partner = relationship.get_partner(request.user)
    
    gift_box = GiftBox.objects.create(
        created_by=request.user,
        target_user=partner,
        item=request.data.get('item'),
        note=request.data.get('note', ''),
        suggested_location=request.data.get('suggested_location'),
        preparation_time=request.data.get('preparation_time'),
        has_expiration=request.data.get('has_expiration', False),
        expires_at=request.data.get('expires_at')
    )
    
    # 发送WebSocket通知
    send_new_gift_box(partner.id, {
        'gift_box_id': str(gift_box.id),
        'item': gift_box.item
    })
    
    return Response({
        'id': str(gift_box.id),
        'status': gift_box.status
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_gift_boxes(request):
    """获取心意盒列表"""
    gift_box_type = request.query_params.get('type', 'all')
    
    if gift_box_type == 'sent':
        gift_boxes = GiftBox.objects.filter(created_by=request.user)
    elif gift_box_type == 'received':
        gift_boxes = GiftBox.objects.filter(target_user=request.user)
    else:
        gift_boxes = GiftBox.objects.filter(
            models.Q(created_by=request.user) | models.Q(target_user=request.user)
        )
    
    data = [{
        'id': str(gb.id),
        'item': gb.item,
        'status': gb.status,
        'created_at': gb.created_at
    } for gb in gift_boxes]
    
    return Response({'gift_boxes': data})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def respond_gift_box(request, gift_box_id):
    """响应心意盒"""
    gift_box = GiftBox.objects.get(id=gift_box_id)
    response = request.data.get('response')  # accepted/rejected
    
    if response == 'accepted':
        gift_box.status = GiftBox.Status.ACCEPTED
        gift_box.accepted_info = request.data.get('accepted_info')
    elif response == 'rejected':
        gift_box.status = GiftBox.Status.REJECTED
    
    gift_box.response = response
    gift_box.responded_at = timezone.now()
    gift_box.save()
    
    return Response({'message': '响应已提交'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def withdraw_gift_box(request, gift_box_id):
    """撤回心意盒"""
    gift_box = GiftBox.objects.get(id=gift_box_id)
    
    if gift_box.created_by != request.user:
        return Response(
            {'detail': '无权撤回'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    if gift_box.status != GiftBox.Status.PENDING:
        return Response(
            {'detail': '只能撤回待确认的心意盒'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    gift_box.is_withdrawn = True
    gift_box.status = GiftBox.Status.WITHDRAWN
    gift_box.save()
    
    return Response({'message': '心意盒已撤回'})

