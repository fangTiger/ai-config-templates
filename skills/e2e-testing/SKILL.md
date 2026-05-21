---
name: e2e-testing
description: Use when setting up, writing, or running end-to-end tests for a deployed project. Covers API E2E, frontend UI, backend integration, and AI/model evaluation scenarios. Provides standardized directory structure, multi-framework support (pytest/Playwright/httpx), multi-format reports (Markdown/JSON/JUnit XML), marker system, and test pattern guidance.
---

# E2E Testing Skill

## Overview

端到端测试规范与脚手架，用于被部署项目的系统级测试。提供标准化目录结构、多框架支持、多格式报告和四大场景测试模式指导。

**核心原则**：E2E 测试验证已部署系统的业务流是否正确——它是"验收证明"，不是"单元验证"。

## When to Use

- 为项目创建或扩展端到端测试体系
- 编写 API 链路测试、UI 交互测试、后端集成测试
- 设置 AI/模型评测框架
- 生成测试报告（Markdown/JSON/JUnit XML）
- 需要标准化测试目录结构和命名规范

**NOT this skill（用其他 skill）：**
- 单元测试/组件测试 → `test-driven-development`
- 完成前门禁检查 → `verification-before-completion`
- Bug 调试 → `systematic-debugging`

## Boundary with Other Skills

| 维度 | TDD Skill | E2E Testing（本 skill） | Verification Skill |
|------|-----------|------------------------|-------------------|
| 定位 | 组件级、开发中 | 系统级、发布前 | 工作流门禁 |
| 速度 | 毫秒/秒级 | 分钟级 | 调度层 |
| 依赖 | Mock 隔离 | 真实基础设施 | 调用 TDD + E2E |
| 产出 | 绿灯测试 | 验收报告 | 通过/拦截决策 |

## Quick Reference

### 目录结构（必须遵循）

```
tests/e2e/
├── conftest.py              # 全局 fixtures（环境、认证、报告收集）
├── pytest.ini               # markers + 插件配置
├── e2e_config.yaml          # 环境配置（从模板复制）
├── api/                     # API 端到端测试
│   ├── conftest.py          # API client fixture
│   └── test_{domain}_{scenario}.py
├── ui/                      # 前端 UI 测试
│   ├── conftest.py          # Browser/Page fixture
│   ├── pages/               # Page Object 模型
│   │   └── base_page.py
│   └── test_{domain}_{scenario}.py
├── integration/             # 后端集成测试
│   ├── conftest.py          # DB/MQ/Cache fixture
│   └── test_{domain}_{scenario}.py
├── evaluation/              # AI/模型评测
│   ├── conftest.py          # 模型调用 fixture
│   ├── datasets/            # 黄金测试数据集（.csv/.json）
│   └── test_{domain}_{scenario}.py
└── reports/                 # 报告输出（gitignore）
    ├── YYYY-MM-DD-report.md
    ├── YYYY-MM-DD-results.json
    └── YYYY-MM-DD-junit.xml
```

### 命名规范

| 元素 | 规范 | 示例 |
|------|------|------|
| 文件 | `test_{业务域}_{场景}.py` | `test_order_create_flow.py` |
| 类 | `TestE2E{业务域}{场景}` | `TestE2EOrderCreateFlow` |
| 方法 | `test_{动作}_{预期结果}` | `test_create_order_returns_201` |

### 标记系统

```ini
[pytest]
markers =
    api: API 端到端测试
    ui: 前端 UI 测试
    integration: 后端集成测试
    evaluation: AI/模型评测
    smoke: 冒烟测试（快速验证核心路径）
    slow: 慢速测试（>30s）
    flaky: 已知不稳定测试（附原因）
    critical: 关键业务路径
```

```bash
pytest tests/e2e/ -m api              # 只跑 API 测试
pytest tests/e2e/ -m "smoke and api"  # API 冒烟测试
pytest tests/e2e/ -m "not slow"       # 跳过慢速测试
```

### 框架选择

```
测试需求 → 自动推荐：
├─ API 接口测试 → pytest + httpx/requests
├─ 页面交互测试 → pytest + playwright
├─ 数据库/MQ 测试 → pytest + 原生客户端库
├─ 模型评测 → pytest + requests + parametrize
└─ 混合场景 → 全部安装，按标记分别运行
```

