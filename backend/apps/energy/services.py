from django.db import models
from django.utils import timezone
from datetime import datetime, timedelta, date
from apps.energy.models import EnergyRecord, EnergyLevelChange
from apps.users.models import User
from apps.closures.models import PeacefulClosure
from apps.gift_boxes.models import GiftBox
from apps.relationships.models import Relationship


class EnergyService:
    """能量状态服务"""
    
    def __init__(self):
        pass
    
    def get_current_status(self, user):
        """获取当前能量状态（包含临时状态和预规划状态）"""
        now = timezone.now()
        today = now.date()
        current_hour = now.hour
        current_minute = now.minute
        
        # 1. 获取基础能量状态
        base_energy_level = user.current_energy_level
        
        # 2. 检查临时状态（优先级最高）
        temporary_state = self._get_active_temporary_state(user, now)
        
        # 3. 检查预规划状态（优先级次之）
        planned_state = self._get_active_planned_state(user, today, current_hour, current_minute)
        
        # 4. 计算显示能量状态（优先级：临时状态 > 预规划状态 > 基础状态）
        if temporary_state['is_active']:
            display_energy_level = temporary_state['level']
        elif planned_state['is_active']:
            display_energy_level = planned_state['level']
        else:
            display_energy_level = base_energy_level
        
        return {
            'base_energy_level': base_energy_level,
            'display_energy_level': display_energy_level,
            'temporary_state': temporary_state,
            'planned_state': planned_state
        }
    
    def _get_active_temporary_state(self, user, now):
        """获取当前激活的临时状态"""
        # 查找所有未结束的临时状态记录
        temporary_records = EnergyRecord.objects.filter(
            user=user,
            record_type=EnergyRecord.RecordType.TEMPORARY
        ).order_by('-created_at')
        
        current_hour = now.hour
        current_minute = now.minute
        
        for record in temporary_records:
            # 检查当前时间是否在任何一个时间段内
            for slot in record.time_slots:
                start_hour = slot.get('start_hour', 0)
                start_minute = slot.get('start_minute', 0)
                end_hour = slot.get('end_hour', 23)
                end_minute = slot.get('end_minute', 59)
                
                if self._is_time_in_slot(current_hour, current_minute,
                                        start_hour, start_minute,
                                        end_hour, end_minute):
                    # 计算剩余时间（分钟）
                    current_minutes = current_hour * 60 + current_minute
                    end_minutes = end_hour * 60 + end_minute
                    remaining_minutes = max(0, end_minutes - current_minutes)
                    
                    return {
                        'is_active': True,
                        'type': record.temporary_type,
                        'level': record.energy_level,
                        'remaining_minutes': remaining_minutes,
                        'start_time': self._get_datetime_from_slot(record.record_date, start_hour, start_minute),
                        'end_time': self._get_datetime_from_slot(record.record_date, end_hour, end_minute)
                    }
        
        return {
            'is_active': False,
            'type': None,
            'level': None,
            'remaining_minutes': 0
        }
    
    def _get_active_planned_state(self, user, today, current_hour, current_minute):
        """获取当前激活的预规划状态"""
        planned_record = EnergyRecord.objects.filter(
            user=user,
            record_date=today,
            record_type=EnergyRecord.RecordType.PLANNED
        ).first()
        
        if not planned_record:
            return {
                'is_active': False,
                'level': None,
                'remaining_minutes': 0
            }
        
        # 检查当前时间是否在预规划时间段内
        for slot in planned_record.time_slots:
            start_hour = slot.get('start_hour', 0)
            start_minute = slot.get('start_minute', 0)
            end_hour = slot.get('end_hour', 23)
            end_minute = slot.get('end_minute', 59)
            
            if self._is_time_in_slot(current_hour, current_minute,
                                    start_hour, start_minute,
                                    end_hour, end_minute):
                # 计算剩余时间（分钟）
                current_minutes = current_hour * 60 + current_minute
                end_minutes = end_hour * 60 + end_minute
                remaining_minutes = max(0, end_minutes - current_minutes)
                
                # 从时间段中读取energy_level，如果没有则使用记录的energy_level（向后兼容）
                slot_energy_level = slot.get('energy_level', planned_record.energy_level)
                
                return {
                    'is_active': True,
                    'level': slot_energy_level,
                    'remaining_minutes': remaining_minutes,
                    'start_time': self._get_datetime_from_slot(today, start_hour, start_minute),
                    'end_time': self._get_datetime_from_slot(today, end_hour, end_minute)
                }
        
        return {
            'is_active': False,
            'level': None,
            'remaining_minutes': 0
        }
    
    def _get_datetime_from_slot(self, date_obj, hour, minute):
        """从日期和时间段构建datetime对象"""
        from datetime import time
        return timezone.make_aware(
            datetime.combine(date_obj, time(hour=hour, minute=minute))
        )
    
    def get_energy_records(self, user, target_date=None, record_type=None):
        """获取能量记录"""
        if target_date is None:
            target_date = timezone.now().date()
        
        records = EnergyRecord.objects.filter(user=user, record_date=target_date)
        
        if record_type:
            records = records.filter(record_type=record_type)
        
        # 按类型分组
        result = {
            'base': [],
            'planned': [],
            'temporary': []
        }
        
        for record in records.order_by('created_at'):
            record_data = {
                'id': str(record.id),
                'date': record.record_date.isoformat(),
                'energy_level': record.energy_level,
                'time_slots': record.time_slots,
                'created_at': record.created_at.isoformat(),
                'updated_at': record.updated_at.isoformat()
            }
            
            if record.record_type == EnergyRecord.RecordType.TEMPORARY:
                record_data['temporary_type'] = record.temporary_type
                record_data['original_energy_level'] = record.original_energy_level
                result['temporary'].append(record_data)
            elif record.record_type == EnergyRecord.RecordType.PLANNED:
                result['planned'].append(record_data)
            else:
                result['base'].append(record_data)
        
        # 计算今日统计
        summary = self._calculate_summary(user, target_date)
        
        return {
            'records': result,
            'summary': summary
        }
    
    def _calculate_summary(self, user, target_date):
        """计算今日能量状态统计"""
        base_record = EnergyRecord.objects.filter(
            user=user,
            record_date=target_date,
            record_type=EnergyRecord.RecordType.BASE
        ).first()
        
        if not base_record or not base_record.time_slots:
            return {
                'high_minutes': 0,
                'medium_minutes': 0,
                'low_minutes': 0,
                'unplanned_minutes': 0
            }
        
        now = timezone.now()
        current_hour = now.hour
        current_minute = now.minute
        current_total_minutes = current_hour * 60 + current_minute
        
        # 只统计7:00到当前时间的分钟数
        start_minutes = 7 * 60  # 7:00
        total_minutes = max(0, current_total_minutes - start_minutes)
        
        # 统计各状态的分钟数
        high_minutes = 0
        medium_minutes = 0
        low_minutes = 0
        unplanned_minutes = 0
        
        for slot in base_record.time_slots:
            start_hour = slot.get('start_hour', 7)
            start_minute = slot.get('start_minute', 0)
            end_hour = slot.get('end_hour', 23)
            end_minute = slot.get('end_minute', 59)
            
            slot_start_minutes = start_hour * 60 + start_minute
            slot_end_minutes = min(end_hour * 60 + end_minute, current_total_minutes)
            
            # 只统计7:00之后的时间
            if slot_end_minutes < start_minutes:
                continue
            
            slot_start_minutes = max(slot_start_minutes, start_minutes)
            slot_duration = max(0, slot_end_minutes - slot_start_minutes)
            
            if base_record.energy_level == EnergyRecord.EnergyLevel.HIGH:
                high_minutes += slot_duration
            elif base_record.energy_level == EnergyRecord.EnergyLevel.MEDIUM:
                medium_minutes += slot_duration
            elif base_record.energy_level == EnergyRecord.EnergyLevel.LOW:
                low_minutes += slot_duration
            else:
                unplanned_minutes += slot_duration
        
        # 未规划的时间 = 总时间 - 已规划时间
        planned_minutes = high_minutes + medium_minutes + low_minutes
        unplanned_minutes = max(0, total_minutes - planned_minutes)
        
        return {
            'high_minutes': high_minutes,
            'medium_minutes': medium_minutes,
            'low_minutes': low_minutes,
            'unplanned_minutes': unplanned_minutes
        }
    
    def get_partner_status(self, user):
        """获取伴侣能量状态"""
        relationship = Relationship.get_active_relationship(user)
        if not relationship:
            return None
        
        partner = relationship.get_partner(user)
        if not partner:
            return None
        
        # 获取伴侣当前能量状态
        service = EnergyService()
        partner_current_status = service.get_current_status(partner)
        
        # 获取伴侣今日能量记录
        today = timezone.now().date()
        partner_records = self.get_energy_records(partner, target_date=today)
        
        return {
            'energy_level': partner_current_status['display_energy_level'],
            'records': {
                'base': partner_records['records']['base']
            }
        }
    
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

