from django.db import models
from django.utils import timezone
import uuid


class GiftBox(models.Model):
    """心意盒"""
    
    class Status(models.TextChoices):
        PENDING = 'pending', '待确认'
        ACCEPTED = 'accepted', '已接受'
        REJECTED = 'rejected', '不想要'
        EXPIRED = 'expired', '已过期'
        WITHDRAWN = 'withdrawn', '已撤回'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_gift_boxes',
        verbose_name='创建者'
    )
    target_user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='received_gift_boxes',
        verbose_name='目标用户'
    )
    item = models.CharField(max_length=200, verbose_name='物品')
    note = models.TextField(blank=True, verbose_name='备注')
    suggested_location = models.CharField(max_length=200, verbose_name='建议地点')
    preparation_time = models.IntegerField(verbose_name='准备时间（分钟）')
    
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name='状态'
    )
    
    # 接收方填写的信息（JSONB）
    accepted_info = models.JSONField(null=True, blank=True, verbose_name='接受信息')
    response = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        choices=[
            ('accepted', '好滴收下啦🥰'),
            ('rejected', '不太想要😅'),
        ],
        verbose_name='响应'
    )
    responded_at = models.DateTimeField(null=True, blank=True, verbose_name='响应时间')
    
    has_expiration = models.BooleanField(default=False, verbose_name='是否有有效期')
    expires_at = models.DateTimeField(null=True, blank=True, verbose_name='过期时间')
    is_withdrawn = models.BooleanField(default=False, verbose_name='是否已撤回')
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    last_edited_at = models.DateTimeField(null=True, blank=True, verbose_name='最后编辑时间')
    
    class Meta:
        db_table = 'gift_boxes'
        verbose_name = '心意盒'
        verbose_name_plural = '心意盒'
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
    
    @property
    def last_activity_time(self):
        """最后活动时间"""
        if self.responded_at:
            return self.responded_at
        if self.last_edited_at:
            return self.last_edited_at
        return self.created_at

