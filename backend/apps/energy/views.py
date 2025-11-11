from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from apps.users.models import User
from apps.energy.models import EnergyRecord
from apps.energy.services import EnergyService


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_energy_status(request):
    """获取当前能量状态"""
    user = request.user
    service = EnergyService()
    
    # 检查临时状态
    temporary_record = EnergyRecord.objects.filter(
        user=user,
        record_type=EnergyRecord.RecordType.TEMPORARY
    ).first()
    
    # 检查预规划状态
    planned_record = EnergyRecord.objects.filter(
        user=user,
        record_date=timezone.now().date(),
        record_type=EnergyRecord.RecordType.PLANNED
    ).first()
    
    data = {
        'current_energy_level': user.current_energy_level,
        'focus_mode_enabled': user.focus_mode_enabled,
        'temporary_state': {
            'is_active': temporary_record is not None,
            'type': temporary_record.temporary_type if temporary_record else None,
            'end_time': None  # 需要计算
        },
        'planned_state': {
            'is_active': planned_record is not None,
            'level': planned_record.energy_level if planned_record else None,
            'end_time': None  # 需要计算
        }
    }
    
    return Response(data)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_current_energy_level(request):
    """更新当前能量状态"""
    user = request.user
    energy_level = request.data.get('energy_level')
    
    if energy_level not in [choice[0] for choice in User.EnergyLevel.choices]:
        return Response(
            {'detail': '无效的能量状态'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user.current_energy_level = energy_level
    user.save()
    
    # 记录状态变更
    from apps.energy.models import EnergyLevelChange
    EnergyLevelChange.objects.create(
        user=user,
        change_time=timezone.now(),
        new_energy_level=energy_level,
        change_type='manual'
    )
    
    # 通知伴侣
    service = EnergyService()
    service._notify_partner_energy_change(user)
    
    return Response({
        'energy_level': user.current_energy_level,
        'updated_at': user.updated_at
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_temporary_state(request):
    """创建临时状态"""
    user = request.user
    temporary_type = request.data.get('type')  # fastCharge/lowPower
    duration_minutes = request.data.get('duration_minutes', 120)
    
    # 创建临时状态记录
    # 实现逻辑...
    
    return Response({'message': '临时状态已创建'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def end_temporary_state(request):
    """结束临时状态"""
    user = request.user
    # 实现逻辑...
    return Response({'message': '临时状态已结束'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_energy_plan(request):
    """创建能量预规划"""
    user = request.user
    # 实现逻辑...
    return Response({'message': '预规划已创建'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_energy_records(request):
    """获取能量状态记录"""
    user = request.user
    date = request.query_params.get('date')  # YYYY-MM-DD
    record_type = request.query_params.get('type')  # base/planned/temporary
    
    records = EnergyRecord.objects.filter(user=user)
    
    if date:
        records = records.filter(record_date=date)
    if record_type:
        records = records.filter(record_type=record_type)
    
    # 序列化返回
    data = []
    for record in records:
        data.append({
            'id': str(record.id),
            'record_date': record.record_date.isoformat(),
            'record_type': record.record_type,
            'energy_level': record.energy_level,
            'time_slots': record.time_slots
        })
    
    return Response({'records': data})

