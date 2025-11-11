from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
import json

User = get_user_model()


class EnergyStatusConsumer(AsyncWebsocketConsumer):
    """能量状态WebSocket消费者"""
    
    async def connect(self):
        """连接建立"""
        self.user = self.scope["user"]
        if self.user.is_authenticated:
            # 加入用户专属房间
            self.room_group_name = f"user_{self.user.id}"
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            await self.accept()
        else:
            await self.close()
    
    async def disconnect(self, close_code):
        """连接断开"""
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
    
    async def receive(self, text_data):
        """接收消息"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'ping':
                await self.send(text_data=json.dumps({
                    'type': 'pong',
                    'timestamp': data.get('timestamp')
                }))
        except json.JSONDecodeError:
            pass
    
    # 接收能量状态变更消息
    async def energy_level_changed(self, event):
        """接收能量状态变更消息"""
        await self.send(text_data=json.dumps({
            'type': 'energy_level_changed',
            'data': event['data']
        }))
    
    # 接收专注模式变更消息
    async def focus_mode_changed(self, event):
        """接收专注模式变更消息"""
        await self.send(text_data=json.dumps({
            'type': 'focus_mode_changed',
            'data': event['data']
        }))


class NotificationConsumer(AsyncWebsocketConsumer):
    """通知WebSocket消费者"""
    
    async def connect(self):
        """连接建立"""
        self.user = self.scope["user"]
        if self.user.is_authenticated:
            # 加入用户专属房间
            self.room_group_name = f"user_{self.user.id}_notifications"
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            await self.accept()
        else:
            await self.close()
    
    async def disconnect(self, close_code):
        """连接断开"""
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
    
    # 接收新通知消息
    async def new_notification(self, event):
        """接收新通知消息"""
        await self.send(text_data=json.dumps({
            'type': 'new_notification',
            'data': event['data']
        }))
    
    # 接收新邀请消息
    async def new_invitation(self, event):
        """接收新邀请消息"""
        await self.send(text_data=json.dumps({
            'type': 'new_invitation',
            'data': event['data']
        }))
    
    # 接收新安心确认消息
    async def new_closure(self, event):
        """接收新安心确认消息"""
        await self.send(text_data=json.dumps({
            'type': 'new_closure',
            'data': event['data']
        }))
    
    # 接收新心意盒消息
    async def new_gift_box(self, event):
        """接收新心意盒消息"""
        await self.send(text_data=json.dumps({
            'type': 'new_gift_box',
            'data': event['data']
        }))
    
    # 接收新碎片消息
    async def new_fragment(self, event):
        """接收新碎片消息"""
        await self.send(text_data=json.dumps({
            'type': 'new_fragment',
            'data': event['data']
        }))

