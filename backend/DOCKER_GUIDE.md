# 「边界舱」后端项目 - Docker启动指南

## 前置要求

- Docker Desktop（Mac/Windows）或 Docker Engine（Linux）
- Docker Compose

## 快速启动（推荐方式）

### 方式1：仅启动数据库和Redis（推荐用于开发）

这种方式只启动PostgreSQL和Redis，Django应用在本地运行：

```bash
# 1. 启动PostgreSQL和Redis
docker-compose up -d

# 2. 检查服务状态
docker-compose ps

# 3. 在本地创建虚拟环境并安装依赖
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 4. 配置环境变量（使用.env文件）
cp .env.example .env
# 编辑.env文件，确保数据库和Redis配置正确：
# DB_HOST=localhost
# REDIS_HOST=localhost

# 5. 运行数据库迁移
python manage.py makemigrations
python manage.py migrate

# 6. 创建超级用户
python manage.py createsuperuser

# 7. 启动Django开发服务器
python manage.py runserver

# 8. 启动Celery Worker（新终端）
celery -A config worker -l info

# 9. 启动Celery Beat（新终端）
celery -A config beat -l info
```

### 方式2：完全Docker化（所有服务都在Docker中）

```bash
# 1. 启动所有服务（包括Django、Celery等）
docker-compose -f docker-compose.dev.yml up -d

# 2. 查看日志
docker-compose -f docker-compose.dev.yml logs -f

# 3. 运行数据库迁移（在Django容器中）
docker-compose -f docker-compose.dev.yml exec django python manage.py makemigrations
docker-compose -f docker-compose.dev.yml exec django python manage.py migrate

# 4. 创建超级用户（在Django容器中）
docker-compose -f docker-compose.dev.yml exec django python manage.py createsuperuser

# 5. 访问服务
# Django: http://localhost:8000
# API文档: http://localhost:8000/api/docs/
```

## 服务说明

### PostgreSQL数据库
- 端口: 5432
- 数据库名: boundary_capsule
- 用户名: postgres
- 密码: postgres
- 数据持久化: postgres_data volume

### Redis
- 端口: 6379
- 数据持久化: redis_data volume

### Django应用
- 端口: 8000
- API文档: http://localhost:8000/api/docs/

### Celery Worker
- 处理异步任务

### Celery Beat
- 定时任务调度器

## 常用命令

### 启动服务
```bash
# 仅数据库和Redis
docker-compose up -d

# 所有服务
docker-compose -f docker-compose.dev.yml up -d
```

### 停止服务
```bash
# 停止并删除容器
docker-compose down

# 停止并删除容器和数据卷（⚠️ 会删除数据库数据）
docker-compose down -v
```

### 查看日志
```bash
# 所有服务日志
docker-compose logs -f

# 特定服务日志
docker-compose logs -f django
docker-compose logs -f celery_worker
```

### 进入容器
```bash
# 进入Django容器
docker-compose exec django bash

# 进入PostgreSQL容器
docker-compose exec postgres psql -U postgres -d boundary_capsule
```

### 数据库迁移（在容器中）
```bash
# 创建迁移文件
docker-compose exec django python manage.py makemigrations

# 执行迁移
docker-compose exec django python manage.py migrate
```

## 数据库表创建状态

**数据库表尚未创建**，需要执行以下步骤：

### 如果使用方式1（本地运行Django）

```bash
# 1. 确保PostgreSQL和Redis已启动
docker-compose up -d

# 2. 运行迁移
python manage.py makemigrations
python manage.py migrate

# 3. 验证表是否创建（可选）
docker-compose exec postgres psql -U postgres -d boundary_capsule -c "\dt"
```

### 如果使用方式2（完全Docker化）

```bash
# 1. 确保所有服务已启动
docker-compose -f docker-compose.dev.yml up -d

# 2. 等待服务就绪（约10-20秒）
docker-compose -f docker-compose.dev.yml ps

# 3. 运行迁移
docker-compose -f docker-compose.dev.yml exec django python manage.py makemigrations
docker-compose -f docker-compose.dev.yml exec django python manage.py migrate

# 4. 验证表是否创建
docker-compose -f docker-compose.dev.yml exec postgres psql -U postgres -d boundary_capsule -c "\dt"
```

## 环境变量配置

### 方式1：使用.env文件（本地开发）

复制 `.env.example` 为 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件：
```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

DB_NAME=boundary_capsule
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432

REDIS_HOST=localhost
REDIS_PORT=6379
```

### 方式2：Docker Compose自动配置

如果使用 `docker-compose.dev.yml`，环境变量会自动设置，无需手动配置。

## 故障排查

### 1. 端口被占用

如果5432或6379端口被占用，修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "5433:5432"  # 改为其他端口
```

### 2. 数据库连接失败

检查服务是否启动：
```bash
docker-compose ps
```

检查数据库日志：
```bash
docker-compose logs postgres
```

### 3. Redis连接失败

检查Redis服务：
```bash
docker-compose logs redis
```

测试Redis连接：
```bash
docker-compose exec redis redis-cli ping
```

### 4. Django无法启动

查看Django日志：
```bash
docker-compose logs django
```

检查依赖是否安装：
```bash
docker-compose exec django pip list
```

## 下一步

1. ✅ 启动PostgreSQL和Redis（使用Docker）
2. ✅ 运行数据库迁移（创建表）
3. ✅ 创建超级用户
4. ✅ 启动Django开发服务器
5. ✅ 启动Celery Worker和Beat
6. ✅ 访问API文档：http://localhost:8000/api/docs/

## 生产环境部署

生产环境建议：
- 使用独立的PostgreSQL和Redis服务器
- 使用Gunicorn + Nginx部署Django
- 使用Daphne或Uvicorn部署WebSocket服务
- 配置SSL证书
- 设置环境变量和密钥管理

