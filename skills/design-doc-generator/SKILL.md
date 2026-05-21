---
name: design-doc-generator
description: 将 Markdown 设计文档转换为企业标准格式的 Word (.docx) 和 XML 文档。基于 design-template 目录下的模板，自动创建归档子目录，生成包含封面、修订记录、目录、章节内容的完整设计文档。适用于需要将 AI 生成的设计文档归档为正式企业文档的场景。
---

# Design Document Generator 设计文档生成技能

## Purpose

将 Markdown 格式的设计文档转换为企业标准格式的 Word 和 XML 文档，实现设计文档的规范化归档。

## When to Use This Skill

当需要：
- 将 Markdown 设计文档（如 `docs/*.md`）转换为 Word 格式
- 生成符合企业模板的正式设计文档
- 创建文档归档目录结构
- 生成 XML 格式的结构化设计文档
- 为设计评审准备正式文档

---

## Quick Start

### 1. 安装依赖

```bash
cd skills/design-doc-generator/tools
pip install -r requirements.txt
```

### 2. 基本使用

```bash
# 将 Markdown 设计文档转换为 Word 和 XML
python skills/design-doc-generator/tools/design_doc_generator.py docs/aicoding-scaffold-design.md

# 指定输出目录
python skills/design-doc-generator/tools/design_doc_generator.py docs/design.md --output-dir ./output

# 使用企业模板
python skills/design-doc-generator/tools/design_doc_generator.py docs/design.md \
    --template "design-template/xxx微服务详细设计参考模板-v1.6.docx"

# 指定文档信息
python skills/design-doc-generator/tools/design_doc_generator.py docs/design.md \
    --author "张三" \
    --version "2.0" \
    --doc-number "DOC-2026-001"
```

### 3. 输出结构

执行后会在 `docs/archive/<文档名>-<日期>/` 下创建：

```
docs/archive/aicoding-scaffold-design-20260227/
├── aicoding-scaffold-design.md      # 原始 Markdown（备份）
├── aicoding-scaffold-design.docx    # Word 文档
├── aicoding-scaffold-design.xml     # XML 结构化文档
└── index.json                       # 文档索引元数据
```

---

## 命令行参数

| 参数 | 缩写 | 说明 | 默认值 |
|------|------|------|--------|
| `file` | - | Markdown 源文件路径 | 必需 |
| `--output-dir` | `-o` | 输出目录 | `docs/archive/<名称>-<日期>` |
| `--template` | `-t` | Word 模板文件路径 | 无 |
| `--author` | `-a` | 文档作者 | AI Coding Team |
| `--version` | `-v` | 文档版本号 | 1.0 |
| `--doc-number` | `-n` | 文档编号 | 待分配 |
| `--format` | `-f` | 输出格式 (docx/xml/both) | both |

---

## 文档结构映射

### Markdown → Word 章节对应

工具会自动将 Markdown 的标题层级映射到 Word 文档：

| Markdown | Word |
|----------|------|
| `# 标题` | 文档标题（封面） |
| `## 章节` | Heading 1 |
| `### 子章节` | Heading 2 |
| `#### 小节` | Heading 3 |
| 表格 | Word 表格 |
| 代码块 | 等宽字体段落 |
| 列表 | 普通段落 |

### 生成的 Word 文档结构

```
1. 封面页
   - 文档标题
   - 副标题："详细设计文档"
   - 文档编号、创建日期、版本号、作者

2. 修订记录表
   - 版本、日期、修订人、修订内容

3. 目录（占位）
   - 提示用户在 Word 中生成

4. 正文章节
   - 按 Markdown 标题层级组织
   - 包含表格、代码块、段落
```

---

## XML 输出格式

生成的 XML 文档结构：

```xml
<?xml version="1.0" ?>
<DesignDocument version="1.0" encoding="UTF-8">
  <Metadata>
    <Title>AI Coding 脚手架设计文档</Title>
    <Description>...</Description>
    <Author>AI Coding Team</Author>
    <Version>1.0</Version>
    <DocNumber>DOC-2026-001</DocNumber>
    <CreatedDate>2026-02-27</CreatedDate>
    <ModifiedDate>2026-02-27</ModifiedDate>
  </Metadata>
  <Sections>
    <Section number="1" level="2">
      <Title>系统定位</Title>
      <Content>
        <Paragraph>...</Paragraph>
      </Content>
      <CodeBlocks>
        <CodeBlock language="bash">...</CodeBlock>
      </CodeBlocks>
      <Tables>
        <Table>
          <Row><Cell>列1</Cell><Cell>列2</Cell></Row>
        </Table>
      </Tables>
      <Subsections>
        <Section number="1.1" level="3">...</Section>
      </Subsections>
    </Section>
  </Sections>
</DesignDocument>
```

