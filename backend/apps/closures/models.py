from django.db import models
from django.utils import timezone
import uuid


class PeacefulClosure(models.Model):
    """安心确认"""
    
    class ClosureType(models.TextChoices):
        ITEM = 'item', '物品'
        AFFAIR = 'affair', '事务'
    
    class Status(models.TextChoices):
        PENDING = 'pending', '待确认'
        COMPLETED = 'completed', '已完成'
        ARCHIVED = 'archived', '已归档'
        EXPIRED = 'expired', '已过期'
        CANCELLED = 'cancelled', '已撤销'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_closures',
        verbose_name='创建者'
    )
    target_user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='received_closures',
        verbose_name='目标用户'
    )
    closure_type = models.CharField(
        max_length=20,
        choices=ClosureType.choices,
        verbose_name='类型'
    )
    title = models.CharField(max_length=200, verbose_name='标题')
    content = models.TextField(verbose_name='内容')
    
    # 物品类特有字段（JSONB）
    item_details = models.JSONField(null=True, blank=True, verbose_name='物品详情')
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name='状态'
    )
    
    # 响应信息（JSONB）
    response = models.JSONField(null=True, blank=True, verbose_name='响应信息')
    
    expires_at = models.DateTimeField(null=True, blank=True, verbose_name='过期时间')
    has_expiration = models.BooleanField(default=False, verbose_name='是否有过期时间')
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    responded_at = models.DateTimeField(null=True, blank=True, verbose_name='响应时间')
    
    class Meta:
        db_table = 'peaceful_closures'
        verbose_name = '安心确认'
        verbose_name_plural = '安心确认'
        indexes = [
            models.Index(fields=['created_by', 'status']),
            models.Index(fields=['target_user', 'status']),
            models.Index(fields=['expires_at']),
        ]
    
    @property
    def is_expired(self):
        """检查是否过期"""
        if not self.has_expiration or not self.expires_at:
            return False
        return timezone.now() > self.expires_at

