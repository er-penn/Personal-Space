from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import datetime, timedelta
from apps.users.models import User
from apps.energy.models import EnergyRecord, EnergyLevelChange
from apps.energy.services import EnergyService
from apps.energy.serializers import EnergyRecordSerializer


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def current_energy_status(request):
    """获取或更新当前能量状态"""
    if request.method == 'GET':
        return get_current_energy_status(request)
    else:  # PUT
        return update_current_energy_level(request)


def get_current_energy_status(request):
    """获取当前能量状态"""
    user = request.user
    service = EnergyService()
    
    current_status = service.get_current_status(user)
    
    # 获取伴侣状态
    partner_status = service.get_partner_status(user)
    partner_energy_level = partner_status['energy_level'] if partner_status else None
    
    data = {
        'current_status': {
            'base_energy_level': current_status['base_energy_level'],
            'display_energy_level': current_status['display_energy_level'],
            'temporary_state': {
                'is_active': current_status['temporary_state']['is_active'],
                'type': current_status['temporary_state']['type'],
                'remaining_minutes': current_status['temporary_state']['remaining_minutes']
            },
            'planned_state': {
                'is_active': current_status['planned_state']['is_active'],
                'level': current_status['planned_state']['level'],
                'remaining_minutes': current_status['planned_state']['remaining_minutes']
            }
        },
        'partner_status': {
            'energy_level': partner_energy_level
        } if partner_energy_level else None
    }
    
    return Response(data)


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
        'updated_at': user.updated_at.isoformat()
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_temporary_state(request):
    """创建临时状态"""
    user = request.user
    temporary_type = request.data.get('type')  # fastCharge/lowPower
    duration_minutes = request.data.get('duration_minutes', 120)
    
    if temporary_type not in ['fastCharge', 'lowPower']:
        return Response(
            {'detail': '无效的临时状态类型'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if duration_minutes <= 0 or duration_minutes > 1440:  # 最多24小时
        return Response(
            {'detail': '持续时间必须在1-1440分钟之间'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    now = timezone.now()
    today = now.date()
    current_hour = now.hour
    current_minute = now.minute
    
    # 计算结束时间
    end_datetime = now + timedelta(minutes=duration_minutes)
    end_hour = end_datetime.hour
    end_minute = end_datetime.minute
    
    # 确定能量等级
    if temporary_type == 'fastCharge':
        energy_level = EnergyRecord.EnergyLevel.HIGH
    else:  # lowPower
        energy_level = EnergyRecord.EnergyLevel.LOW
    
    # 创建临时状态记录
    temporary_record = EnergyRecord.objects.create(
        user=user,
        record_date=today,
        record_type=EnergyRecord.RecordType.TEMPORARY,
        energy_level=energy_level,
        temporary_type=temporary_type,
        original_energy_level=user.current_energy_level,
        time_slots=[{
            'start_hour': current_hour,
            'start_minute': current_minute,
            'end_hour': end_hour,
            'end_minute': end_minute
        }]
    )
    
    # 记录状态变更
    EnergyLevelChange.objects.create(
        user=user,
        change_time=now,
        new_energy_level=energy_level,
        change_type='temporary'
    )
    
    # 通知伴侣
    service = EnergyService()
    service._notify_partner_energy_change(user)
    
    return Response({
        'id': str(temporary_record.id),
        'type': temporary_type,
        'start_time': now.isoformat(),
        'end_time': end_datetime.isoformat(),
        'remaining_minutes': duration_minutes
    }, status=status.HTTP_201_CREATED)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def end_temporary_state(request):
    """结束临时状态"""
    user = request.user
    temporary_id = request.data.get('id')  # 可选的临时状态ID
    
    now = timezone.now()
    current_hour = now.hour
    current_minute = now.minute
    
    # 查找当前激活的临时状态
    if temporary_id:
        temporary_record = EnergyRecord.objects.filter(
            id=temporary_id,
            user=user,
            record_type=EnergyRecord.RecordType.TEMPORARY
        ).first()
    else:
        # 查找当前时间范围内的临时状态
        temporary_records = EnergyRecord.objects.filter(
            user=user,
            record_type=EnergyRecord.RecordType.TEMPORARY
        ).order_by('-created_at')
        
        temporary_record = None
        for record in temporary_records:
            for slot in record.time_slots:
                start_hour = slot.get('start_hour', 0)
                start_minute = slot.get('start_minute', 0)
                end_hour = slot.get('end_hour', 23)
                end_minute = slot.get('end_minute', 59)
                
                service = EnergyService()
                if service._is_time_in_slot(current_hour, current_minute,
                                          start_hour, start_minute,
                                          end_hour, end_minute):
                    temporary_record = record
                    break
            
            if temporary_record:
                break
    
    if not temporary_record:
        return Response(
            {'detail': '未找到激活的临时状态'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # 更新时间段，提前结束
    updated_slots = []
    for slot in temporary_record.time_slots:
        end_hour = slot.get('end_hour', 23)
        end_minute = slot.get('end_minute', 59)
        
        # 如果时间段还未结束，更新为当前时间
        if (current_hour < end_hour or 
            (current_hour == end_hour and current_minute < end_minute)):
            slot['end_hour'] = current_hour
            slot['end_minute'] = current_minute
        
        updated_slots.append(slot)
    
    temporary_record.time_slots = updated_slots
    temporary_record.save()
    
    # 记录状态变更（恢复到原始状态）
    if temporary_record.original_energy_level:
        EnergyLevelChange.objects.create(
            user=user,
            change_time=now,
            new_energy_level=temporary_record.original_energy_level,
            change_type='temporary'
        )
    
    # 通知伴侣
    service = EnergyService()
    service._notify_partner_energy_change(user)
    
    return Response({'message': '临时状态已结束'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_energy_plans(request):
    """获取能量预规划"""
    user = request.user
    date_str = request.query_params.get('date')  # YYYY-MM-DD
    
    if date_str:
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'detail': '日期格式错误，请使用YYYY-MM-DD格式'},
                status=status.HTTP_400_BAD_REQUEST
            )
    else:
        target_date = timezone.now().date()
    
    planned_records = EnergyRecord.objects.filter(
        user=user,
        record_date=target_date,
        record_type=EnergyRecord.RecordType.PLANNED
    ).order_by('created_at')
    
    plans = []
    for record in planned_records:
        plans.append({
            'id': str(record.id),
            'date': record.record_date.isoformat(),
            'energy_level': record.energy_level,
            'time_slots': record.time_slots,
            'created_at': record.created_at.isoformat()
        })
    
    return Response({'plans': plans})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_energy_plan(request):
    """创建能量预规划"""
    user = request.user
    date_str = request.data.get('date')
    energy_level = request.data.get('energy_level')
    time_slots = request.data.get('time_slots', [])
    
    # 验证日期
    if date_str:
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'detail': '日期格式错误，请使用YYYY-MM-DD格式'},
                status=status.HTTP_400_BAD_REQUEST
            )
    else:
        target_date = timezone.now().date()
    
    # 验证能量等级
    if energy_level not in [choice[0] for choice in EnergyRecord.EnergyLevel.choices]:
        return Response(
            {'detail': '无效的能量状态'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # 验证时间段
    if not time_slots or not isinstance(time_slots, list):
        return Response(
            {'detail': '时间段列表不能为空'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # 验证每个时间段
    for slot in time_slots:
        required_fields = ['start_hour', 'start_minute', 'end_hour', 'end_minute']
        if not all(field in slot for field in required_fields):
            return Response(
                {'detail': f'时间段缺少必需字段: {required_fields}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 验证时间范围
        if not (0 <= slot['start_hour'] <= 23 and 0 <= slot['end_hour'] <= 23):
            return Response(
                {'detail': '小时数必须在0-23之间'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not (0 <= slot['start_minute'] <= 59 and 0 <= slot['end_minute'] <= 59):
            return Response(
                {'detail': '分钟数必须在0-59之间'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 验证时间段有效性
        start_minutes = slot['start_hour'] * 60 + slot['start_minute']
        end_minutes = slot['end_hour'] * 60 + slot['end_minute']
        
        if start_minutes >= end_minutes:
            return Response(
                {'detail': '开始时间必须早于结束时间'},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    # 获取或创建预规划记录（同一天只能有一条）
    planned_record, created = EnergyRecord.objects.get_or_create(
        user=user,
        record_date=target_date,
        record_type=EnergyRecord.RecordType.PLANNED,
        defaults={
            'energy_level': energy_level,
            'time_slots': time_slots
        }
    )
    
    if not created:
        # 更新现有记录
        planned_record.energy_level = energy_level
        planned_record.time_slots = time_slots
        planned_record.save()
    
    return Response({
        'id': str(planned_record.id),
        'date': planned_record.record_date.isoformat(),
        'energy_level': planned_record.energy_level,
        'time_slots': planned_record.time_slots,
        'created_at': planned_record.created_at.isoformat()
    }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_energy_records(request):
    """获取能量状态记录"""
    user = request.user
    date_str = request.query_params.get('date')  # YYYY-MM-DD
    record_type = request.query_params.get('type')  # base/planned/temporary
    
    if date_str:
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'detail': '日期格式错误，请使用YYYY-MM-DD格式'},
                status=status.HTTP_400_BAD_REQUEST
            )
    else:
        target_date = timezone.now().date()
    
    service = EnergyService()
    result = service.get_energy_records(user, target_date=target_date, record_type=record_type)
    
    return Response(result)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_partner_status(request):
    """获取伴侣能量状态"""
    user = request.user
    service = EnergyService()
    
    partner_status = service.get_partner_status(user)
    
    if not partner_status:
        return Response(
            {'detail': '未找到活跃的关系'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    return Response({
        'partner_status': partner_status
    })