---

## Python API

```python
from tools.design_doc_generator import (
    generate_design_document,
    MarkdownParser,
    WordDocumentGenerator,
    XMLDocumentGenerator
)

# 方式 1: 一键生成
results = generate_design_document(
    markdown_file="docs/design.md",
    output_dir="./output",
    author="张三",
    version="2.0",
    output_format="both"
)
print(f"生成的文件: {results}")

# 方式 2: 分步操作
# 解析 Markdown
parser = MarkdownParser("docs/design.md")
doc = parser.parse()

# 生成 Word
word_gen = WordDocumentGenerator(template_path="template.docx")
word_gen.generate(doc, "output/design.docx")

# 生成 XML
xml_gen = XMLDocumentGenerator()
xml_gen.generate(doc, "output/design.xml")
```

---

## 工作流示例

### 示例 1: 归档设计文档

```bash
# 将当前设计文档归档
python skills/design-doc-generator/tools/design_doc_generator.py \
    docs/aicoding-scaffold-design.md \
    --author "开发团队" \
    --version "1.0" \
    --doc-number "AICODE-DESIGN-001"
```

输出：
```
✓ 文档生成成功！
  输出目录: docs/archive/aicoding-scaffold-design-20260227
  Word 文档: docs/archive/aicoding-scaffold-design-20260227/aicoding-scaffold-design.docx
  XML 文档: docs/archive/aicoding-scaffold-design-20260227/aicoding-scaffold-design.xml
  索引文件: docs/archive/aicoding-scaffold-design-20260227/index.json
```

### 示例 2: 使用企业模板

```bash
# 基于企业模板生成
python skills/design-doc-generator/tools/design_doc_generator.py \
    docs/design.md \
    --template "design-template/xxx微服务详细设计参考模板-v1.6.docx" \
    --output-dir "output/formal-docs"
```

### 示例 3: 批量处理

```bash
# 批量归档所有设计文档
for md in docs/*-design.md; do
    python skills/design-doc-generator/tools/design_doc_generator.py "$md"
done
```

---

## 与其他技能的配合

### 配合 document-reader 技能

```bash
# 1. 先用 document-reader 读取参考模板
python skills/document-reader/tools/doc_reader.py \
    "design-template/xxx微服务详细设计参考模板-v1.6.docx" \
    --output /tmp/template-reference.md

# 2. 参考模板编写 Markdown 设计文档
# 3. 用 design-doc-generator 生成正式文档
python skills/design-doc-generator/tools/design_doc_generator.py \
    docs/my-design.md
```

### 配合 OpenSpec 工作流

```bash
# 将 OpenSpec 设计文档归档
python skills/design-doc-generator/tools/design_doc_generator.py \
    openspec/changes/add-code-ontology-capability/design.md \
    --output-dir openspec/changes/add-code-ontology-capability/archive
```

---

## 设计文档编写规范

为获得最佳转换效果，Markdown 设计文档应遵循：

### 1. 标题层级

```markdown
# 文档标题（只有一个）

> 文档描述（可选，用引用块）

## 一级章节
### 二级章节
#### 三级章节
```

### 2. 表格格式

```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| A1  | B1  | C1  |
| A2  | B2  | C2  |
```

### 3. 代码块

```markdown
​```python
def example():
    pass
​```
```

### 4. 建议的章节结构

参考 `design-template/xxx微服务详细设计参考模板-v1.6.docx`：

1. 概述（目的、阅读对象、设计原则）
2. 整体设计（服务定义、关系、核心业务）
3. 详细设计（模型、API、数据、部署）
4. 非功能性设计（安全、可靠、性能）
5. 变更设计（如有）
6. 附录

---

## 文件结构

```
skills/design-doc-generator/
├── SKILL.md                         # 技能文档（本文件）
├── tools/
│   ├── design_doc_generator.py      # 主工具脚本
│   └── requirements.txt             # Python 依赖
└── templates/                       # 自定义模板目录（可选）
```

---

## 常见问题

### Q: 生成的 Word 文档没有目录怎么办？

A: 由于技术限制，目录需要在 Word 中手动生成。打开文档后，点击"引用 > 目录 > 自动目录"即可。

### Q: 如何保留 Markdown 中的样式？

A: 当前版本会清理大部分 Markdown 格式标记。如需保留，建议使用 `--format xml` 生成 XML 后自行处理。

### Q: 支持 Mermaid 图表吗？

A: 当前版本不支持 Mermaid 渲染。图表会作为代码块保留在文档中。

---

## 相关技能

- `document-reader` - 读取 Word/Excel 文档
- `openspec-workflow` - 规范驱动开发工作流
- `python-backend-guidelines` - Python 开发规范
