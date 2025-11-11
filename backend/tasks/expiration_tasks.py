"""
过期检查任务
"""
from celery import shared_task
from django.utils import timezone
from apps.closures.models import PeacefulClosure
from apps.gift_boxes.models import GiftBox
from apps.websocket.utils import send_new_notification


@shared_task
def check_expired_items():
    """检查过期项"""
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
    
    # 检查过期的心意盒
    expired_gift_boxes = GiftBox.objects.filter(
        has_expiration=True,
        expires_at__lte=now,
        status=GiftBox.Status.PENDING
    )
    
    for gift_box in expired_gift_boxes:
        gift_box.status = GiftBox.Status.EXPIRED
        gift_box.save()
    
    return {
        'expired_closures': expired_closures.count(),
        'expired_gift_boxes': expired_gift_boxes.count()
    }

