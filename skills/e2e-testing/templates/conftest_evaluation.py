# -*- coding: utf-8 -*-
"""
AI/模型评测场景 conftest.py

提供 fixtures：
- model_client: 封装模型 API 调用
- load_dataset: 从 CSV/JSON 加载黄金数据集
- extract_answer: 从模型输出提取结构化答案
- EvaluationMetrics: 收集和统计评测指标
"""

import csv
import json
import re
import time
import pytest
import requests
from pathlib import Path
from typing import Tuple, List, Dict, Any, Optional
from dataclasses import dataclass, field


# ============================================================
# 模型客户端
# ============================================================

class ModelClient:
    """封装模型 API 调用

    支持重试、超时、错误处理、Token 计数
    """

    def __init__(self, api_url: str, model_name: str, timeout: int = 180, retries: int = 2):
        self.api_url = api_url
        self.model_name = model_name
        self.timeout = timeout
        self.retries = retries
        self.total_tokens = 0

    def call(self, prompt: str, max_tokens: int = 4096) -> Tuple[str, float]:
        """调用模型 API

        Returns:
            (response_text, latency_seconds)
        """
        payload = {
            "messages": [{"content": prompt, "role": "user"}],
            "model": self.model_name,
            "stream": False,
            "max_tokens": max_tokens,
        }
        headers = {"Content-Type": "application/json"}

        last_error = None
        for attempt in range(self.retries + 1):
            try:
                start = time.time()
                resp = requests.post(
                    self.api_url, json=payload, headers=headers, timeout=self.timeout
                )
                latency = time.time() - start

                if resp.status_code == 200:
                    data = resp.json()
                    content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                    # 统计 Token
                    usage = data.get("usage", {})
                    self.total_tokens += usage.get("total_tokens", 0)
                    return content, latency
                else:
                    last_error = f"HTTP {resp.status_code}: {resp.text[:200]}"
            except requests.exceptions.Timeout:
                last_error = f"请求超时 ({self.timeout}s)"
            except Exception as e:
                last_error = str(e)

        return f"[ERROR] {last_error}", 0.0


@pytest.fixture(scope="session")
def model_clients(e2e_config) -> Dict[str, ModelClient]:
    """创建所有待评测模型的客户端"""
    eval_config = e2e_config.get("evaluation", {})
    api_url = eval_config.get("model_api_url", "")
    models = eval_config.get("models", [])
    timeout = eval_config.get("request_timeout", 180)

    if not api_url or api_url.startswith("$"):
        pytest.skip("未配置模型 API URL，跳过评测")
    if not models:
        pytest.skip("未配置评测模型列表，跳过评测")

    return {
        model: ModelClient(api_url, model, timeout=timeout)
        for model in models
    }


@pytest.fixture
def model_client(model_clients, request) -> ModelClient:
    """获取单个模型客户端（通过 parametrize 选择模型）"""
    model_name = getattr(request, "param", None)
    if model_name and model_name in model_clients:
        return model_clients[model_name]
    # 默认返回第一个模型
    return next(iter(model_clients.values()))


# ============================================================
# 数据集加载
# ============================================================

def load_dataset(filename: str, dataset_dir: str = "tests/e2e/evaluation/datasets") -> List[Dict]:
    """加载黄金测试数据集

    支持 CSV 和 JSON 格式。

    用法（作为 parametrize 参数）：
        @pytest.mark.parametrize("case", load_dataset("test_cases.csv"))
        def test_model(model_client, case):
            response, _ = model_client.call(case["prompt"])
            assert extract_answer(response) == case["expected"]
    """
    path = Path(dataset_dir) / filename

    if not path.exists():
        pytest.skip(f"数据集文件未找到: {path}")

    if path.suffix == ".csv":
        with open(path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            return list(reader)
    elif path.suffix == ".json":
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, list) else [data]
    else:
        raise ValueError(f"不支持的数据集格式: {path.suffix}（支持 .csv 和 .json）")


# ============================================================
# 答案提取
# ============================================================

def extract_answer(response: str, model_name: str = "") -> str:
    """从模型输出中提取结构化答案

    支持多种输出格式：
    1. <<<answer>>> 标记格式
    2. </think>content 格式（思考链模型）
    3. 纯文本（直接返回）
    """
    # 格式 1: <<<answer>>> 标记
    match = re.search(r'<<<(.+?)>>>', response, re.DOTALL)
    if match:
        return match.group(1).strip()

    # 格式 2: </think> 分隔（RL 模型常用）
    if '</think>' in response:
        parts = response.split('</think>', 1)
        if len(parts) > 1:
            return parts[1].strip()

    # 格式 3: 直接返回清理后的文本
    return response.strip()


# ============================================================
# 评测指标
# ============================================================

@dataclass
class EvaluationMetrics:
    """评测指标收集器

    用法：
        metrics = EvaluationMetrics()
        for case in test_cases:
            response, latency = model_client.call(case["prompt"])
            answer = extract_answer(response)
            is_correct = answer == case["expected"]
            metrics.record(case.get("category", "default"), is_correct, latency)

        report = metrics.summary()
    """

    records: List[Dict] = field(default_factory=list)

    def record(self, category: str, correct: bool, latency: float,
               tokens: int = 0, extra: Optional[Dict] = None):
        """记录单条评测结果"""
        self.records.append({
            "category": category,
            "correct": correct,
            "latency": latency,
            "tokens": tokens,
            **(extra or {}),
        })

    def summary(self) -> Dict[str, Any]:
        """生成评测摘要"""
        total = len(self.records)
        correct = sum(1 for r in self.records if r["correct"])
        latencies = [r["latency"] for r in self.records if r["latency"] > 0]

        # 按类别分组统计
        categories = {}
        for r in self.records:
            cat = r["category"]
            if cat not in categories:
                categories[cat] = {"total": 0, "correct": 0, "latencies": []}
            categories[cat]["total"] += 1
            if r["correct"]:
                categories[cat]["correct"] += 1
            if r["latency"] > 0:
                categories[cat]["latencies"].append(r["latency"])

        category_stats = {}
        for cat, data in categories.items():
            cat_total = data["total"]
            cat_correct = data["correct"]
            cat_latencies = data["latencies"]
            category_stats[cat] = {
                "total": cat_total,
                "correct": cat_correct,
                "accuracy": round(cat_correct / cat_total * 100, 1) if cat_total > 0 else 0,
                "avg_latency": round(sum(cat_latencies) / len(cat_latencies), 2) if cat_latencies else 0,
            }

        return {
            "total": total,
            "correct": correct,
            "accuracy": round(correct / total * 100, 1) if total > 0 else 0,
            "avg_latency": round(sum(latencies) / len(latencies), 2) if latencies else 0,
            "total_tokens": sum(r.get("tokens", 0) for r in self.records),
            "categories": category_stats,
        }


@pytest.fixture
def eval_metrics():
    """评测指标收集器 fixture"""
    return EvaluationMetrics()
