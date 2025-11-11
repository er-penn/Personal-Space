from django.db import models
from django.utils import timezone
import uuid


class CollaborationInvitation(models.Model):
    """协作邀请"""
    
    class Status(models.TextChoices):
        PENDING = 'pending', '待确认'
        ACCEPTED = 'accepted', '已接受'
        REJECTED = 'rejected', '已拒绝'
        CANCELLED = 'cancelled', '已取消'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_invitations',
        verbose_name='创建者'
    )
    target_user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='received_invitations',
        verbose_name='目标用户'
    )
    title = models.CharField(max_length=200, verbose_name='标题')
    description = models.TextField(blank=True, verbose_name='描述')
    start_time = models.DateTimeField(null=True, blank=True, verbose_name='开始时间')
    location = models.CharField(max_length=200, blank=True, verbose_name='地点')
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name='状态'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    responded_at = models.DateTimeField(null=True, blank=True, verbose_name='响应时间')
    
    class Meta:
        db_table = 'collaboration_invitations'
        verbose_name = '协作邀请'
        verbose_name_plural = '协作邀请'
        indexes = [
            models.Index(fields=['created_by', 'status']),
            models.Index(fields=['target_user', 'status']),
            models.Index(fields=['start_time']),
        ]

