from django.db import models
from django.utils import timezone
from django.contrib.postgres.fields import ArrayField
import uuid


class EnergyRecord(models.Model):
    """能量状态记录"""
    
    class RecordType(models.TextChoices):
        BASE = 'base', '基础状态'
        PLANNED = 'planned', '预规划状态'
        TEMPORARY = 'temporary', '临时状态'
    
    class EnergyLevel(models.TextChoices):
        HIGH = '🟢', '满血复活'
        MEDIUM = '🟡', '血条还行'
        LOW = '🔴', '血槽空了'
        UNPLANNED = '⚪', '待规划'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='energy_records',
        verbose_name='用户'
    )
    record_date = models.DateField(verbose_name='记录日期')
    record_type = models.CharField(
        max_length=20,
        choices=RecordType.choices,
        verbose_name='记录类型'
    )
    energy_level = models.CharField(
        max_length=10,
        choices=EnergyLevel.choices,
        verbose_name='能量等级'
    )
    
    # 时间段信息（JSONB存储）
    time_slots = models.JSONField(default=list, verbose_name='时间段列表')
    
    # 临时状态特有字段
    temporary_type = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        choices=[
            ('fastCharge', '快充模式'),
            ('lowPower', '低电量模式'),
        ],
        verbose_name='临时状态类型'
    )
    original_energy_level = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        choices=EnergyLevel.choices,
        verbose_name='原始能量状态'
    )
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    
    class Meta:
        db_table = 'energy_records'
        verbose_name = '能量状态记录'
        verbose_name_plural = '能量状态记录'
        unique_together = [['user', 'record_date', 'record_type']]
        indexes = [
            models.Index(fields=['user', 'record_date']),
            models.Index(fields=['record_type']),
        ]


class EnergyLevelChange(models.Model):
    """能量状态变更历史"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='energy_level_changes',
        verbose_name='用户'
    )
    change_time = models.DateTimeField(verbose_name='变更时间')
    new_energy_level = models.CharField(
        max_length=10,
        choices=EnergyRecord.EnergyLevel.choices,
        verbose_name='新能量状态'
    )
    change_type = models.CharField(
        max_length=20,
        choices=[
            ('manual', '手动切换'),
            ('temporary', '临时状态'),
            ('planned', '预规划状态'),
            ('auto', '自动切换'),
        ],
        verbose_name='变更类型'
    )
    
    class Meta:
        db_table = 'energy_level_changes'
        verbose_name = '能量状态变更历史'
        verbose_name_plural = '能量状态变更历史'
        indexes = [
            models.Index(fields=['user', 'change_time']),
        ]

