"""
公共模块
"""
from rest_framework.permissions import BasePermission
from apps.relationships.models import Relationship


class IsInRelationship(BasePermission):
    """检查用户是否在活跃关系中"""
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        relationship = Relationship.get_active_relationship(request.user)
        return relationship is not None


class IsPartner(BasePermission):
    """检查是否是伴侣关系"""
    
    def has_object_permission(self, request, view, obj):
        relationship = Relationship.get_active_relationship(request.user)
        if not relationship:
            return False
        partner = relationship.get_partner(request.user)
        # 根据obj类型判断权限
        if hasattr(obj, 'target_user'):
            return obj.target_user == partner
        if hasattr(obj, 'created_by'):
            return obj.created_by == partner
        return False