## Test Discipline（强制规则）

### AAA 原则

```python
@pytest.mark.api
def test_create_order_returns_201(api_client):
    # Arrange - 准备环境和数据
    payload = {"product_id": "P001", "quantity": 2}

    # Act - 执行被测操作
    response = api_client.post("/api/orders", json=payload)

    # Assert - 验证结果（多维度）
    assert response.status_code == 201
    data = response.json()
    assert data["product_id"] == "P001"
    assert data["status"] == "created"
```

### 幂等性规则

- 每个测试必须可重复执行 N 次不因脏数据失败
- 使用 fixture 的 `yield` 进行可靠清理
- 禁止依赖其他测试的执行顺序
- 使用工厂函数生成唯一测试数据（如 UUID 前缀）

### 反脆弱规则

- **禁止** `time.sleep()`，使用显式等待
  - Playwright：`page.wait_for_selector()`、`expect(locator).to_be_visible()`
  - API：轮询重试 `poll_until(condition, timeout=10, interval=0.5)`
  - 集成：`poll_until(lambda: queue.get() is not None, timeout=30)`
- 网络请求设置合理超时（默认 30s，AI 评测 180s）
- Flaky test 标记 `@pytest.mark.flaky(reruns=2)` 并在注释中记录原因

### 敏感信息规则

- 禁止硬编码密钥、密码、Token
- 使用 `e2e_config.yaml` + 环境变量（`${E2E_PASSWORD}`）
- 报告自动脱敏：匹配 `sensitive_patterns` 的值替换为 `***`
- `.gitignore` 包含 `e2e_config.yaml`（只提交 `e2e_config.example.yaml`）

## Scene Patterns（四大场景）

### API E2E

| 模式 | 说明 |
|------|------|
| 请求链路 | 完整业务流：创建→查询→修改→删除 |
| 状态流转 | 验证资源状态在操作链中的正确变迁 |
| 契约验证 | JSON Schema 校验响应结构不发生破坏性变更 |
| 鉴权穿透 | Token 获取→刷新→过期重试 |

```python
@pytest.mark.api
@pytest.mark.critical
class TestE2EOrderLifecycle:
    """订单全生命周期 E2E 测试"""

    def test_full_lifecycle(self, api_client, api_cleanup):
        # 创建
        resp = api_client.post("/api/orders", json={"product": "A"})
        assert resp.status_code == 201
        order_id = resp.json()["id"]
        api_cleanup.track(f"/api/orders/{order_id}")  # 自动清理

        # 查询
        resp = api_client.get(f"/api/orders/{order_id}")
        assert resp.json()["status"] == "created"

        # 修改状态
        resp = api_client.patch(f"/api/orders/{order_id}", json={"status": "paid"})
        assert resp.json()["status"] == "paid"

        # 删除
        resp = api_client.delete(f"/api/orders/{order_id}")
        assert resp.status_code == 204
```

### 前端 UI

| 模式 | 说明 |
|------|------|
| Page Object | 页面元素和操作封装为类 |
| 状态注入 | 通过 API 设置前提状态（跳过 UI 登录） |
| 网络拦截 | Playwright `route` 拦截请求做 Mock |
| 截图取证 | 失败自动截图保存到 reports/ |

```python
@pytest.mark.ui
def test_login_flow(authenticated_page):
    """登录后能看到仪表盘"""
    page = authenticated_page  # 已通过 API 注入认证
    page.goto("/dashboard")
    expect(page.locator("h1")).to_have_text("仪表盘")
```

### 后端集成

| 模式 | 说明 |
|------|------|
| 依赖隔离 | 测试数据库独立于生产 |
| 异步断言 | 带超时重试的轮询（消息队列、异步任务） |
| 数据工厂 | fixture 自动构造/清理测试数据 |
| 事务回滚 | 测试结束后回滚数据变更 |

### AI/模型评测

