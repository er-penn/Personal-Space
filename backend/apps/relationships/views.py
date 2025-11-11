from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from apps.relationships.models import Relationship, MaybeItem, GrowthGarden


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invite_relationship(request):
    """发送关系邀请"""
    target_phone = request.data.get('target_phone')
    # 实现逻辑...
    return Response({'message': '邀请已发送'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accept_relationship(request):
    """接受关系邀请"""
    invitation_id = request.data.get('invitation_id')
    # 实现逻辑...
    return Response({'message': '关系已建立'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_relationship(request):
    """获取当前关系"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    return Response({
        'id': str(relationship.id),
        'status': relationship.status,
        'created_at': relationship.created_at
    })


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def end_relationship(request):
    """解除关系"""
    relationship = Relationship.get_active_relationship(request.user)
    if relationship:
        relationship.status = Relationship.Status.ENDED
        relationship.save()
    return Response({'message': '关系已解除'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_maybe_items(request):
    """获取Maybe清单"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response({'items': []})
    
    items = MaybeItem.objects.filter(relationship=relationship)
    data = [{
        'id': str(item.id),
        'title': item.title,
        'description': item.description,
        'location': item.location,
        'created_at': item.created_at
    } for item in items]
    
    return Response({'items': data})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_maybe_item(request):
    """创建Maybe清单项"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    item = MaybeItem.objects.create(
        relationship=relationship,
        created_by=request.user,
        title=request.data.get('title'),
        description=request.data.get('description', ''),
        location=request.data.get('location', '')
    )
    
    return Response({
        'id': str(item.id),
        'title': item.title
    })


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_maybe_item(request, item_id):
    """更新Maybe清单项"""
    item = MaybeItem.objects.get(id=item_id)
    # 权限检查...
    
    item.title = request.data.get('title', item.title)
    item.description = request.data.get('description', item.description)
    item.location = request.data.get('location', item.location)
    item.save()
    
    return Response({'message': '已更新'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_maybe_item(request, item_id):
    """删除Maybe清单项"""
    item = MaybeItem.objects.get(id=item_id)
    # 权限检查...
    item.delete()
    return Response({'message': '已删除'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_growth_garden(request):
    """获取成长花园状态"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    garden, created = GrowthGarden.objects.get_or_create(
        relationship=relationship,
        defaults={'plant_level': 1, 'water_level': 0}
    )
    
    return Response({
        'plant_level': garden.plant_level,
        'water_level': garden.water_level,
        'last_watered_at': garden.last_watered_at
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def water_garden(request):
    """浇水"""
    relationship = Relationship.get_active_relationship(request.user)
    if not relationship:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    garden, created = GrowthGarden.objects.get_or_create(
        relationship=relationship,
        defaults={'plant_level': 1, 'water_level': 0}
    )
    
    garden.water_level = min(10, garden.water_level + 1)
    garden.last_watered_at = timezone.now()
    garden.save()
    
    return Response({
        'water_level': garden.water_level,
        'last_watered_at': garden.last_watered_at
    })

