# -*- coding: utf-8 -*-
"""
API 场景 conftest.py

提供 fixtures：
- api_client: 带认证的 httpx Client
- api_cleanup: 自动清理创建的资源
- assert_json_schema: JSON Schema 契约验证
"""

import httpx
import pytest
from typing import Optional


@pytest.fixture(scope="session")
def auth_token(e2e_config, base_url) -> Optional[str]:
    """获取认证 Token"""
    auth_config = e2e_config.get("auth", {})
    auth_type = auth_config.get("type", "none")

    if auth_type == "none":
        return None

    token_url = auth_config.get("token_url", "/api/auth/token")
    username = auth_config.get("username", "")
    password = auth_config.get("password", "")

    response = httpx.post(
        f"{base_url}{token_url}",
        json={"username": username, "password": password},
        timeout=e2e_config.get("timeout", 30),
    )
    response.raise_for_status()
    return response.json().get("access_token", response.json().get("token"))


@pytest.fixture
def api_client(e2e_config, base_url, auth_token):
    """带认证的 API 客户端"""
    headers = {"Content-Type": "application/json"}
    if auth_token:
        auth_type = e2e_config.get("auth", {}).get("type", "bearer")
        if auth_type == "bearer":
            headers["Authorization"] = f"Bearer {auth_token}"

    with httpx.Client(
        base_url=base_url,
        headers=headers,
        timeout=e2e_config.get("timeout", 30),
    ) as client:
        yield client


class ResourceCleanup:
    """追踪并自动清理测试创建的资源"""

    def __init__(self, client: httpx.Client):
        self._client = client
        self._resources: list[str] = []

    def track(self, resource_url: str):
        """记录需要清理的资源 URL"""
        self._resources.append(resource_url)

    def cleanup(self):
        """按 LIFO 顺序删除资源"""
        for url in reversed(self._resources):
            try:
                self._client.delete(url)
            except Exception:
                pass  # 清理失败不影响测试结果
        self._resources.clear()


@pytest.fixture
def api_cleanup(api_client):
    """资源自动清理 fixture"""
    cleaner = ResourceCleanup(api_client)
    yield cleaner
    cleaner.cleanup()


def assert_json_schema(data: dict, schema: dict):
    """JSON Schema 契约验证

    用法：
        assert_json_schema(response.json(), {
            "type": "object",
            "required": ["id", "status"],
            "properties": {
                "id": {"type": "string"},
                "status": {"type": "string", "enum": ["created", "paid", "shipped"]},
            }
        })
    """
    try:
        import jsonschema
        jsonschema.validate(instance=data, schema=schema)
    except ImportError:
        # jsonschema 未安装时降级为基本检查
        required = schema.get("required", [])
        for field in required:
            assert field in data, f"响应缺少必填字段: {field}"
