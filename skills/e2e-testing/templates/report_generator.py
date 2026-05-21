# -*- coding: utf-8 -*-
"""
E2E 测试多格式报告生成器

从 pytest 运行结果（JSON）生成 Markdown 和 JUnit XML 报告。
适配器模式：统一数据结构 → 多格式渲染。

用法：
    python report_generator.py [--input results.json] [--output-dir reports/]
    python report_generator.py  # 自动查找最新的 results.json
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom.minidom import parseString


# ============================================================
# 数据模型
# ============================================================

class TestResult:
    """统一测试结果数据结构"""

    def __init__(self, raw_data: dict):
        self.summary = raw_data.get("summary", {})
        self.results = raw_data.get("results", [])
        self.slowest = raw_data.get("slowest_top10", [])
        self.environment = raw_data.get("environment", {})

    @property
    def passed(self) -> List[dict]:
        return [r for r in self.results if r["outcome"] == "passed"]

    @property
    def failed(self) -> List[dict]:
        return [r for r in self.results if r["outcome"] == "failed"]

    @property
    def skipped(self) -> List[dict]:
        return [r for r in self.results if r["outcome"] == "skipped"]

    @property
    def by_category(self) -> Dict[str, List[dict]]:
        categories: Dict[str, List[dict]] = {}
        for r in self.results:
            cat = r.get("category", "uncategorized")
            if cat not in categories:
                categories[cat] = []
            categories[cat].append(r)
        return categories


# ============================================================
# 敏感信息脱敏
# ============================================================

def sanitize_text(text: str, patterns: Optional[List[str]] = None) -> str:
    """对文本中的敏感信息脱敏"""
    if not patterns:
        patterns = ["password", "token", "secret", "key", "authorization"]
    for pattern in patterns:
        # 匹配 key=value 或 key: value 格式
        text = re.sub(
            rf'({pattern}\s*[=:]\s*)[^\s,\}}\]]+',
            rf'\1***',
            text,
            flags=re.IGNORECASE
        )
    return text


# ============================================================
# Markdown 渲染器
# ============================================================

class MarkdownRenderer:
    """生成 Markdown 格式测试报告"""

    def render(self, data: TestResult) -> str:
        sections = [
            self._header(data),
            self._summary(data),
            self._by_category(data),
            self._failures(data),
            self._slowest(data),
            self._environment(data),
        ]
        return "\n\n".join(s for s in sections if s)

    def _header(self, data: TestResult) -> str:
        timestamp = data.summary.get("start_time", datetime.now().isoformat())
        return f"# E2E 测试报告\n\n**生成时间**: {timestamp}"

    def _summary(self, data: TestResult) -> str:
        s = data.summary
        total = s.get("total", 0)
        passed = s.get("passed", 0)
        failed = s.get("failed", 0)
        skipped = s.get("skipped", 0)
        rate = s.get("pass_rate", 0)
        duration = s.get("total_duration", 0)

        # 格式化耗时
        if duration >= 60:
            time_str = f"{int(duration // 60)}m {duration % 60:.0f}s"
        else:
            time_str = f"{duration:.1f}s"

        return (
            f"## 总结\n\n"
            f"| 指标 | 值 |\n"
            f"|------|----|\n"
            f"| 总用例数 | {total} |\n"
            f"| 通过 | {passed} |\n"
            f"| 失败 | {failed} |\n"
            f"| 跳过 | {skipped} |\n"
            f"| 通过率 | {rate}% |\n"
            f"| 总耗时 | {time_str} |"
        )

    def _by_category(self, data: TestResult) -> str:
        categories = data.by_category
        if not categories or len(categories) <= 1:
            return ""

        lines = ["## 按场景统计\n"]
        lines.append("| 场景 | 通过 | 失败 | 跳过 | 通过率 |")
        lines.append("|------|------|------|------|--------|")

        for cat, results in sorted(categories.items()):
            passed = sum(1 for r in results if r["outcome"] == "passed")
            failed = sum(1 for r in results if r["outcome"] == "failed")
            skipped = sum(1 for r in results if r["outcome"] == "skipped")
            total = len(results)
            rate = round(passed / total * 100, 1) if total > 0 else 0
            lines.append(f"| {cat} | {passed} | {failed} | {skipped} | {rate}% |")

        return "\n".join(lines)

    def _failures(self, data: TestResult) -> str:
        failed = data.failed
        if not failed:
            return ""

        lines = ["## 失败详情\n"]
        for r in failed:
            nodeid = r.get("nodeid", "unknown")
            error = sanitize_text(r.get("error", "无错误信息"))
            screenshot = r.get("screenshot", "")

            lines.append(f"### {nodeid}\n")
            lines.append(f"- **错误**: {error}")
            lines.append(f"- **耗时**: {r.get('duration', 0):.2f}s")
            if screenshot:
                lines.append(f"- **截图**: {screenshot}")
            lines.append("")

        return "\n".join(lines)

    def _slowest(self, data: TestResult) -> str:
        slowest = data.slowest
        if not slowest:
            return ""

        lines = ["## 最慢 Top 10\n"]
        lines.append("| 排名 | 用例 | 耗时 |")
        lines.append("|------|------|------|")

        for i, r in enumerate(slowest, 1):
            nodeid = r.get("nodeid", "unknown")
            duration = r.get("duration", 0)
            lines.append(f"| {i} | {nodeid} | {duration:.2f}s |")

        return "\n".join(lines)

    def _environment(self, data: TestResult) -> str:
        env = data.environment
        if not env:
            return ""

        lines = ["## 环境详情\n"]
        lines.append("| 项目 | 值 |")
        lines.append("|------|----|\n")
        for key, value in env.items():
            lines.append(f"| {key} | {value} |")

        return "\n".join(lines)


# ============================================================
# JUnit XML 渲染器
# ============================================================

class JUnitRenderer:
    """生成 JUnit XML 格式报告"""

    def render(self, data: TestResult) -> str:
        s = data.summary
        testsuites = Element("testsuites")
        testsuite = SubElement(testsuites, "testsuite", {
            "name": "e2e_tests",
            "tests": str(s.get("total", 0)),
            "failures": str(s.get("failed", 0)),
            "skipped": str(s.get("skipped", 0)),
            "time": str(s.get("total_duration", 0)),
            "timestamp": s.get("start_time", ""),
        })

        for r in data.results:
            nodeid = r.get("nodeid", "unknown")
            # 解析 classname 和 name
            parts = nodeid.rsplit("::", 1)
            classname = parts[0].replace("/", ".").replace(".py", "") if len(parts) > 1 else ""
            name = parts[-1]

            testcase = SubElement(testsuite, "testcase", {
                "classname": classname,
                "name": name,
                "time": str(r.get("duration", 0)),
            })

            if r["outcome"] == "failed":
                failure = SubElement(testcase, "failure", {
                    "message": sanitize_text(r.get("error", ""))[:200],
                })
                failure.text = sanitize_text(r.get("error", ""))
            elif r["outcome"] == "skipped":
                SubElement(testcase, "skipped")

        raw_xml = tostring(testsuites, encoding="unicode")
        return parseString(raw_xml).toprettyxml(indent="  ")


# ============================================================
# 主入口
# ============================================================

def generate_reports(
    input_path: Optional[str] = None,
    output_dir: str = "tests/e2e/reports",
):
    """生成所有格式的报告"""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # 查找输入文件
    if input_path:
        json_path = Path(input_path)
    else:
        # 自动查找最新的 results.json
        json_files = sorted(output_path.glob("*-results.json"), reverse=True)
        if not json_files:
            print("未找到 results.json 文件")
            return
        json_path = json_files[0]

    with open(json_path, "r", encoding="utf-8") as f:
        raw_data = json.load(f)

    data = TestResult(raw_data)
    date_str = datetime.now().strftime("%Y-%m-%d")

    # 生成 Markdown 报告
    md_content = MarkdownRenderer().render(data)
    md_path = output_path / f"{date_str}-report.md"
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)
    print(f"Markdown 报告: {md_path}")

    # 生成 JUnit XML 报告
    xml_content = JUnitRenderer().render(data)
    xml_path = output_path / f"{date_str}-junit.xml"
    with open(xml_path, "w", encoding="utf-8") as f:
        f.write(xml_content)
    print(f"JUnit XML 报告: {xml_path}")

    # 摘要输出
    s = data.summary
    print(f"\n{'='*50}")
    print(f"总用例: {s.get('total', 0)} | 通过: {s.get('passed', 0)} | "
          f"失败: {s.get('failed', 0)} | 通过率: {s.get('pass_rate', 0)}%")
    print(f"{'='*50}")


if __name__ == "__main__":
    input_file = sys.argv[1] if len(sys.argv) > 1 else None
    output_directory = sys.argv[2] if len(sys.argv) > 2 else "tests/e2e/reports"
    generate_reports(input_file, output_directory)
