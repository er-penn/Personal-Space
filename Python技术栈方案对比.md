# 「边界舱」Python 后端技术栈方案对比

## 一、方案概览

本文档提供6种Python技术栈方案，供项目选择：

1. **方案1：FastAPI + SQLAlchemy（现代化高性能）** ⭐推荐
2. **方案2：Django + Django REST Framework（全功能框架）**
3. **方案3：Flask + SQLAlchemy（轻量级灵活）**
4. **方案4：FastAPI + Tortoise ORM（异步ORM）**
5. **方案5：Django + Django Channels（实时通信强化）**
6. **方案6：FastAPI + SQLModel（类型优先）**

---

## 二、方案1：FastAPI + SQLAlchemy（现代化高性能）⭐推荐

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | FastAPI | 0.104+ |
| 数据库ORM | SQLAlchemy 2.0 | 2.0+ |
| 数据库 | PostgreSQL 14+ | - |
| 异步驱动 | asyncpg | - |
| 缓存 | aioredis / redis-py | Redis 7+ |
| 实时通信 | FastAPI WebSocket | - |
| 认证 | python-jose / PyJWT | - |
| 数据验证 | Pydantic V2 | 2.0+ |
| 文件上传 | python-multipart | - |
| 任务队列 | Celery + Redis | - |
| 日志 | Loguru | - |
| API文档 | FastAPI自动生成 | - |
| 测试框架 | pytest + httpx | - |
| 数据库迁移 | Alembic | - |

### 项目结构示例

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI应用入口
│   ├── config.py               # 配置管理
│   ├── database.py             # 数据库连接
│   ├── dependencies.py         # 依赖注入
│   ├── models/                 # SQLAlchemy模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── relationship.py
│   │   └── energy_record.py
│   ├── schemas/                # Pydantic模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── energy.py
│   ├── api/                    # API路由
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   └── energy.py
│   ├── services/               # 业务逻辑
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── energy_service.py
│   ├── websocket/              # WebSocket处理
│   │   ├── __init__.py
│   │   └── handlers.py
│   └── utils/                  # 工具函数
│       ├── __init__.py
│       └── jwt.py
├── alembic/                    # 数据库迁移
│   ├── versions/
│   └── env.py
├── tests/                      # 测试
├── requirements.txt
└── pyproject.toml
```

### 核心代码示例

**main.py**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import auth, users, energy
from app.websocket import handlers
from app.database import engine, Base

# 创建数据库表
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="边界舱 API",
    description="边界舱后端API文档",
    version="1.0.0"
)

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 路由注册
app.include_router(auth.router, prefix="/api/v1/auth", tags=["认证"])
app.include_router(users.router, prefix="/api/v1/users", tags=["用户"])
app.include_router(energy.router, prefix="/api/v1/energy", tags=["能量状态"])

# WebSocket路由
app.websocket("/ws")(handlers.websocket_endpoint)
```

**models/user.py**
```python
from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
import uuid
import enum

class EnergyLevel(str, enum.Enum):
    HIGH = "🟢"
    MEDIUM = "🟡"
    LOW = "🔴"
    UNPLANNED = "⚪"

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    nickname = Column(String(50))
    avatar_url = Column(String)
    current_energy_level = Column(Enum(EnergyLevel), default=EnergyLevel.UNPLANNED)
    focus_mode_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_seen_at = Column(DateTime)
    
    # 关系
    energy_records = relationship("EnergyRecord", back_populates="user")
```

**schemas/user.py**
```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from app.models.user import EnergyLevel

class UserCreate(BaseModel):
    phone: str = Field(..., min_length=11, max_length=20)
    nickname: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    phone: str
    nickname: Optional[str]
    avatar_url: Optional[str]
    current_energy_level: EnergyLevel
    focus_mode_enabled: bool
    last_seen_at: Optional[datetime]
    
    class Config:
        from_attributes = True
```

**api/v1/users.py**
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.user import UserResponse
from app.services.user_service import UserService
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取当前用户信息"""
    return current_user

@router.put("/me", response_model=UserResponse)
async def update_user_info(
    nickname: Optional[str] = None,
    avatar_url: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新用户信息"""
    service = UserService(db)
    return service.update_user(current_user.id, nickname=nickname, avatar_url=avatar_url)
