# -*- coding: utf-8 -*-
"""
后端集成场景 conftest.py

提供 fixtures：
- db_session: 数据库会话（带事务回滚）
- redis_client: Redis 测试连接
- poll_until: 异步轮询断言工具
- data_factory: 测试数据构造/清理
"""

import time
import uuid
import pytest
from typing import Callable, Any, Optional


def poll_until(
    condition: Callable[[], Any],
    timeout: float = 10.0,
    interval: float = 0.5,
    message: str = "条件未在超时时间内满足"
) -> Any:
    """轮询等待条件满足

    用法：
        # 等待消息队列中出现消息
        result = poll_until(lambda: queue.get_nowait(), timeout=30, interval=1)

        # 等待异步任务完成
        poll_until(lambda: get_task_status(task_id) == "completed", timeout=60)
    """
    start = time.monotonic()
    last_error = None
    while time.monotonic() - start < timeout:
        try:
            result = condition()
            if result:
                return result
        except Exception as e:
            last_error = e
        time.sleep(interval)

    error_detail = f" (最后错误: {last_error})" if last_error else ""
    raise TimeoutError(f"{message} (超时 {timeout}s){error_detail}")


@pytest.fixture(scope="session")
def db_engine(e2e_config):
    """创建数据库引擎（按实际项目适配）

    示例使用 SQLAlchemy，请根据项目实际 ORM 修改
    """
    db_url = e2e_config.get("integration", {}).get("database_url", "")
    if not db_url or db_url.startswith("$"):
        pytest.skip("未配置数据库连接，跳过集成测试")

    try:
        from sqlalchemy import create_engine
        engine = create_engine(db_url)
        yield engine
        engine.dispose()
    except ImportError:
        pytest.skip("SQLAlchemy 未安装，跳过数据库测试")


@pytest.fixture
def db_session(db_engine):
    """带事务回滚的数据库会话

    测试结束后自动回滚，保证测试幂等性
    """
    from sqlalchemy.orm import sessionmaker
    Session = sessionmaker(bind=db_engine)
    session = Session()
    yield session
    session.rollback()
    session.close()


@pytest.fixture(scope="session")
def redis_client(e2e_config):
    """Redis 测试连接"""
    redis_url = e2e_config.get("integration", {}).get("redis_url", "")
    if not redis_url or redis_url.startswith("$"):
        pytest.skip("未配置 Redis 连接，跳过 Redis 测试")

    try:
        import redis
        client = redis.from_url(redis_url)
        client.ping()  # 验证连接
        yield client
        client.close()
    except ImportError:
        pytest.skip("redis 库未安装，跳过 Redis 测试")


class DataFactory:
    """测试数据工厂

    自动生成带 UUID 前缀的测试数据，yield 后自动清理

    用法：
        def test_create_user(data_factory, db_session):
            user_data = data_factory.create("user", name="测试用户")
            # ... 测试逻辑 ...
            # 测试结束后 data_factory 自动清理
    """

    def __init__(self):
        self._created: list[dict] = []
        self._prefix = uuid.uuid4().hex[:8]

    def create(self, resource_type: str, **kwargs) -> dict:
        """构造测试数据"""
        data = {
            "resource_type": resource_type,
            "test_prefix": self._prefix,
            **kwargs,
        }
        # 为名称类字段自动添加前缀
        for key in ["name", "title", "username", "email"]:
            if key in data and isinstance(data[key], str):
                data[key] = f"e2e_{self._prefix}_{data[key]}"
        self._created.append(data)
        return data

    def cleanup(self, cleanup_fn: Optional[Callable] = None):
        """清理所有创建的测试数据"""
        if cleanup_fn:
            for item in reversed(self._created):
                try:
                    cleanup_fn(item)
                except Exception:
                    pass
        self._created.clear()


@pytest.fixture
def data_factory():
    """测试数据工厂 fixture"""
    factory = DataFactory()
    yield factory
    factory.cleanup()
