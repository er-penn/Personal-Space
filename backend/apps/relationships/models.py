from django.db import models
from django.utils import timezone
import uuid


class Relationship(models.Model):
    """关系模型"""
    
    class Status(models.TextChoices):
        PENDING = 'pending', '待确认'
        ACTIVE = 'active', '活跃'
        BLOCKED = 'blocked', '已屏蔽'
        ENDED = 'ended', '已结束'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='relationships_as_user1',
        verbose_name='用户1'
    )
    user2 = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='relationships_as_user2',
        verbose_name='用户2'
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name='状态'
    )
    invited_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='invited_relationships',
        verbose_name='邀请者'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    
    class Meta:
        db_table = 'relationships'
        verbose_name = '关系'
        verbose_name_plural = '关系'
        unique_together = [['user1', 'user2']]
        indexes = [
            models.Index(fields=['user1', 'status']),
            models.Index(fields=['user2', 'status']),
        ]
    
    def __str__(self):
        return f"{self.user1.phone} <-> {self.user2.phone} ({self.status})"
    
    @classmethod
    def get_active_relationship(cls, user):
        """获取用户的活跃关系"""
        return cls.objects.filter(
            models.Q(user1=user) | models.Q(user2=user),
            status=cls.Status.ACTIVE
        ).first()
    
    def get_partner(self, user):
        """获取伴侣"""
        if self.user1 == user:
            return self.user2
        return self.user1
    
    def is_user_in_relationship(self, user):
        """检查用户是否在关系中"""
        return self.user1 == user or self.user2 == user


class MaybeItem(models.Model):
    """Maybe清单项"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    relationship = models.ForeignKey(
        Relationship,
        on_delete=models.CASCADE,
        related_name='maybe_items',
        verbose_name='关系'
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='created_maybe_items',
        verbose_name='创建者'
    )
    title = models.CharField(max_length=200, verbose_name='标题')
    description = models.TextField(blank=True, verbose_name='描述')
    location = models.CharField(max_length=200, blank=True, verbose_name='地点')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    
    class Meta:
        db_table = 'maybe_items'
        verbose_name = 'Maybe清单项'
        verbose_name_plural = 'Maybe清单项'
        ordering = ['-created_at']


class GrowthGarden(models.Model):
    """成长花园"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    relationship = models.OneToOneField(
        Relationship,
        on_delete=models.CASCADE,
        related_name='growth_garden',
        verbose_name='关系'
    )
    plant_level = models.IntegerField(default=1, verbose_name='植物等级')
    water_level = models.IntegerField(default=0, verbose_name='水分值')
    last_watered_at = models.DateTimeField(null=True, blank=True, verbose_name='最后浇水时间')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    
    class Meta:
        db_table = 'growth_garden'
        verbose_name = '成长花园'
        verbose_name_plural = '成长花园'