```

### 优势

✅ **现代化设计**
- 基于 Python 3.10+ 类型提示
- Pydantic V2 数据验证强大
- 自动生成 OpenAPI/Swagger 文档
- 异步支持完善（async/await）

✅ **性能优秀**
- 基于 Starlette 和 Pydantic（C语言实现）
- 异步处理能力强
- 性能接近 Node.js
- 适合高并发场景

✅ **开发体验好**
- 自动API文档（Swagger UI）
- 类型提示完善，IDE支持好
- 代码简洁，可读性强
- 错误信息清晰

✅ **生态兼容**
- 兼容所有 Python 库
- SQLAlchemy 成熟稳定
- Celery 任务队列支持
- 第三方库集成方便

### 劣势

❌ **相对较新**
- 2018年发布，历史相对较短
- 某些企业可能不熟悉
- 最佳实践需要探索

❌ **异步ORM学习曲线**
- SQLAlchemy 2.0 异步需要学习
- 同步和异步代码混用需要注意
- 调试相对复杂

❌ **实时通信需要手动管理**
- WebSocket 连接管理需要自己实现
- 不如 Socket.io 成熟
- 需要处理连接断开、重连等

### 适用场景

- ✅ 现代化项目
- ✅ 需要高性能
- ✅ 需要自动API文档
- ✅ 团队熟悉Python异步编程
- ✅ 中小型到大型项目

### 学习资源

- 官方文档：https://fastapi.tiangolo.com/
- SQLAlchemy 2.0：https://docs.sqlalchemy.org/en/20/
- 教程：FastAPI官方教程、Real Python教程

---

## 三、方案2：Django + Django REST Framework（全功能框架）

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | Django | 4.2+ |
| API框架 | Django REST Framework | 3.14+ |
| 数据库ORM | Django ORM | - |
| 数据库 | PostgreSQL 14+ | - |
| 缓存 | django-redis | Redis 7+ |
| 实时通信 | Django Channels | - |
| 认证 | djangorestframework-simplejwt | - |
| 数据验证 | DRF Serializers | - |
| 文件上传 | Django FileField | - |
| 任务队列 | Celery + Redis | - |
| 日志 | Django logging | - |
| API文档 | drf-spectacular | - |
| 测试框架 | Django TestCase / pytest-django | - |
| 数据库迁移 | Django Migrations | - |

### 项目结构示例

```
backend/
├── manage.py
├── config/
│   ├── __init__.py
│   ├── settings.py          # Django配置
│   ├── urls.py              # 主URL配置
│   └── wsgi.py
├── apps/
│   ├── users/               # 用户应用
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── admin.py
│   ├── energy/              # 能量状态应用
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── relationships/      # 关系管理应用
│       ├── models.py
│       ├── serializers.py
│       ├── views.py
│       └── urls.py
├── common/                  # 公共模块
│   ├── permissions.py
│   ├── pagination.py
│   └── exceptions.py
├── requirements.txt
└── pyproject.toml
```

### 核心代码示例

**settings.py**
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'rest_framework',
    'rest_framework_simplejwt',
    'channels',
    'apps.users',
    'apps.energy',
    'apps.relationships',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [('127.0.0.1', 6379)],
        },
    },
}
```

**apps/users/models.py**
```python
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, phone, password=None, **extra_fields):
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

class User(AbstractBaseUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    phone = models.CharField(max_length=20, unique=True, db_index=True)
    nickname = models.CharField(max_length=50, blank=True)
    avatar_url = models.URLField(blank=True)
    current_energy_level = models.CharField(max_length=10, default='⚪')
    focus_mode_enabled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)
    
    USERNAME_FIELD = 'phone'
    objects = UserManager()
```

**apps/users/serializers.py**
```python
from rest_framework import serializers
from apps.users.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone', 'nickname', 'avatar_url', 
                  'current_energy_level', 'focus_mode_enabled', 
                  'last_seen_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
```

**apps/users/views.py**
```python
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from apps.users.models import User
from apps.users.serializers import UserSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put'])
    def update_me(self, request):
        serializer = self.get_serializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
```

### 优势

✅ **全功能框架**
- 内置Admin后台
- 用户认证系统完善
- ORM功能强大
- 中间件系统完善

