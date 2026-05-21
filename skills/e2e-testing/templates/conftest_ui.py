# -*- coding: utf-8 -*-
"""
UI 场景 conftest.py

提供 fixtures：
- browser_context: Playwright 浏览器上下文
- page: 带自动截图的页面实例
- authenticated_page: 已注入认证状态的页面

依赖：pip install playwright pytest-playwright
"""

import pytest
from pathlib import Path
from datetime import datetime


@pytest.fixture(scope="session")
def browser_type_launch_args(e2e_config):
    """Playwright 浏览器启动参数"""
    ui_config = e2e_config.get("ui", {})
    return {
        "headless": ui_config.get("headless", True),
    }


@pytest.fixture(scope="session")
def browser_context_args(e2e_config):
    """Playwright 浏览器上下文参数"""
    ui_config = e2e_config.get("ui", {})
    viewport = ui_config.get("viewport", {"width": 1280, "height": 720})
    return {
        "viewport": viewport,
        "locale": "zh-CN",
    }


@pytest.fixture
def page(context, e2e_config, request):
    """带自动截图的页面实例

    测试失败时自动截图保存到 reports/screenshots/
    """
    _page = context.new_page()
    yield _page

    # 失败时自动截图
    ui_config = e2e_config.get("ui", {})
    if request.node.rep_call and request.node.rep_call.failed:
        if ui_config.get("screenshot_on_failure", True):
            screenshots_dir = Path("tests/e2e/reports/screenshots")
            screenshots_dir.mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            test_name = request.node.name.replace("/", "_").replace("::", "_")
            screenshot_path = screenshots_dir / f"{test_name}_{timestamp}.png"
            _page.screenshot(path=str(screenshot_path))

    _page.close()


@pytest.fixture
def authenticated_page(page, base_url, auth_token, e2e_config):
    """已注入认证状态的页面（跳过 UI 登录流程）

    通过 API 获取 Token 后注入到浏览器 Cookie/localStorage
    """
    if auth_token:
        auth_type = e2e_config.get("auth", {}).get("type", "bearer")
        page.goto(base_url)

        if auth_type == "bearer":
            # 注入 Token 到 localStorage
            page.evaluate(f"localStorage.setItem('token', '{auth_token}')")
        elif auth_type == "cookie":
            # 注入认证 Cookie
            page.context.add_cookies([{
                "name": "session",
                "value": auth_token,
                "url": base_url,
            }])

    return page


# ============================================================
# Page Object 基类（也可放在 pages/base_page.py）
# ============================================================

class BasePage:
    """Page Object 基类

    用法：
        class LoginPage(BasePage):
            URL = "/login"

            @property
            def username_input(self):
                return self.page.locator("#username")

            def login(self, username, password):
                self.navigate()
                self.username_input.fill(username)
                self.page.locator("#password").fill(password)
                self.page.locator("button[type=submit]").click()
    """

    URL = "/"

    def __init__(self, page, base_url: str):
        self.page = page
        self.base_url = base_url

    def navigate(self):
        """导航到页面"""
        self.page.goto(f"{self.base_url}{self.URL}")

    def screenshot(self, name: str = "screenshot") -> str:
        """截图并返回路径"""
        screenshots_dir = Path("tests/e2e/reports/screenshots")
        screenshots_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        path = screenshots_dir / f"{name}_{timestamp}.png"
        self.page.screenshot(path=str(path))
        return str(path)

    def wait_for_load(self, timeout: int = 10000):
        """等待页面加载完成"""
        self.page.wait_for_load_state("networkidle", timeout=timeout)
