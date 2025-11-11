from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.db.models import Q
from apps.invitations.models import CollaborationInvitation
from apps.relationships.models import Relationship
from apps.websocket.utils import send_new_invitation


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_invitation(request):
    """创建协作邀请"""
    # 检查关系
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    partner = relationship.get_partner(request.user)
    
    invitation = CollaborationInvitation.objects.create(
        created_by=request.user,
        target_user=partner,
        title=request.data.get('title'),
        description=request.data.get('description', ''),
        start_time=request.data.get('start_time'),
        location=request.data.get('location', '')
    )
    
    # 发送WebSocket通知
    send_new_invitation(partner.id, {
        'invitation_id': str(invitation.id),
        'title': invitation.title
    })
    
    return Response({
        'id': str(invitation.id),
        'status': invitation.status,
        'created_at': invitation.created_at
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_invitations(request):
    """获取邀请列表"""
    invitation_type = request.query_params.get('type', 'all')  # sent/received/all
    
    if invitation_type == 'sent':
        invitations = CollaborationInvitation.objects.filter(created_by=request.user)
    elif invitation_type == 'received':
        invitations = CollaborationInvitation.objects.filter(target_user=request.user)
    else:
        invitations = CollaborationInvitation.objects.filter(
            models.Q(created_by=request.user) | models.Q(target_user=request.user)
        )
    
    data = [{
        'id': str(inv.id),
        'title': inv.title,
        'status': inv.status,
        'created_at': inv.created_at
    } for inv in invitations]
    
    return Response({'invitations': data})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def respond_invitation(request, invitation_id):
    """响应邀请"""
    invitation = CollaborationInvitation.objects.get(id=invitation_id)
    response = request.data.get('response')  # accepted/rejected
    
    if response == 'accepted':
        invitation.status = CollaborationInvitation.Status.ACCEPTED
    elif response == 'rejected':
        invitation.status = CollaborationInvitation.Status.REJECTED
    
    invitation.responded_at = timezone.now()
    invitation.save()
    
    return Response({'message': '响应已提交'})

