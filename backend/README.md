# 「边界舱」后端项目

## 技术栈

- Django 4.2+
- Django REST Framework 3.14+
- Django Channels 4.0+
- Celery + Redis
- PostgreSQL 14+
- Redis 7+

## 项目结构

```
backend/
├── config/                 # Django配置
│   ├── settings.py        # 项目设置
│   ├── urls.py            # URL路由
│   ├── asgi.py            # ASGI配置（WebSocket）
│   ├── wsgi.py            # WSGI配置
│   ├── celery.py          # Celery配置
│   └── routing.py         # WebSocket路由
├── apps/                   # 应用模块
│   ├── users/             # 用户管理
│   ├── relationships/     # 关系管理
│   ├── energy/            # 能量状态管理
│   ├── invitations/       # 协作邀请
│   ├── closures/          # 安心确认
│   ├── gift_boxes/        # 心意盒
│   ├── fragments/         # 碎片
│   ├── moments/           # 瞬间
│   ├── notifications/      # 通知
│   └── websocket/         # WebSocket处理
├── tasks/                  # Celery定时任务
│   ├── energy_tasks.py    # 能量状态任务
│   └── expiration_tasks.py # 过期检查任务
├── common/                 # 公共模块
│   ├── permissions.py     # 权限类
│   └── utils.py           # 工具函数
├── requirements.txt       # Python依赖
├── manage.py              # Django管理脚本
└── README.md              # 项目说明
```

## 快速开始

### 方式1：使用Docker启动数据库和Redis（推荐）

**前置要求：**
- Docker Desktop（Mac/Windows）或 Docker Engine（Linux）
- Python 3.9+

**步骤：**

1. **启动PostgreSQL和Redis（使用Docker）**
   ```bash
   # 方式A：使用快速启动脚本
   ./start-services.sh
   
   # 方式B：手动启动
   docker-compose up -d
   ```

2. **创建虚拟环境并安装依赖**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑.env文件，确保配置正确（默认配置已适配Docker）
   ```

4. **运行数据库迁移（创建表）**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. **创建超级用户**
   ```bash
   python manage.py createsuperuser
   ```

6. **启动Django开发服务器**
   ```bash
   python manage.py runserver
   ```

7. **启动Celery Worker（新终端）**
   ```bash
   celery -A config worker -l info
   ```

8. **启动Celery Beat（新终端）**
   ```bash
   celery -A config beat -l info
   ```

### 方式2：完全Docker化（所有服务都在Docker中）

详细说明请查看 [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

```bash
# 启动所有服务
docker-compose -f docker-compose.dev.yml up -d

# 运行迁移
docker-compose -f docker-compose.dev.yml exec django python manage.py makemigrations
docker-compose -f docker-compose.dev.yml exec django python manage.py migrate
```

## 数据库表创建状态

**数据库表尚未创建**，需要执行迁移命令：

```bash
python manage.py makemigrations
python manage.py migrate
```

迁移完成后，可以使用以下命令验证表是否创建：

```bash
# 如果使用Docker
docker-compose exec postgres psql -U postgres -d boundary_capsule -c "\dt"

# 或者直接连接数据库查看
```

## API文档

启动服务后访问：http://localhost:8000/api/docs/

## WebSocket连接

### 能量状态WebSocket

```
ws://localhost:8000/ws/energy/?token=jwt_token
```

### 通知WebSocket

```
ws://localhost:8000/ws/notifications/?token=jwt_token
```

## 主要功能模块

### 1. 用户认证
- JWT Token认证
- 用户注册/登录
- 用户信息管理

### 2. 关系管理
- 关系邀请/接受
- Maybe清单
- 成长花园

### 3. 能量状态
- 能量状态管理（🟢/🟡/🔴）
- 临时状态（快充/低电量）
- 预规划状态
- 实时状态同步（WebSocket）

### 4. 协作邀请
- 创建/响应邀请
- 邀请状态管理

### 5. 安心确认
- 创建/响应确认
- 过期检查

### 6. 心意盒
- 创建/响应心意盒
- 有效期管理

### 7. 碎片
- 发送/接收碎片
- 已读状态管理

### 8. 瞬间
- 发布瞬间
- 文案隐藏规则（3天）

### 9. 通知
- 实时通知推送（WebSocket）
- 通知管理

## 定时任务

### 每分钟执行
- `process_energy_state_minute`: 处理能量状态（追加时间段、检查状态切换）

### 每小时执行
- `check_expired_items`: 检查过期项（安心确认、心意盒）

### 每天0点执行
- `reset_daily_state`: 重置每日状态

## 开发说明

### 代码结构

- **models.py**: 数据库模型
- **serializers.py**: 序列化器（DRF）
- **views.py**: 视图函数/视图集
- **urls.py**: URL路由配置
- **services.py**: 业务逻辑服务层
- **consumers.py**: WebSocket消费者

### 数据库模型

主要模型包括：
- `User`: 用户
- `Relationship`: 关系
- `EnergyRecord`: 能量状态记录
- `CollaborationInvitation`: 协作邀请
- `PeacefulClosure`: 安心确认
- `GiftBox`: 心意盒
- `Fragment`: 碎片
- `Moment`: 瞬间
- `Notification`: 通知

## 部署说明

### 生产环境配置

1. 修改 `DEBUG = False`
2. 设置安全的 `SECRET_KEY`
3. 配置 `ALLOWED_HOSTS`
4. 使用生产级数据库和Redis
5. 配置静态文件服务
6. 使用Gunicorn或uWSGI作为WSGI服务器
7. 使用Daphne或Uvicorn作为ASGI服务器（WebSocket）

### Docker部署（可选）

可以创建 `Dockerfile` 和 `docker-compose.yml` 进行容器化部署。

## 许可证

MIT License

