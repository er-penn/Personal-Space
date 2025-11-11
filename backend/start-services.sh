#!/bin/bash

# 「边界舱」后端项目快速启动脚本

set -e

echo "🚀 启动「边界舱」后端服务..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker Desktop"
    exit 1
fi

# 检查是否在backend目录
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 请在backend目录下运行此脚本"
    exit 1
fi

# 启动PostgreSQL和Redis
echo "📦 启动PostgreSQL和Redis..."
docker-compose up -d

# 等待服务就绪
echo "⏳ 等待服务就绪..."
sleep 5

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

echo ""
echo "✅ PostgreSQL和Redis已启动！"
echo ""
echo "下一步操作："
echo "1. 创建虚拟环境: python -m venv venv"
echo "2. 激活虚拟环境: source venv/bin/activate"
echo "3. 安装依赖: pip install -r requirements.txt"
echo "4. 配置环境变量: cp .env.example .env"
echo "5. 运行迁移: python manage.py makemigrations && python manage.py migrate"
echo "6. 创建超级用户: python manage.py createsuperuser"
echo "7. 启动Django: python manage.py runserver"
echo ""
echo "查看日志: docker-compose logs -f"
echo "停止服务: docker-compose down"

