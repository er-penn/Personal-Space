"""
公共工具函数
"""
from django.utils import timezone
from datetime import datetime, timedelta


def get_current_time():
    """获取当前时间"""
    return timezone.now()


def format_datetime(dt):
    """格式化日期时间"""
    if dt:
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    return None


def is_same_day(date1, date2):
    """检查是否是同一天"""
    if not date1 or not date2:
        return False
    return date1.date() == date2.date()

