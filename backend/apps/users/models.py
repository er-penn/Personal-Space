from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.utils import timezone
import uuid


class UserManager(BaseUserManager):
    """自定义用户管理器"""
    
    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError('手机号是必填项')
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(phone, password, **extra_fields)


class User(AbstractBaseUser):
    """用户模型"""
    
    class EnergyLevel(models.TextChoices):
        HIGH = '🟢', '满血复活'
        MEDIUM = '🟡', '血条还行'
        LOW = '🔴', '血槽空了'
        UNPLANNED = '⚪', '待规划'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=20, unique=True, db_index=True, verbose_name='手机号')
    nickname = models.CharField(max_length=50, blank=True, verbose_name='昵称')
    avatar_url = models.URLField(blank=True, null=True, verbose_name='头像URL')
    
    # 能量状态相关
    current_energy_level = models.CharField(
        max_length=10,
        choices=EnergyLevel.choices,
        default=EnergyLevel.UNPLANNED,
        verbose_name='当前能量状态'
    )
    focus_mode_enabled = models.BooleanField(default=False, verbose_name='专注模式')
    
    # 时间戳
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='更新时间')
    last_seen_at = models.DateTimeField(null=True, blank=True, verbose_name='最后活跃时间')
    
    # Django认证相关
    is_active = models.BooleanField(default=True, verbose_name='是否激活')
    is_staff = models.BooleanField(default=False, verbose_name='是否员工')
    is_superuser = models.BooleanField(default=False, verbose_name='是否超级用户')
    
    objects = UserManager()
    
    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = []
    
    class Meta:
        db_table = 'users'
        verbose_name = '用户'
        verbose_name_plural = '用户'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.phone} ({self.nickname or '未设置昵称'})"
    
    def has_perm(self, perm, obj=None):
        return self.is_superuser
    
    def has_module_perms(self, app_label):
        return self.is_superuser

