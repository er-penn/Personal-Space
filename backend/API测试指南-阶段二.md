# API测试指南 - 阶段二

## 测试前准备

1. 确保Django服务正在运行：
```bash
cd backend
source venv/bin/activate
python manage.py runserver
```

2. 获取认证Token（如果还没有）：
```bash
# 注册用户
curl -X POST http://127.0.0.1:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "password": "123456",
    "password_confirm": "123456",
    "nickname": "测试用户"
  }'

# 登录获取Token
curl -X POST http://127.0.0.1:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "password": "123456"
  }'
```

## API测试步骤

### 1. 获取当前能量状态

**接口**: `GET /api/v1/energy/current-status/`

**测试命令**:
```bash
curl -X GET http://127.0.0.1:8000/api/v1/energy/current-status/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**:
```json
{
  "current_status": {
    "base_energy_level": "⚪",
    "display_energy_level": "⚪",
    "temporary_state": {
      "is_active": false,
      "type": null,
      "remaining_minutes": 0
    },
    "planned_state": {
      "is_active": false,
      "level": null,
      "remaining_minutes": 0
    }
  },
  "partner_status": null
}
```

**验证点**:
- ✅ 返回状态码200
- ✅ 包含current_status和partner_status字段
- ✅ base_energy_level和display_energy_level字段存在
- ✅ temporary_state和planned_state结构正确

---

### 2. 更新当前能量状态

**接口**: `PUT /api/v1/energy/current-status/`

**测试命令**:
```bash
curl -X PUT http://127.0.0.1:8000/api/v1/energy/current-status/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "energy_level": "🟢"
  }'
```

**预期响应**:
```json
{
  "energy_level": "🟢",
  "updated_at": "2025-01-27T10:00:00Z"
}
```

**验证点**:
- ✅ 返回状态码200
- ✅ energy_level已更新
- ✅ updated_at字段存在
- ✅ 再次调用获取当前状态API，base_energy_level应为"🟢"

---

### 3. 获取能量记录

**接口**: `GET /api/v1/energy/records/`

**测试命令**:
```bash
# 获取今天的记录
curl -X GET "http://127.0.0.1:8000/api/v1/energy/records/?date=2025-01-27" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 获取特定类型的记录
curl -X GET "http://127.0.0.1:8000/api/v1/energy/records/?type=base" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**:
```json
{
  "records": {
    "base": [],
    "planned": [],
    "temporary": []
  },
  "summary": {
    "high_minutes": 0,
    "medium_minutes": 0,
    "low_minutes": 0,
    "unplanned_minutes": 0
  }
}
```

**验证点**:
- ✅ 返回状态码200
- ✅ records包含base、planned、temporary三个数组
- ✅ summary包含各状态的分钟数统计

---

### 4. 创建能量预规划

**接口**: `POST /api/v1/energy/plans/create/`

**测试命令**:
```bash
curl -X POST http://127.0.0.1:8000/api/v1/energy/plans/create/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2025-01-27",
    "energy_level": "🟡",
    "time_slots": [
      {
        "start_hour": 14,
        "start_minute": 0,
        "end_hour": 18,
        "end_minute": 0
      }
    ]
  }'
```

**预期响应**:
```json
{
  "id": "uuid",
  "date": "2025-01-27",
  "energy_level": "🟡",
  "time_slots": [
    {
      "start_hour": 14,
      "start_minute": 0,
      "end_hour": 18,
      "end_minute": 0
    }
  ],
  "created_at": "2025-01-27T10:00:00Z"
}
```

**验证点**:
- ✅ 返回状态码201（新建）或200（更新）
- ✅ 返回的id、date、energy_level、time_slots正确
- ✅ 再次调用获取预规划API，应能看到创建的记录

---

### 5. 获取能量预规划

**接口**: `GET /api/v1/energy/plans/`

**测试命令**:
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/energy/plans/?date=2025-01-27" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**:
```json
{
  "plans": [
    {
      "id": "uuid",
      "date": "2025-01-27",
      "energy_level": "🟡",
      "time_slots": [...],
      "created_at": "2025-01-27T10:00:00Z"
    }
  ]
}
```

**验证点**:
- ✅ 返回状态码200
- ✅ plans数组包含之前创建的预规划记录

---

### 6. 创建临时状态

**接口**: `POST /api/v1/energy/temporary-state/`

**测试命令**:
```bash
curl -X POST http://127.0.0.1:8000/api/v1/energy/temporary-state/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fastCharge",
    "duration_minutes": 120
  }'
```

**预期响应**:
```json
{
  "id": "uuid",
  "type": "fastCharge",
  "start_time": "2025-01-27T10:00:00Z",
  "end_time": "2025-01-27T12:00:00Z",
  "remaining_minutes": 120
}
```

**验证点**:
- ✅ 返回状态码201
- ✅ type、start_time、end_time、remaining_minutes正确
- ✅ 再次调用获取当前状态API，temporary_state.is_active应为true

---

### 7. 结束临时状态

**接口**: `DELETE /api/v1/energy/temporary-state/end/`

**测试命令**:
```bash
curl -X DELETE http://127.0.0.1:8000/api/v1/energy/temporary-state/end/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "临时状态ID（可选）"
  }'
```

**预期响应**:
```json
{
  "message": "临时状态已结束"
}
```

**验证点**:
- ✅ 返回状态码200
- ✅ 再次调用获取当前状态API，temporary_state.is_active应为false

---

### 8. 获取伴侣状态

**接口**: `GET /api/v1/energy/partner-status/`

**测试命令**:
```bash
curl -X GET http://127.0.0.1:8000/api/v1/energy/partner-status/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**（如果有伴侣）:
```json
{
  "partner_status": {
    "energy_level": "🟡",
    "records": {
      "base": [...]
    }
  }
}
```

**预期响应**（如果没有伴侣）:
```json
{
  "detail": "未找到活跃的关系"
}
```

**验证点**:
- ✅ 返回状态码200（有伴侣）或404（无伴侣）
- ✅ partner_status包含energy_level和records字段

---

## 错误情况测试

### 1. 无效的能量状态

```bash
curl -X PUT http://127.0.0.1:8000/api/v1/energy/current-status/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "energy_level": "无效状态"
  }'
```

**预期**: 返回400错误，提示"无效的能量状态"

### 2. 无效的日期格式

```bash
curl -X GET "http://127.0.0.1:8000/api/v1/energy/records/?date=2025/01/27" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期**: 返回400错误，提示"日期格式错误"

### 3. 未认证请求

```bash
curl -X GET http://127.0.0.1:8000/api/v1/energy/current-status/
```

**预期**: 返回401错误

---

## 验证清单

完成所有测试后，请确认：

- [ ] 所有API都能正常响应
- [ ] 数据格式符合方案要求
- [ ] 错误处理正确
- [ ] 认证机制正常工作
- [ ] 数据持久化到数据库
- [ ] 伴侣状态功能正常（需要两个用户建立关系）

## 注意事项

1. 测试时需要替换`YOUR_ACCESS_TOKEN`为实际的访问令牌
2. 日期参数使用当前日期或测试日期
3. 如果测试伴侣状态，需要先建立两个用户之间的关系
4. 临时状态的duration_minutes不能超过1440分钟（24小时）

