from django.db import models
from django.utils import timezone
import uuid


class Notification(models.Model):
    """通知"""
    
    class Category(models.TextChoices):
        INFO = 'info', '信息'
        REMINDER = 'reminder', '提醒'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='用户'
    )
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        verbose_name='类别'
    )
    type = models.CharField(max_length=50, verbose_name='类型')
    title = models.CharField(max_length=200, verbose_name='标题')
    content = models.TextField(verbose_name='内容')
    is_read = models.BooleanField(default=False, verbose_name='是否已读')
    end_time = models.DateTimeField(null=True, blank=True, verbose_name='结束时间')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    read_at = models.DateTimeField(null=True, blank=True, verbose_name='已读时间')
    
    class Meta:
        db_table = 'notifications'
        verbose_name = '通知'
        verbose_name_plural = '通知'
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['category']),
            models.Index(fields=['created_at']),
        ]
    
    @property
    def is_expired(self):
        """检查是否过期"""
        if not self.end_time:
            return False
        return timezone.now() > self.end_time