| 模式 | 说明 |
|------|------|
| 黄金数据集驱动 | CSV/JSON 参数化测试 |
| 指标体系 | 准确率、延迟、Token 消耗、异常率 |
| 答案提取 | 从输出中提取结构化答案 |
| 分类评估 | 按任务类型分组统计 |

```python
@pytest.mark.evaluation
@pytest.mark.parametrize("case", load_dataset("graph_testset.csv"))
def test_model_accuracy(model_client, case):
    """模型准确率评测"""
    response, latency = model_client.call(case["prompt"])
    answer = extract_answer(response, model_client.model_name)
    assert answer == case["expected"], f"期望 {case['expected']}，实际 {answer}"
```

详细模式说明和代码示例见 `references/test-patterns.md`。

## Report Specification

### 4 种格式

| 格式 | 实现方式 | 用途 |
|------|---------|------|
| 终端实时 | pytest -v + pytest-sugar | 开发时 |
| JUnit XML | `--junitxml=reports/junit.xml` | CI/CD |
| JSON | report_generator.py | 分析/对比 |
| Markdown | report_generator.py | 人类可读归档 |

### 报告必含指标

- **摘要**：总用例数、通过/失败/跳过数、通过率、总耗时
- **环境上下文**：OS、Python 版本、Git Hash、依赖版本、（AI 评测：模型版本）
- **失败详情**：用例名、错误消息、堆栈摘要、（UI：截图路径）
- **耗时分析**：最慢 Top 10、各场景平均耗时
- **可追溯性（可选）**：链接到 OpenSpec 需求提案

报告生成器模板见 `templates/report_generator.py`。

## Workflow Integration（可选）

```
独立使用（默认）：
  用户调用 → Skill 指导生成测试 → 运行 → 生成报告

与 OpenSpec 集成：
  spec.md Scenario → 映射为 E2E 测试用例
  归档时 → 验证 Scenario 有对应 E2E 覆盖

与 Verification 联动：
  verification-before-completion → pytest tests/e2e/ -m smoke → 冒烟通过后放行
```

## Setup Checklist

首次为项目设置 E2E 测试时，按以下顺序执行：

1. 从模板复制目录结构到项目 `tests/e2e/`
2. 复制 `e2e_config.example.yaml` → `e2e_config.yaml` 并填写项目配置
3. 安装依赖：`pip install pytest httpx pytest-sugar pytest-xdist`
4. 按需安装：`pip install playwright pytest-playwright`（UI）
5. 按场景创建 conftest.py（从模板适配）
6. 编写测试用例（遵循命名规范 + AAA 原则）
7. 运行：`pytest tests/e2e/ -v --junitxml=tests/e2e/reports/junit.xml`
8. 生成报告：`python tests/e2e/report_generator.py`

## Common Mistakes

| 错误 | 正确做法 |
|------|---------|
| 在 E2E 中用 Mock 替代真实服务 | E2E 测试必须连接真实基础设施 |
| `time.sleep(5)` 等待异步操作 | 使用 `poll_until()` 或显式等待 |
| 硬编码 base_url 和密码 | 使用 `e2e_config.yaml` + 环境变量 |
| 测试之间共享状态 | 每个测试独立，fixture 负责 setup/teardown |
| 报告只有 pass/fail | 必须包含环境上下文、耗时、失败详情 |
| API 测试只检查状态码 | 同时验证响应体结构和业务数据 |
| AI 评测用 Mock 模型 | 必须调用真实模型 API |
| 所有测试串行执行 | 配置 pytest-xdist 并行执行（`-n auto`） |

## Templates

本 skill 提供以下模板文件，使用时复制到项目并适配：

| 模板 | 用途 |
|------|------|
| `templates/conftest_root.py` | 根 conftest（环境配置、报告收集） |
| `templates/conftest_api.py` | API 场景 fixtures |
| `templates/conftest_ui.py` | UI 场景 fixtures + Page Object 基类 |
| `templates/conftest_integration.py` | 集成场景 fixtures |
| `templates/conftest_evaluation.py` | AI 评测场景 fixtures |
| `templates/pytest_e2e.ini` | pytest 配置 |
| `templates/e2e_config.example.yaml` | 环境配置模板 |
| `templates/report_generator.py` | 多格式报告生成器 |