✅ **生态成熟**
- 第三方包丰富（Django Packages）
- 社区活跃
- 文档完善
- 最佳实践多

✅ **开发效率高**
- 代码生成工具（manage.py）
- 自动数据库迁移
- Admin后台快速开发
- 模板系统（如果需要）

✅ **企业级特性**
- 安全性好（CSRF、XSS防护）
- 缓存系统完善
- 国际化支持
- 日志系统完善

✅ **实时通信支持**
- Django Channels成熟
- WebSocket支持好
- 支持多种后端（Redis、内存等）

### 劣势

❌ **相对重量级**
- 框架较大，启动较慢
- 内存占用相对较高
- 某些功能可能用不到

❌ **性能相对一般**
- 同步框架，性能不如异步框架
- 需要配合异步视图提升性能
- 高并发需要优化

❌ **学习曲线**
- 概念较多（MVC、MTV）
- 配置相对复杂
- 需要理解Django设计哲学

❌ **灵活性相对较低**
- 框架约定较多
- 某些场景需要绕过框架
- 不如Flask灵活

### 适用场景

- ✅ 需要快速开发Admin后台
- ✅ 需要完整的Web框架功能
- ✅ 团队熟悉Django
- ✅ 需要实时通信（Channels）
- ✅ 中大型项目

### 学习资源

- 官方文档：https://docs.djangoproject.com/
- DRF文档：https://www.django-rest-framework.org/
- Channels文档：https://channels.readthedocs.io/

---

## 四、方案3：Flask + SQLAlchemy（轻量级灵活）

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | Flask | 3.0+ |
| API框架 | Flask-RESTful / Flask-RESTX | - |
| 数据库ORM | SQLAlchemy 2.0 | 2.0+ |
| 数据库 | PostgreSQL 14+ | - |
| 缓存 | Flask-Caching + redis | Redis 7+ |
| 实时通信 | Flask-SocketIO | - |
| 认证 | Flask-JWT-Extended | - |
| 数据验证 | Marshmallow | - |
| 文件上传 | Flask-Uploads | - |
| 任务队列 | Celery + Redis | - |
| 日志 | Flask logging | - |
| API文档 | Flask-RESTX自动生成 | - |
| 测试框架 | pytest + Flask-Testing | - |
| 数据库迁移 | Flask-Migrate (Alembic) | - |

### 项目结构示例

```
backend/
├── app/
│   ├── __init__.py           # Flask应用工厂
│   ├── config.py             # 配置
│   ├── extensions.py         # 扩展初始化
│   ├── models/               # SQLAlchemy模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── energy.py
│   ├── schemas/              # Marshmallow模式
│   │   ├── __init__.py
│   │   └── user.py
│   ├── api/                  # API蓝图
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── users.py
│   │   └── energy.py
│   ├── services/             # 业务逻辑
│   │   ├── __init__.py
│   │   └── user_service.py
│   └── utils/                # 工具函数
│       └── __init__.py
├── migrations/               # 数据库迁移
├── tests/
├── requirements.txt
└── run.py
```

### 核心代码示例

**app/__init__.py**
```python
from flask import Flask
from flask_restful import Api
from flask_socketio import SocketIO
from app.config import Config
from app.extensions import db, jwt, migrate, socketio

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # 初始化扩展
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    socketio.init_app(app, cors_allowed_origins="*")
    
    # 注册蓝图
    from app.api import auth, users, energy
    api = Api(app)
    api.add_resource(auth.LoginResource, '/api/v1/auth/login')
    api.add_resource(users.UserResource, '/api/v1/users/me')
    api.add_resource(energy.EnergyResource, '/api/v1/energy/current')
    
    return app
```

**app/api/users.py**
```python
from flask_restful import Resource
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.user import User
from app.schemas.user import UserSchema
from app.extensions import db

class UserResource(Resource):
    @jwt_required()
    def get(self):
        """获取当前用户信息"""
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        schema = UserSchema()
        return schema.dump(user)
    
    @jwt_required()
    def put(self):
        """更新用户信息"""
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        schema = UserSchema()
        data = schema.load(request.json, partial=True)
        
        for key, value in data.items():
            setattr(user, key, value)
        
        db.session.commit()
        return schema.dump(user)
```

