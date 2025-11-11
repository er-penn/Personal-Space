from django.db import models
from django.utils import timezone
import uuid


class Fragment(models.Model):
    """碎片"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_fragments',
        verbose_name='创建者'
    )
    target_user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='received_fragments',
        verbose_name='目标用户'
    )
    content = models.TextField(verbose_name='内容')
    image_url = models.URLField(blank=True, null=True, verbose_name='图片URL')
    link_url = models.URLField(blank=True, null=True, verbose_name='链接URL')
    is_read = models.BooleanField(default=False, verbose_name='是否已读')
    is_withdrawn = models.BooleanField(default=False, verbose_name='是否已撤回')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    read_at = models.DateTimeField(null=True, blank=True, verbose_name='已读时间')
    
    class Meta:
        db_table = 'fragments'
        verbose_name = '碎片'
        verbose_name_plural = '碎片'
        indexes = [
            models.Index(fields=['created_by']),
            models.Index(fields=['target_user', 'is_read']),
            models.Index(fields=['created_at']),
        ]

