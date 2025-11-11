from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from apps.moments.models import Moment


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_moment(request):
    """发布瞬间"""
    moment = Moment.objects.create(
        created_by=request.user,
        content=request.data.get('content'),
        images=request.data.get('images', []),
        is_text_hidden=request.data.get('is_text_hidden', True)
    )
    
    return Response({
        'id': str(moment.id),
        'created_at': moment.created_at
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_moments(request):
    """获取瞬间列表"""
    moment_type = request.query_params.get('type', 'all')  # mine/partner/all
    
    if moment_type == 'mine':
        moments = Moment.objects.filter(created_by=request.user)
    elif moment_type == 'partner':
        from apps.relationships.models import Relationship
        relationship = Relationship.get_active_relationship(request.user)
        if relationship:
            partner = relationship.get_partner(request.user)
            moments = Moment.objects.filter(created_by=partner)
        else:
            moments = Moment.objects.none()
    else:
        moments = Moment.objects.all()
    
    data = [{
        'id': str(m.id),
        'content': m.content if m.should_show_text else '',
        'images': m.images,
        'is_text_hidden': m.is_text_hidden,
        'remaining_hidden_days': m.remaining_hidden_days,
        'created_at': m.created_at
    } for m in moments]
    
    return Response({'moments': data})