### 优势

✅ **轻量级**
- 框架核心小，启动快
- 只包含必要功能
- 内存占用小
- 灵活度高

✅ **灵活性高**
- 可以自由选择组件
- 不受框架约束
- 适合定制化需求
- 架构设计自由

✅ **学习曲线平缓**
- 概念简单
- 文档清晰
- 容易理解
- 适合初学者

✅ **生态丰富**
- Flask扩展丰富
- 社区活跃
- 第三方库多
- 集成方便

### 劣势

❌ **需要更多配置**
- 需要手动选择组件
- 配置相对分散
- 需要自己搭建架构
- 开发时间可能更长

❌ **缺少内置功能**
- 没有Admin后台
- 需要自己实现认证
- 需要自己实现权限
- 需要更多代码

❌ **性能一般**
- 同步框架
- 高并发需要优化
- 不如异步框架

❌ **实时通信相对复杂**
- Flask-SocketIO配置复杂
- 不如Socket.io简单
- 需要处理连接管理

### 适用场景

- ✅ 需要高度定制化
- ✅ 项目规模较小
- ✅ 团队熟悉Flask
- ✅ 需要灵活架构
- ✅ 微服务架构

### 学习资源

- 官方文档：https://flask.palletsprojects.com/
- Flask-RESTful：https://flask-restful.readthedocs.io/
- Flask-SocketIO：https://flask-socketio.readthedocs.io/

---

## 五、方案4：FastAPI + Tortoise ORM（异步ORM）

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | FastAPI | 0.104+ |
| 数据库ORM | Tortoise ORM | 0.20+ |
| 数据库 | PostgreSQL 14+ | - |
| 异步驱动 | asyncpg | - |
| 缓存 | aioredis | Redis 7+ |
| 实时通信 | FastAPI WebSocket | - |
| 认证 | python-jose | - |
| 数据验证 | Pydantic V2 | 2.0+ |
| 文件上传 | python-multipart | - |
| 任务队列 | Celery + Redis | - |
| 日志 | Loguru | - |
| API文档 | FastAPI自动生成 | - |
| 测试框架 | pytest + httpx | - |
| 数据库迁移 | Aerich | - |

### 项目结构示例

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── database.py           # Tortoise配置
│   ├── models/                # Tortoise模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── energy.py
│   ├── schemas/               # Pydantic模型
│   │   └── user.py
│   ├── api/
│   │   └── v1/
│   │       ├── users.py
│   │       └── energy.py
│   └── services/
│       └── user_service.py
├── migrations/                # Aerich迁移
├── tests/
└── requirements.txt
```

### 核心代码示例

**app/database.py**
```python
from tortoise import Tortoise
from app.config import settings

async def init_db():
    await Tortoise.init(
        db_url=settings.DATABASE_URL,
        modules={'models': ['app.models']}
    )
    await Tortoise.generate_schemas()

async def close_db():
    await Tortoise.close_connections()
```

**app/models/user.py**
```python
from tortoise.models import Model
from tortoise import fields
import uuid

class User(Model):
    id = fields.UUIDField(pk=True, default=uuid.uuid4)
    phone = fields.CharField(max_length=20, unique=True, index=True)
    nickname = fields.CharField(max_length=50, null=True)
    avatar_url = fields.TextField(null=True)
    current_energy_level = fields.CharField(max_length=10, default='⚪')
    focus_mode_enabled = fields.BooleanField(default=False)
    created_at = fields.DatetimeField(auto_now_add=True)
    updated_at = fields.DatetimeField(auto_now=True)
    last_seen_at = fields.DatetimeField(null=True)
    
    class Meta:
        table = "users"
```

**app/api/v1/users.py**
```python
from fastapi import APIRouter, Depends
from app.models.user import User
from app.schemas.user import UserResponse
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """获取当前用户信息"""
    return await UserResponse.from_tortoise_orm(current_user)

