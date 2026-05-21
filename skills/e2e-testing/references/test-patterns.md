# E2E 测试模式速查表

## 框架选择决策树

```
测试需求 → 框架选择：
├─ API 接口 → pytest + httpx（同步）或 pytest + httpx + pytest-asyncio（异步）
├─ 浏览器 UI → pytest + playwright（pytest-playwright 插件）
├─ 数据库/缓存 → pytest + SQLAlchemy/redis-py（原生客户端）
├─ 消息队列 → pytest + pika/kafka-python（原生客户端）
├─ 模型评测 → pytest + requests + pytest.mark.parametrize
└─ 混合 → 全部安装，按 marker 分别运行
```

## 常用 pytest 插件

| 插件 | 用途 | 安装 |
|------|------|------|
| pytest-xdist | 并行执行 (`-n auto`) | `pip install pytest-xdist` |
| pytest-sugar | 美化终端输出 | `pip install pytest-sugar` |
| pytest-rerunfailures | 失败重试 | `pip install pytest-rerunfailures` |
| pytest-playwright | Playwright 集成 | `pip install pytest-playwright` |
| pytest-asyncio | 异步测试 | `pip install pytest-asyncio` |
| pytest-timeout | 超时控制 | `pip install pytest-timeout` |

## API E2E 模式

### 请求链路（CRUD 全流程）

```python
@pytest.mark.api
@pytest.mark.critical
def test_resource_lifecycle(api_client, api_cleanup):
    # 创建
    resp = api_client.post("/api/resources", json={"name": "test"})
    assert resp.status_code == 201
    resource_id = resp.json()["id"]
    api_cleanup.track(f"/api/resources/{resource_id}")

    # 读取
    resp = api_client.get(f"/api/resources/{resource_id}")
    assert resp.status_code == 200
    assert resp.json()["name"] == "test"

    # 更新
    resp = api_client.put(f"/api/resources/{resource_id}", json={"name": "updated"})
    assert resp.status_code == 200

    # 删除
    resp = api_client.delete(f"/api/resources/{resource_id}")
    assert resp.status_code == 204
```

### 契约验证（JSON Schema）

```python
ORDER_SCHEMA = {
    "type": "object",
    "required": ["id", "status", "items", "total"],
    "properties": {
        "id": {"type": "string"},
        "status": {"type": "string", "enum": ["created", "paid", "shipped", "delivered"]},
        "items": {"type": "array", "minItems": 1},
        "total": {"type": "number", "minimum": 0},
    }
}

@pytest.mark.api
def test_order_contract(api_client):
    resp = api_client.post("/api/orders", json={"items": [{"id": "P1", "qty": 1}]})
    assert_json_schema(resp.json(), ORDER_SCHEMA)
```

### 鉴权穿透

```python
@pytest.mark.api
def test_unauthorized_access(base_url):
    """无 Token 访问受保护端点应返回 401"""
    client = httpx.Client(base_url=base_url)
    resp = client.get("/api/protected")
    assert resp.status_code == 401
```

## 前端 UI 模式

### Page Object

```python
# pages/login_page.py
class LoginPage(BasePage):
    URL = "/login"

    @property
    def username_input(self):
        return self.page.locator("#username")

    @property
    def password_input(self):
        return self.page.locator("#password")

    @property
    def submit_button(self):
        return self.page.locator("button[type=submit]")

    def login(self, username: str, password: str):
        self.navigate()
        self.username_input.fill(username)
        self.password_input.fill(password)
        self.submit_button.click()
        self.page.wait_for_url("**/dashboard**")

# tests
@pytest.mark.ui
def test_login_success(page, base_url):
    login_page = LoginPage(page, base_url)
    login_page.login("testuser", "testpass")
    expect(page).to_have_url(re.compile(r"/dashboard"))
```

### 网络拦截

```python
@pytest.mark.ui
def test_with_mocked_api(page, base_url):
    """拦截 API 请求返回 Mock 数据"""
    def handle_route(route):
        route.fulfill(
            status=200,
            content_type="application/json",
            body=json.dumps({"items": [{"name": "Mock Item"}]})
        )

    page.route("**/api/items", handle_route)
    page.goto(f"{base_url}/items")
    expect(page.locator(".item-name")).to_have_text("Mock Item")
```

## 后端集成模式

### 异步轮询断言

```python
@pytest.mark.integration
def test_async_task_completion(api_client):
    # 触发异步任务
    resp = api_client.post("/api/tasks", json={"type": "process_data"})
    task_id = resp.json()["task_id"]

    # 轮询等待完成
    result = poll_until(
        lambda: api_client.get(f"/api/tasks/{task_id}").json().get("status") == "completed",
        timeout=60,
        interval=2,
        message=f"任务 {task_id} 未在 60s 内完成"
    )
```

### 数据工厂 + 事务回滚

```python
@pytest.mark.integration
def test_user_creation(db_session, data_factory):
    user_data = data_factory.create("user", name="张三", email="test@example.com")
    # user_data["name"] 已自动添加前缀：e2e_abc12345_张三

    # 插入数据库（使用项目的 ORM）
    user = User(**user_data)
    db_session.add(user)
    db_session.flush()

    assert user.id is not None
    # db_session 会在 fixture teardown 时自动回滚
```

## AI/模型评测模式

### 黄金数据集参数化

```python
@pytest.mark.evaluation
@pytest.mark.parametrize("case", load_dataset("qa_testset.csv"))
def test_qa_accuracy(model_client, case, eval_metrics):
    response, latency = model_client.call(case["prompt"])
    answer = extract_answer(response, model_client.model_name)
    is_correct = answer.strip() == case["expected"].strip()

    eval_metrics.record(
        category=case.get("category", "general"),
        correct=is_correct,
        latency=latency,
    )
    assert is_correct, f"期望: {case['expected']}, 实际: {answer}"
```

## 常见反模式

| 反模式 | 问题 | 正确做法 |
|--------|------|---------|
| `time.sleep(5)` | 不可靠，浪费时间 | `poll_until()` 或 Playwright 显式等待 |
| 共享测试数据 | 测试间耦合 | 每个测试独立的 fixture + 数据工厂 |
| 硬编码 URL | 环境不可迁移 | `e2e_config.yaml` + 环境变量 |
| 只断言状态码 | 遗漏业务逻辑错误 | 同时断言状态码 + 响应体 + 业务状态 |
| Mock 替代真实服务 | 违背 E2E 初衷 | 连接真实基础设施 |
| 串行全量执行 | 太慢 | `pytest-xdist -n auto` + marker 分组 |
| 忽略 flaky test | 降低信心 | 标记 `@pytest.mark.flaky` + 根因分析 |
