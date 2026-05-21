# -*- coding: utf-8 -*-
"""
E2E 测试根 conftest.py

提供全局 fixtures：
- e2e_config: 加载配置文件
- report_collector: 收集测试结果用于报告生成
- pytest hooks: 捕获每条用例的结果和耗时
"""

import os
import re
import json
import yaml
import pytest
import platform
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any


# ============================================================
# 配置加载
# ============================================================

def _resolve_env_vars(value: str) -> str:
    """将 ${ENV_VAR} 替换为环境变量值"""
    pattern = re.compile(r'\$\{(\w+)\}')
    def replacer(match):
        env_key = match.group(1)
        return os.environ.get(env_key, match.group(0))
    return pattern.sub(replacer, str(value))


def _resolve_config(obj: Any) -> Any:
    """递归解析配置中的环境变量"""
    if isinstance(obj, str):
        return _resolve_env_vars(obj)
    elif isinstance(obj, dict):
        return {k: _resolve_config(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_resolve_config(item) for item in obj]
    return obj


@pytest.fixture(scope="session")
def e2e_config():
    """加载 E2E 测试配置"""
    config_path = Path(__file__).parent / "e2e_config.yaml"
    if not config_path.exists():
        pytest.skip("e2e_config.yaml 未找到，请从 e2e_config.example.yaml 复制并配置")

    with open(config_path, "r", encoding="utf-8") as f:
        raw_config = yaml.safe_load(f)

    return _resolve_config(raw_config.get("e2e", {}))


@pytest.fixture(scope="session")
def base_url(e2e_config):
    """获取被测系统基础 URL"""
    return e2e_config.get("base_url", "http://localhost:8000")


# ============================================================
# 环境上下文收集
# ============================================================

def _get_git_hash() -> str:
    """获取当前 Git commit hash"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip() if result.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


@pytest.fixture(scope="session")
def env_context():
    """收集环境上下文信息"""
    return {
        "os": f"{platform.system()} {platform.release()}",
        "python": platform.python_version(),
        "git_hash": _get_git_hash(),
        "timestamp": datetime.now().isoformat(),
        "machine": platform.machine(),
    }


# ============================================================
# 报告收集器
# ============================================================

class ReportCollector:
    """收集测试结果用于报告生成"""

    def __init__(self):
        self.results = []
        self.start_time = datetime.now()

    def add_result(self, nodeid: str, outcome: str, duration: float,
                   error: str = "", screenshot: str = "", category: str = ""):
        """记录单条测试结果"""
        self.results.append({
            "nodeid": nodeid,
            "outcome": outcome,
            "duration": round(duration, 3),
            "error": error,
            "screenshot": screenshot,
            "category": category,
            "timestamp": datetime.now().isoformat(),
        })

    def summary(self) -> dict:
        """生成摘要统计"""
        total = len(self.results)
        passed = sum(1 for r in self.results if r["outcome"] == "passed")
        failed = sum(1 for r in self.results if r["outcome"] == "failed")
        skipped = sum(1 for r in self.results if r["outcome"] == "skipped")
        total_duration = sum(r["duration"] for r in self.results)

        return {
            "total": total,
            "passed": passed,
            "failed": failed,
            "skipped": skipped,
            "pass_rate": round(passed / total * 100, 1) if total > 0 else 0,
            "total_duration": round(total_duration, 2),
            "start_time": self.start_time.isoformat(),
        }

    def slowest(self, n: int = 10) -> list:
        """获取最慢 Top N 用例"""
        sorted_results = sorted(self.results, key=lambda r: r["duration"], reverse=True)
        return sorted_results[:n]


@pytest.fixture(scope="session")
def report_collector():
    """会话级报告收集器"""
    return ReportCollector()


# ============================================================
# Pytest Hooks - 自动收集测试结果
# ============================================================

# 全局收集器（hook 无法访问 fixture，需要模块级变量）
_global_collector = ReportCollector()


def pytest_runtest_makereport(item, call):
    """捕获每条测试的结果"""
    if call.when == "call":
        outcome = "passed" if call.excinfo is None else "failed"
        error = ""
        if call.excinfo:
            error = str(call.excinfo.value)[:500]  # 截断过长错误信息

        # 从标记中提取场景分类
        category = ""
        for marker_name in ["api", "ui", "integration", "evaluation"]:
            if item.get_closest_marker(marker_name):
                category = marker_name
                break

        _global_collector.add_result(
            nodeid=item.nodeid,
            outcome=outcome,
            duration=call.duration,
            error=error,
            category=category,
        )


def pytest_sessionfinish(session, exitstatus):
    """会话结束时保存原始结果数据"""
    reports_dir = Path(session.config.rootdir) / "tests" / "e2e" / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    date_str = datetime.now().strftime("%Y-%m-%d")

    # 保存 JSON 结果
    results_data = {
        "summary": _global_collector.summary(),
        "results": _global_collector.results,
        "slowest_top10": _global_collector.slowest(10),
    }
    json_path = reports_dir / f"{date_str}-results.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results_data, f, ensure_ascii=False, indent=2)