@router.put("/me", response_model=UserResponse)
async def update_user_info(
    nickname: Optional[str] = None,
    avatar_url: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """更新用户信息"""
    if nickname:
        current_user.nickname = nickname
    if avatar_url:
        current_user.avatar_url = avatar_url
    await current_user.save()
    return await UserResponse.from_tortoise_orm(current_user)
```

### 优势

✅ **完全异步**
- ORM完全异步
- 性能优秀
- 适合高并发
- 代码风格统一

✅ **Django风格**
- 模型定义类似Django
- 迁移工具类似Django
- 学习成本低（如果熟悉Django）
- 代码可读性好

✅ **类型支持**
- 支持类型提示
- IDE支持好
- 代码质量高
- 减少错误

✅ **迁移工具**
- Aerich迁移工具
- 类似Django Migrations
- 使用方便
- 版本控制好

### 劣势

❌ **相对较新**
- 2019年发布
- 社区相对较小
- 文档相对较少
- 最佳实践需要探索

❌ **功能相对简单**
- 不如SQLAlchemy功能丰富
- 复杂查询支持一般
- 某些高级特性缺失
- 需要手写SQL的场景多

❌ **生态相对较小**
- 第三方扩展少
- 社区资源少
- 问题解决可能困难
- 需要自己实现某些功能

❌ **性能优化**
- 查询优化需要手动
- N+1问题需要注意
- 需要理解异步ORM原理
- 调试相对复杂

### 适用场景

- ✅ 需要完全异步的项目
- ✅ 熟悉Django但需要异步
- ✅ 高并发场景
- ✅ 中小型项目

### 学习资源

- 官方文档：https://tortoise.github.io/
- GitHub：https://github.com/tortoise/tortoise-orm

---

## 六、方案5：Django + Django Channels（实时通信强化）

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | Django | 4.2+ |
| API框架 | Django REST Framework | 3.14+ |
| 实时通信 | Django Channels | 4.0+ |
| 数据库ORM | Django ORM | - |
| 数据库 | PostgreSQL 14+ | - |
| 缓存 | django-redis | Redis 7+ |
| 认证 | djangorestframework-simplejwt | - |
| 任务队列 | Celery + Redis | - |
| WebSocket后端 | Redis Channel Layer | - |
| API文档 | drf-spectacular | - |

### 项目结构示例

```
backend/
├── config/
│   ├── settings.py
│   ├── asgi.py              # ASGI配置（Channels需要）
│   └── routing.py           # WebSocket路由
├── apps/
│   ├── users/
│   ├── energy/
│   └── websocket/           # WebSocket消费者
│       ├── consumers.py
│       └── routing.py
└── requirements.txt
```

### 核心代码示例

**config/asgi.py**
```python
import os
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application
from config.routing import websocket_urlpatterns

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
```

**apps/websocket/consumers.py**
```python
from channels.generic.websocket import AsyncWebsocketConsumer
import json

class EnergyStatusConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        if self.user.is_authenticated:
            self.room_group_name = f"user_{self.user.id}"
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            await self.accept()
        else:
            await self.close()
    
    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type')
        
        if message_type == 'ping':
            await self.send(text_data=json.dumps({
                'type': 'pong'
            }))
    
    async def energy_level_changed(self, event):
        """接收能量状态变更消息"""
        await self.send(text_data=json.dumps({
            'type': 'energy_level_changed',
            'data': event['data']
        }))
```

**apps/websocket/routing.py**
```python
from django.urls import path
from apps.websocket import consumers

websocket_urlpatterns = [
    path('ws/energy/', consumers.EnergyStatusConsumer.as_asgi()),
]
```

### 优势

✅ **实时通信成熟**
- Django Channels成熟稳定
- WebSocket支持完善
- 支持多种后端（Redis、内存等）
- 连接管理完善

✅ **Django全功能**
- 继承Django所有优势
- Admin后台可用
- ORM功能强大
- 生态丰富

✅ **架构清晰**
- ASGI应用清晰
- 消费者模式易理解
- 路由配置简单
- 代码组织好

✅ **扩展性强**
- 支持多种协议（WebSocket、HTTP/2）
- 可以扩展其他协议
- 灵活配置
- 适合复杂场景

### 劣势

❌ **配置复杂**
- ASGI配置需要理解
- Channel Layer配置复杂
- 需要Redis等后端
- 部署相对复杂

❌ **性能考虑**
- Channel Layer可能成为瓶颈
- 需要Redis等中间件
- 连接数多时性能下降
- 需要优化

❌ **学习曲线**
- 需要理解ASGI
- 需要理解Channel Layer
- 概念相对复杂
- 调试相对困难

❌ **资源占用**
- 需要额外的Redis等
- 内存占用相对较高
- 服务器成本增加

### 适用场景

- ✅ 实时通信需求多
- ✅ 需要WebSocket功能
- ✅ 团队熟悉Django
- ✅ 中大型项目

### 学习资源

- Channels文档：https://channels.readthedocs.io/
- Django文档：https://docs.djangoproject.com/

---

## 七、方案6：FastAPI + SQLModel（类型优先）

### 技术栈组成

| 组件 | 技术选型 | 版本要求 |
|------|---------|---------|
| 后端框架 | FastAPI | 0.104+ |
| 数据库ORM | SQLModel | 0.0.14+ |
| 数据库 | PostgreSQL 14+ | - |
| 异步驱动 | asyncpg | - |
| 缓存 | aioredis | Redis 7+ |
| 实时通信 | FastAPI WebSocket | - |
| 认证 | python-jose | - |
| 数据验证 | Pydantic V2（内置） | - |
| 文件上传 | python-multipart | - |
| 任务队列 | Celery + Redis | - |
| 日志 | Loguru | - |
| API文档 | FastAPI自动生成 | - |
| 测试框架 | pytest + httpx | - |
| 数据库迁移 | Alembic | - |

### 项目结构示例

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── database.py
│   ├── models/               # SQLModel模型（同时是Pydantic模型）
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── energy.py
│   ├── api/
│   │   └── v1/
│   │       ├── users.py
│   │       └── energy.py
│   └── services/
│       └── user_service.py
├── alembic/
├── tests/
└── requirements.txt
```

### 核心代码示例

**app/models/user.py**
```python
from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime
import uuid

class UserBase(SQLModel):
    phone: str = Field(max_length=20, unique=True, index=True)
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    current_energy_level: str = Field(default="⚪")
    focus_mode_enabled: bool = Field(default=False)

class User(UserBase, table=True):
    __tablename__ = "users"
    
    id: Optional[uuid.UUID] = Field(default_factory=uuid.uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_seen_at: Optional[datetime] = None

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    last_seen_at: Optional[datetime]
```

**app/api/v1/users.py**
```python
from fastapi import APIRouter, Depends
from sqlmodel import Session, select
from app.models.user import User, UserResponse, UserCreate
from app.database import get_session
from app.dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """获取当前用户信息"""
    return current_user

@router.put("/me", response_model=UserResponse)
async def update_user_info(
    nickname: Optional[str] = None,
    avatar_url: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session)
):
    """更新用户信息"""
    if nickname:
        current_user.nickname = nickname
    if avatar_url:
        current_user.avatar_url = avatar_url
    current_user.updated_at = datetime.utcnow()
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return current_user
```

### 优势

✅ **类型优先**
- 一个模型同时是数据库模型和API模型
- 类型安全，减少重复代码
- IDE支持完美
- 代码简洁

✅ **FastAPI优势**
- 继承FastAPI所有优势
- 自动API文档
- 性能优秀
- 异步支持

✅ **代码复用**
- 模型定义一次，多处使用
- 减少代码重复
- 维护成本低
- 一致性高

✅ **现代化设计**
- 基于Pydantic和SQLAlchemy
- 类型提示完善
- 代码可读性强
- 符合现代Python实践

### 劣势

❌ **相对较新**
- 2021年发布
- 社区相对较小
- 文档相对较少
- 最佳实践需要探索

❌ **功能相对简单**
- 不如SQLAlchemy功能丰富
- 复杂关系处理需要学习
- 某些高级特性缺失
- 迁移工具需要配合Alembic

❌ **学习曲线**
- 需要理解SQLModel设计理念
- 需要理解SQLAlchemy
- 需要理解Pydantic
- 概念相对复杂

❌ **生态相对较小**
- 第三方扩展少
- 社区资源少
- 问题解决可能困难
- 需要自己实现某些功能

### 适用场景

- ✅ 需要类型安全
- ✅ 需要减少代码重复
- ✅ 现代化项目
- ✅ 中小型项目

### 学习资源

- 官方文档：https://sqlmodel.tiangolo.com/
- GitHub：https://github.com/tiangolo/sqlmodel

---

## 八、综合对比表

| 对比维度 | FastAPI+SQLAlchemy | Django+DRF | Flask+SQLAlchemy | FastAPI+Tortoise | Django+Channels | FastAPI+SQLModel |
|---------|-------------------|------------|------------------|------------------|-----------------|------------------|
| **开发效率** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **运行性能** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **异步支持** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **实时通信** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **类型安全** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **生态丰富度** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **学习成本** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **代码简洁度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Admin后台** | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |
| **自动文档** | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ |
| **ORM功能** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **部署复杂度** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

---

## 九、推荐方案选择指南

### 场景1：快速开发，需要自动API文档
**推荐：方案1（FastAPI + SQLAlchemy）**
- ✅ 自动生成Swagger文档
- ✅ 开发效率高
- ✅ 性能优秀
- ✅ 类型安全

### 场景2：需要Admin后台，全功能框架
**推荐：方案2（Django + DRF）**
- ✅ 内置Admin后台
- ✅ 全功能框架
- ✅ 生态成熟
- ✅ 开发效率高

### 场景3：需要完全异步，高并发
**推荐：方案4（FastAPI + Tortoise ORM）**
- ✅ 完全异步
- ✅ 性能优秀
- ✅ 适合高并发
- ✅ Django风格易上手

### 场景4：实时通信需求多
**推荐：方案5（Django + Channels）**
- ✅ Channels成熟稳定
- ✅ WebSocket支持完善
- ✅ 连接管理完善
- ✅ 适合实时场景

### 场景5：需要类型安全，减少重复代码
**推荐：方案6（FastAPI + SQLModel）**
- ✅ 一个模型多处使用
- ✅ 类型安全
- ✅ 代码简洁
- ✅ 减少重复

### 场景6：轻量级，高度定制
**推荐：方案3（Flask + SQLAlchemy）**
- ✅ 轻量级
- ✅ 灵活度高
- ✅ 可以自由选择组件
- ✅ 适合定制化

---

## 十、最终推荐

### 🏆 综合推荐：方案1（FastAPI + SQLAlchemy）

**推荐理由：**
1. ✅ **现代化设计**：基于Python 3.10+类型提示，代码质量高
2. ✅ **性能优秀**：异步支持完善，性能接近Node.js
3. ✅ **开发效率高**：自动API文档，类型安全，开发体验好
4. ✅ **生态兼容**：兼容所有Python库，SQLAlchemy成熟稳定
5. ✅ **学习曲线平缓**：文档完善，社区活跃，容易上手

**技术栈组合：**
```python
FastAPI 0.104+          # Web框架
SQLAlchemy 2.0         # ORM（支持异步）
Pydantic V2            # 数据验证
asyncpg                # PostgreSQL异步驱动
aioredis               # Redis异步客户端
python-jose            # JWT认证
Celery                 # 任务队列
Alembic                # 数据库迁移
pytest                 # 测试框架
```

### 🥈 实时通信优先：方案5（Django + Channels）

**推荐理由：**
1. ✅ **实时通信成熟**：Channels框架成熟，WebSocket支持完善
2. ✅ **全功能框架**：继承Django所有优势
3. ✅ **生态丰富**：第三方包丰富，社区活跃

### 🥉 类型优先：方案6（FastAPI + SQLModel）

**推荐理由：**
1. ✅ **类型安全**：一个模型同时是数据库模型和API模型
2. ✅ **代码简洁**：减少重复代码，维护成本低
3. ✅ **现代化**：符合现代Python实践

---

## 十一、实施建议

### 阶段1：MVP阶段（推荐方案1）
- 使用 FastAPI + SQLAlchemy
- 快速开发，验证产品
- 自动API文档，方便前端对接

### 阶段2：功能完善阶段
- 根据需求调整：
  - 需要Admin后台 → 考虑Django
  - 实时通信需求多 → 考虑Django Channels
  - 需要完全异步 → 考虑Tortoise ORM

### 阶段3：性能优化阶段
- 异步优化：使用异步ORM
- 缓存优化：Redis缓存
- 数据库优化：索引、查询优化

---

**文档版本**：v1.0  
**创建日期**：2025年1月27日  
**最后更新**：2025年1月27日

