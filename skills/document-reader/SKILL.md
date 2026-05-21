---
name: document-reader
description: 读取 Word (.docx) 和 Excel (.xlsx/.xls) 文档内容的技能。提供命令行工具和 Python API，支持提取文本、表格、标题等结构化内容，输出为 Markdown、JSON 或纯文本格式。适用于需要分析设计文档、需求规范、数据表格等 Office 文档的场景。
---

# Document Reader 文档读取技能

## Purpose

提供读取 Word 和 Excel 等 Office 文档的能力，使 AI 助手能够理解和分析二进制格式的文档内容。

## When to Use This Skill

当需要：
- 读取 `.docx` Word 文档内容
- 读取 `.xlsx` / `.xls` Excel 表格数据
- 提取设计文档、需求规范、模板文件的内容
- 分析 Excel 中的数据表格和工作表
- 将 Office 文档转换为 Markdown 或 JSON 格式

---

## Quick Start

### 1. 安装依赖

```bash
cd skills/document-reader/tools
pip install -r requirements.txt
```

### 2. 命令行使用

```bash
# 读取 Word 文档（默认输出 Markdown）
python tools/doc_reader.py document.docx

# 读取 Excel 文档
python tools/doc_reader.py data.xlsx

# 指定输出格式
python tools/doc_reader.py document.docx --format json
python tools/doc_reader.py document.docx --format text

# 读取指定工作表
python tools/doc_reader.py data.xlsx --sheet "Sheet1"

# 读取所有工作表
python tools/doc_reader.py data.xlsx --all-sheets

# 输出到文件
python tools/doc_reader.py document.docx --output output.md
```

### 3. Python API 使用

```python
from tools.doc_reader import read_document, WordReader, ExcelReader

# 简单使用
content = read_document("path/to/document.docx", output_format="markdown")
print(content)

# Word 文档详细读取
reader = WordReader("path/to/document.docx")
data = reader.read()  # 返回结构化字典
md = reader.to_markdown()  # 转换为 Markdown

# Excel 文档读取
reader = ExcelReader("path/to/data.xlsx")
data = reader.read(all_sheets=True)  # 读取所有工作表
md = reader.to_markdown(sheet_name="Sheet1")  # 指定工作表
```

---

## 支持的文件格式

| 格式 | 扩展名 | 依赖库 | 说明 |
|------|--------|--------|------|
| Word | `.docx` | python-docx | Office 2007+ 格式 |
| Excel | `.xlsx` | openpyxl | Office 2007+ 格式 |
| Excel (旧) | `.xls` | xlrd | Office 97-2003 格式 |

> **注意**: 不支持 `.doc` (旧版 Word) 格式，请先转换为 `.docx`

---

## 输出格式

### Markdown 格式（默认）

适合在对话中展示，保留结构和格式：

```markdown
# 文档名.docx

## 文档信息
- **title**: 文档标题
- **author**: 作者

## 内容

### 第一章
正文内容...

## 表格

| 列1 | 列2 | 列3 |
|-----|-----|-----|
| A1  | B1  | C1  |
```

### JSON 格式

适合程序化处理：

```json
{
  "file_name": "document.docx",
  "file_type": "docx",
  "paragraphs": [
    {"style": "Heading 1", "text": "第一章"},
    {"style": "Normal", "text": "正文内容"}
  ],
  "tables": [
    {"index": 0, "rows": [["列1", "列2"], ["A1", "B1"]]}
  ],
  "headings": [
    {"level": 1, "text": "第一章"}
  ],
  "metadata": {
    "title": "文档标题",
    "author": "作者"
  }
}
```

### 纯文本格式

最简洁的输出：

```
文件: document.docx
==================================================

第一章
正文内容...

==================================================
表格内容:

列1 | 列2 | 列3
A1 | B1 | C1
------------------------------
```

---

## API 参考

### `read_document(file_path, output_format, sheet_name, all_sheets)`

主入口函数，读取文档并返回格式化内容。

**参数:**
- `file_path` (str): 文件路径
- `output_format` (str): 输出格式，可选 `"markdown"`, `"json"`, `"text"`，默认 `"markdown"`
- `sheet_name` (str, optional): Excel 工作表名称
- `all_sheets` (bool): 是否读取所有工作表，默认 `False`

**返回:** 格式化后的字符串

### `WordReader` 类

**方法:**
- `read()` → `Dict`: 返回结构化文档数据
- `to_markdown()` → `str`: 转换为 Markdown
- `to_text()` → `str`: 转换为纯文本

### `ExcelReader` 类

**方法:**
- `read(sheet_name=None, all_sheets=False)` → `Dict`: 返回结构化数据
- `to_markdown(sheet_name=None, all_sheets=False)` → `str`: 转换为 Markdown
- `to_text(sheet_name=None, all_sheets=False)` → `str`: 转换为纯文本

---

## 工作流示例

### 示例 1: 分析设计文档

```bash
# 读取设计模板
python skills/document-reader/tools/doc_reader.py \
    design-template/xxx微服务详细设计参考模板-v1.6.docx \
    --output /tmp/design-template.md

# 然后在对话中引用输出文件进行分析
```

### 示例 2: 提取 Excel 数据

```bash
# 读取技术特性目录
python skills/document-reader/tools/doc_reader.py \
    design-template/技术特性目录.xlsx \
    --all-sheets \
    --format markdown
```

### 示例 3: 在 Python 脚本中使用

```python
import sys
sys.path.insert(0, 'skills/document-reader')
from tools.doc_reader import read_document

# 读取设计文档
content = read_document(
    "design-template/xxx微服务详细设计参考模板-v1.6.docx",
    output_format="markdown"
)

# 解析内容进行分析
for line in content.split('\n'):
    if line.startswith('##'):
        print(f"章节: {line}")
```

---

## 依赖检查

运行以下命令检查依赖安装状态：

```bash
python skills/document-reader/tools/doc_reader.py --check-deps
```

输出示例：
```
依赖检查结果:
  python-docx: ✓ 已安装
  openpyxl: ✓ 已安装
  xlrd: ✓ 已安装
```

---

## 常见问题

### Q: 为什么不支持 .doc 格式？

`.doc` 是旧版二进制格式，通常需要依赖系统级转换组件或 LibreOffice 转换。建议先将 `.doc` 转换为 `.docx` 后使用。

### Q: 读取大文件很慢怎么办？

对于大型 Excel 文件，可以：
1. 指定只读取需要的工作表 `--sheet "Sheet1"`
2. 使用 `--format text` 减少格式化开销

### Q: 如何处理合并单元格？

当前实现会将合并单元格的值复制到每个被合并的单元格中。如需特殊处理，可以使用 JSON 格式输出后自行处理。

---

## 文件结构

```
skills/document-reader/
├── SKILL.md                 # 技能文档（本文件）
└── tools/
    ├── doc_reader.py        # 主工具脚本
    └── requirements.txt     # Python 依赖
```

---

## 相关技能

- `python-backend-guidelines` - Python 开发规范
- `openspec-workflow` - 规范驱动开发工作流
