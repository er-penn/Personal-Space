"""
WebSocket工具函数
"""
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

channel_layer = get_channel_layer()


def send_energy_level_changed(user_id, energy_level):
    """发送能量状态变更消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}",
        {
            'type': 'energy_level_changed',
            'data': {
                'energy_level': energy_level,
                'timestamp': None  # 可以添加时间戳
            }
        }
    )


def send_focus_mode_changed(user_id, focus_mode_enabled):
    """发送专注模式变更消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}",
        {
            'type': 'focus_mode_changed',
            'data': {
                'focus_mode_enabled': focus_mode_enabled,
                'timestamp': None
            }
        }
    )


def send_new_notification(user_id, notification_data):
    """发送新通知消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}_notifications",
        {
            'type': 'new_notification',
            'data': notification_data
        }
    )


def send_new_invitation(user_id, invitation_data):
    """发送新邀请消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}_notifications",
        {
            'type': 'new_invitation',
            'data': invitation_data
        }
    )


def send_new_closure(user_id, closure_data):
    """发送新安心确认消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}_notifications",
        {
            'type': 'new_closure',
            'data': closure_data
        }
    )


def send_new_gift_box(user_id, gift_box_data):
    """发送新心意盒消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}_notifications",
        {
            'type': 'new_gift_box',
            'data': gift_box_data
        }
    )


def send_new_fragment(user_id, fragment_data):
    """发送新碎片消息"""
    async_to_sync(channel_layer.group_send)(
        f"user_{user_id}_notifications",
        {
            'type': 'new_fragment',
            'data': fragment_data
        }
    )

