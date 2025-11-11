from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from apps.notifications.models import Notification


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_notifications(request):
    """获取通知列表"""
    category = request.query_params.get('category')  # info/reminder
    is_read = request.query_params.get('is_read')  # true/false
    
    notifications = Notification.objects.filter(user=request.user)
    
    if category:
        notifications = notifications.filter(category=category)
    if is_read is not None:
        notifications = notifications.filter(is_read=is_read == 'true')
    
    data = [{
        'id': str(n.id),
        'category': n.category,
        'type': n.type,
        'title': n.title,
        'content': n.content,
        'is_read': n.is_read,
        'created_at': n.created_at
    } for n in notifications]
    
    return Response({'notifications': data})


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """标记通知为已读"""
    notification = Notification.objects.get(id=notification_id)
    
    if notification.user != request.user:
        return Response(
            {'detail': '无权操作'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    notification.is_read = True
    notification.read_at = timezone.now()
    notification.save()
    
    return Response({'message': '已标记为已读'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_notification(request, notification_id):
    """删除通知"""
    notification = Notification.objects.get(id=notification_id)
    
    if notification.user != request.user:
        return Response(
            {'detail': '无权操作'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    notification.delete()
    return Response({'message': '通知已删除'})

