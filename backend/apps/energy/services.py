from django.db import models
from django.utils import timezone
from datetime import datetime, timedelta
from apps.energy.models import EnergyRecord, EnergyLevelChange
from apps.users.models import User
from apps.closures.models import PeacefulClosure
from apps.gift_boxes.models import GiftBox


class EnergyService:
    """能量状态服务"""
    
    def __init__(self):
        pass
    
    def check_and_append_base_state_time_slot(self, user):
        """检查并追加基础状态时间段"""
        from apps.websocket.utils import send_energy_level_changed
        
        now = timezone.now()
        today = now.date()
        current_hour = now.hour
        current_minute = now.minute
        
        # 获取今天的基础状态记录
        base_record, created = EnergyRecord.objects.get_or_create(
            user=user,
            record_date=today,
            record_type=EnergyRecord.RecordType.BASE,
            defaults={
                'energy_level': user.current_energy_level,
                'time_slots': []
            }
        )
        
        # 检查是否需要追加时间段
        if base_record.time_slots:
            last_slot = base_record.time_slots[-1]
            last_end_hour = last_slot.get('end_hour', 7)
            last_end_minute = last_slot.get('end_minute', 0)
            
            # 如果当前时间已经超过最后时间段，需要追加
            if (current_hour > last_end_hour or 
                (current_hour == last_end_hour and current_minute >= last_end_minute)):
                # 追加新的时间段
                new_slot = {
                    'start_hour': last_end_hour,
                    'start_minute': last_end_minute,
                    'end_hour': current_hour,
                    'end_minute': current_minute
                }
                base_record.time_slots.append(new_slot)
                base_record.energy_level = user.current_energy_level
                base_record.save()
        
        # 通知伴侣状态变更
        self._notify_partner_energy_change(user)
    
    def check_and_update_planned_state(self, user):
        """检查并更新预规划状态"""
        now = timezone.now()
        today = now.date()
        current_hour = now.hour
        current_minute = now.minute
        
        # 查找当前时间的预规划状态
        planned_records = EnergyRecord.objects.filter(
            user=user,
            record_date=today,
            record_type=EnergyRecord.RecordType.PLANNED
        )
        
        for record in planned_records:
            for slot in record.time_slots:
                start_hour = slot.get('start_hour', 0)
                start_minute = slot.get('start_minute', 0)
                end_hour = slot.get('end_hour', 23)
                end_minute = slot.get('end_minute', 59)
                
                # 检查当前时间是否在预规划时间段内
                if self._is_time_in_slot(current_hour, current_minute, 
                                         start_hour, start_minute, 
                                         end_hour, end_minute):
                    # 更新用户显示状态（这里可以添加逻辑）
                    pass
    
    def update_minute_countdowns(self, user):
        """更新分钟级倒计时"""
        # 检查临时状态倒计时
        temporary_records = EnergyRecord.objects.filter(
            user=user,
            record_type=EnergyRecord.RecordType.TEMPORARY
        )
        
        for record in temporary_records:
            # 检查是否到期（这里需要根据实际需求实现）
            pass
    
    def reset_daily_state(self, user):
        """重置每日状态"""
        user.current_energy_level = User.EnergyLevel.UNPLANNED
        user.save()
        
        # 记录状态变更
        EnergyLevelChange.objects.create(
            user=user,
            change_time=timezone.now(),
            new_energy_level=User.EnergyLevel.UNPLANNED,
            change_type='auto'
        )
    
    def _is_time_in_slot(self, hour, minute, start_hour, start_minute, end_hour, end_minute):
        """检查时间是否在时间段内"""
        current_minutes = hour * 60 + minute
        start_minutes = start_hour * 60 + start_minute
        end_minutes = end_hour * 60 + end_minute
        return start_minutes <= current_minutes <= end_minutes
    
    def _notify_partner_energy_change(self, user):
        """通知伴侣能量状态变更"""
        from apps.relationships.models import Relationship
        from apps.websocket.utils import send_energy_level_changed
        
        relationship = Relationship.get_active_relationship(user)
        if relationship:
            partner = relationship.get_partner(user)
            send_energy_level_changed(partner.id, user.current_energy_level)

