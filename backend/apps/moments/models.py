from django.db import models
from django.utils import timezone
from django.contrib.postgres.fields import ArrayField
import uuid


class Moment(models.Model):
    """瞬间"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_moments',
        verbose_name='创建者'
    )
    content = models.TextField(verbose_name='内容')
    images = ArrayField(
        models.URLField(),
        default=list,
        blank=True,
        verbose_name='图片URL列表'
    )
    is_text_hidden = models.BooleanField(default=True, verbose_name='文案是否隐藏')
    likes = models.IntegerField(default=0, verbose_name='点赞数')
    comments = models.IntegerField(default=0, verbose_name='评论数')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    
    class Meta:
        db_table = 'moments'
        verbose_name = '瞬间'
        verbose_name_plural = '瞬间'
        indexes = [
            models.Index(fields=['created_by']),
            models.Index(fields=['created_at']),
        ]
    
    @property
    def should_show_text(self):
        """是否应该显示文案（3天规则）"""
        if not self.is_text_hidden:
            return True
        return (timezone.now() - self.created_at).total_seconds() > 3 * 24 * 3600
    
    @property
    def remaining_hidden_days(self):
        """剩余隐藏天数"""
        if self.should_show_text:
            return 0
        elapsed = (timezone.now() - self.created_at).total_seconds()
        remaining = 3 * 24 * 3600 - elapsed
        return max(0, int(remaining / (24 * 3600)))

