"""
Celery定时任务
"""
from celery import shared_task
from django.utils import timezone
from django.contrib.auth import get_user_model
from apps.energy.services import EnergyService
from apps.closures.models import PeacefulClosure
from apps.gift_boxes.models import GiftBox
from apps.websocket.utils import send_new_notification

User = get_user_model()


@shared_task
def process_energy_state_minute():
    """每分钟执行：处理能量状态"""
    users = User.objects.filter(is_active=True)
    service = EnergyService()
    
    for user in users:
        try:
            service.check_and_append_base_state_time_slot(user)
            service.check_and_update_planned_state(user)
            service.update_minute_countdowns(user)
        except Exception as e:
            print(f"处理用户 {user.id} 的能量状态时出错: {e}")
    
    return f"已处理 {users.count()} 个用户的能量状态"


@shared_task
def check_expired_items():
    """每小时执行：检查过期项"""
    now = timezone.now()
    
    # 检查过期的安心确认
    expired_closures = PeacefulClosure.objects.filter(
        has_expiration=True,
        expires_at__lte=now,
        status=PeacefulClosure.Status.PENDING
    )
    
    for closure in expired_closures:
        closure.status = PeacefulClosure.Status.EXPIRED
        closure.save()
        
        # 发送通知
        send_new_notification(closure.target_user.id, {
            'notification_id': str(closure.id),
            'category': 'reminder',
            'title': '安心确认已过期',
            'content': f'"{closure.title}" 已过期'
        })
    
    # 检查过期的心意盒
    expired_gift_boxes = GiftBox.objects.filter(
        has_expiration=True,
        expires_at__lte=now,
        status=GiftBox.Status.PENDING
    )
    
    for gift_box in expired_gift_boxes:
        gift_box.status = GiftBox.Status.EXPIRED
        gift_box.save()
        
        # 发送通知
        send_new_notification(gift_box.target_user.id, {
            'notification_id': str(gift_box.id),
            'category': 'reminder',
            'title': '心意盒已过期',
            'content': f'"{gift_box.item}" 已过期'
        })
    
    return f"已检查过期项：{expired_closures.count()} 个安心确认，{expired_gift_boxes.count()} 个心意盒"


@shared_task
def reset_daily_state():
    """每天0点执行：重置每日状态"""
    users = User.objects.filter(is_active=True)
    service = EnergyService()
    
    for user in users:
        try:
            service.reset_daily_state(user)
        except Exception as e:
            print(f"重置用户 {user.id} 的每日状态时出错: {e}")
    
    return f"已重置 {users.count()} 个用户的每日状态"

