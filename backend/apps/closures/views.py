from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.db.models import Q
from apps.closures.models import PeacefulClosure
from apps.relationships.models import Relationship
from apps.websocket.utils import send_new_closure


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_closure(request):
    """创建安心确认"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    partner = relationship.get_partner(request.user)
    
    closure = PeacefulClosure.objects.create(
        created_by=request.user,
        target_user=partner,
        closure_type=request.data.get('type'),
        title=request.data.get('title'),
        content=request.data.get('content'),
        item_details=request.data.get('item_details'),
        has_expiration=request.data.get('has_expiration', False),
        expires_at=request.data.get('expires_at')
    )
    
    # 发送WebSocket通知
    send_new_closure(partner.id, {
        'closure_id': str(closure.id),
        'title': closure.title
    })
    
    return Response({
        'id': str(closure.id),
        'status': closure.status
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_closures(request):
    """获取安心确认列表"""
    closure_type = request.query_params.get('type', 'all')
    
    if closure_type == 'sent':
        closures = PeacefulClosure.objects.filter(created_by=request.user)
    elif closure_type == 'received':
        closures = PeacefulClosure.objects.filter(target_user=request.user)
    else:
        closures = PeacefulClosure.objects.filter(
            models.Q(created_by=request.user) | models.Q(target_user=request.user)
        )
    
    data = [{
        'id': str(c.id),
        'title': c.title,
        'status': c.status,
        'created_at': c.created_at
    } for c in closures]
    
    return Response({'closures': data})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def respond_closure(request, closure_id):
    """响应安心确认"""
    closure = PeacefulClosure.objects.get(id=closure_id)
    response_type = request.data.get('response_type')  # noted/gotIt/later
    content = request.data.get('content', '')
    
    closure.response = {
        'content': content,
        'timestamp': timezone.now().isoformat(),
        'isFinal': True
    }
    closure.status = PeacefulClosure.Status.COMPLETED
    closure.responded_at = timezone.now()
    closure.save()
    
    return Response({'message': '响应已提交'})

