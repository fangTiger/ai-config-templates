---
name: ppt-generator
description: 生成符合用友设计规范的PPT素材（SVG图+配套文案）。用于技术汇报、产品演示、项目总结等场景。触发词：PPT、汇报、演示、Presentation、幻灯片、SVG图表、技术分享、年度总结、项目汇报。遵循用友红(#e60012)点缀配色、大圆角容器、极简留白风格。
---

# PPT Generator Skill

## Purpose

生成符合企业设计规范的PPT素材，包括SVG矢量图和配套演讲文案。支持技术汇报、产品演示、项目总结等多种场景。

## When to Use

- 需要制作技术汇报PPT
- 需要生成演示文稿素材
- 需要制作项目总结/年度汇报
- 需要生成SVG格式的图表/架构图
- 提到"PPT"、"汇报"、"演示"、"presentation"等关键词

---

## Design Specification (用友标准)

### 1. 配色方案

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主背景 | #fafafa | 极浅灰底色 |
| 容器底色 | #ffffff | 白色 |
| 次级背景 | #f8f8f8 | 浅灰填充 |
| 强调色 | #e60012 | 用友红，占比<15% |
| 主标题 | #1a1a1a | 黑色 |
| 正文 | #666666 | 深灰色 |
| 辅助文字 | #999999 | 浅灰色 |
| 边框 | #e8e8e8 | 极浅灰 |
| 红色高亮背景 | #fff5f5 | 极淡红 |

### 2. 用友红使用规则

**允许使用场景**（控制总占比<15%）：
- 核心金句文字
- 演进节点标题（如"数智化"）
- 关键数据数字
- 极细边框（0.5-0.75磅）
- 强调卡片的边框

**禁止使用场景**：
- 大面积填充
- 主背景色
- 全部标题

### 3. 容器规范

```
圆角: rx="20" ry="20" (大圆角矩形)
边框: stroke-width="0.5" 或 "0.75" (极细)
投影: <feDropShadow dx="0" dy="4" stdDeviation="8" flood-opacity="0.15"/>
```

**投影滤镜模板**:
```xml
<filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
  <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#d0d0d0" flood-opacity="0.15"/>
</filter>
```

### 4. 字体家族与字号分级（强约束）

**来源**: `ppt-svg-typography.md`

- 字体家族仅允许：
  - 主标题/封面标题：`Microsoft YaHei, PingFang SC, sans-serif`
  - 通用文本：`Microsoft YaHei, sans-serif`
- 字号必须来自白名单：`60/52/46/40/32/28/26/24/22/20/19/18/17/16/15/14`
- **禁止使用 `<14` 的字号**（不再使用 10/11/12 号字）

| 层级 | 字号范围 | 典型用途 | 字重与颜色 |
|------|----------|----------|------------|
| L1 封面/封底 | 40-60 | 封面主标题、目录大标题、装饰章节号 | `bold`，主色 `#1a1a1a`，装饰号 `#e60012` + `opacity="0.15"` |
| L2 页面标题 | 28-32 | 内容页主标题、封面副标题 | 主标题 `bold #1a1a1a`，副标题 `normal #666666` |
| L3 章节/卡片标题 | 22-26 | 卡片大标题、章节标题、关键数字强调 | `bold`，`#1a1a1a` / `#e60012` |
| L4 模块标题 | 18-20 | 模块名、引擎标题、阶段说明 | 标题 `bold`，副标题 `normal` |
| L5 正文标题/标签 | 16-17 | 小节标题、标签、核心指标标题 | 标题 `bold`，正文色 `#1a1a1a` / 强调色 `#e60012` |
| L6 详细内容 | 14-15 | 列表、步骤、技术细节、注释 | 正文 `normal #666666`，辅助 `normal #999999` |

目录页推荐固定字号：标题 `46`，章节名 `32`，圆圈编号 `22`，子目录 `20`。

### 5. 文本与颜色格式约束

- 字重仅使用 `normal` / `bold`；`italic` 仅用于引用或金句（常用 `17px`）
- 颜色分层：
  - 一级标题/重点标题：`#1a1a1a`
  - 常规正文：`#666666`
  - 辅助说明/页脚/注释：`#999999`
  - 强调信息/关键指标：`#e60012`（总占比 `<15%`）
  - 白字 `#ffffff` 仅用于深色底或红色圆圈编号
- 标题（`>=32px`）可用 `letter-spacing="3"` 或 `letter-spacing="4"`；正文保持默认字距
- 居中标题统一使用 `text-anchor="middle"`，避免手工偏移
- 多行文本使用 `<tspan>` 分行，行距建议约 `1.4em`

### 6. 版式规范

- **留白**: 大面积留白，保持呼吸感
- **排版**: 横向/纵向等距阵列
- **网格**: 1排4列 或 2排2列 等工整布局
- **箭头**: 演进图使用极浅贯穿式箭头暗示方向
- **安全边距**: 建议左右≥80px，上≥60px，下≥40px
- **卡片内边距**: 建议24-32px，卡片间距建议16/24/32递进

---

## SVG Template Structure

### 基础模板 (1920×1080)

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080">
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#d0d0d0" flood-opacity="0.15"/>
    </filter>
  </defs>
  
  <!-- 背景 -->
  <rect width="1920" height="1080" fill="#fafafa"/>
  
  <!-- 页面标题 -->
  <text x="100" y="80" font-family="Microsoft YaHei, PingFang SC, sans-serif" font-size="32" font-weight="bold" fill="#1a1a1a">页面标题</text>
  <text x="100" y="122" font-family="Microsoft YaHei, sans-serif" font-size="18" fill="#999999">页面副标题</text>
  <line x1="100" y1="142" x2="250" y2="142" stroke="#e60012" stroke-width="2"/>
  
  <!-- 内容区域 -->
  <!-- ... -->
</svg>
```

### 常用组件

**白色卡片**:
```xml
<rect x="100" y="200" width="400" height="300" rx="20" ry="20" 
      fill="#ffffff" stroke="#e8e8e8" stroke-width="0.75" filter="url(#shadow)"/>
```

**红色边框强调卡片**:
```xml
<rect x="100" y="200" width="400" height="300" rx="20" ry="20" 
      fill="#ffffff" stroke="#e60012" stroke-width="0.5" filter="url(#shadow)"/>
```

**红色高亮小卡片**:
```xml
<rect x="0" y="0" width="200" height="80" rx="12" 
      fill="#fff5f5" stroke="#e60012" stroke-width="0.5"/>
```

**时间轴节点**:
```xml
<circle cx="200" cy="500" r="12" fill="#e60012"/>
<line x1="200" y1="460" x2="200" y2="488" stroke="#e8e8e8" stroke-width="2"/>
```

**箭头标记**:
```xml
<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
  <polygon points="0 0, 10 3.5, 0 7" fill="#e8e8e8"/>
</marker>
```

---

## Page Types

### 1. 封面页 (Cover)

- 主标题居中，大字号
- 副标题+核心金句
- 极简装饰线条
- 底部时间/作者信息

### 2. 时间线页 (Timeline)

- 横向时间轴
- 等距节点卡片
- 红色圆点标记关键节点
- 渐变或箭头暗示方向

### 3. 架构/流程页 (Architecture/Flow)

- 五步流程横向排列
- 箭头连接
- 分区模块（左右/上下）
- 技能网格展示

### 4. 数据展示页 (Data)

- 4列数据卡片
- 大数字+说明文字
- 核心指标红色高亮
- 能力矩阵网格

### 5. 总结展望页 (Summary)

- 里程碑回顾列表
- 成就卡片阵列
- 展望方向4列布局
- 核心金句底部居中

---

## Text Content Guidelines

### 文案原则

1. **精炼**: 短句或Bullet Points，杜绝长段落
2. **结构化**: 小标题+3行以内短描述
3. **数据化**: 用具体数字说明成果
4. **对比**: 展示前后变化/演进

### 配套文档结构

```markdown
# 标题 - PPT配套文案

## P1 封面页
**主标题**: xxx
**副标题**: xxx
**核心标语**: xxx

## P2 xxx页
### 演讲要点
- 要点1
- 要点2

### 详细内容
| 列1 | 列2 | 列3 |
|-----|-----|-----|

### 关键金句
> 金句内容
```

---

## Output Structure

生成PPT素材时，统一输出到 `ppt_assets/` 目录：

```
ppt_assets/
├── 01_cover.svg            # 封面页 (矢量图)
├── 01_cover.png            # 封面页 (超高分辨率 PNG)
├── 02_xxx.svg              # 各内容页
├── 02_xxx.png              # 对应 PNG
├── ...
├── PPT_TEXT_CONTENT.txt    # 配套文案
└── presentation.pptx       # 最终 PPTX 演示文稿
```

---

## Post-Processing Pipeline (后处理流水线)

**重要：SVG 素材生成后，必须调用 `skills/ppt-generator/tools/generate_pptx.py` 工具执行后处理，禁止现场手写转换代码。**

```
SVG 矢量图 → 4K PNG (3840×2160 @300DPI) → PPTX 演示文稿
```

### 1. SVG → PNG 转换

使用工具将 SVG 转换为 4K 高分辨率 PNG（3840×2160, 300DPI, 16:9, 白色背景）：

```bash
# 默认 4K
python3 skills/ppt-generator/tools/generate_pptx.py ppt_assets/ --png-only

# 可选 8K 超高分辨率（7680×4320, 600DPI）
python3 skills/ppt-generator/tools/generate_pptx.py ppt_assets/ --png-only --8k
```

**参数说明**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| --width | 3840 | 输出宽度（像素，4K）|
| --height | 2160 | 输出高度（像素，4K）|
| --dpi | 300 | 输出分辨率 |
| --background | white | 背景颜色 |
| --8k | - | 快捷切换到 8K（7680×4320, 600DPI）|

**系统依赖**: `rsvg-convert` (macOS: `brew install librsvg`, Ubuntu: `apt install librsvg2-bin`)

### 2. PNG → PPTX 生成

```bash
python3 skills/ppt-generator/tools/generate_pptx.py ppt_assets/ --pptx-only
```

### 3. 完整流水线（推荐）

```bash
python3 skills/ppt-generator/tools/generate_pptx.py ppt_assets/
```

### 4. Claude 自动执行规则

当使用本技能生成 SVG 素材后，**必须执行以下步骤**：

1. 确认所有 SVG 文件已生成到 `ppt_assets/`
2. **直接调用已有工具**：`python3 skills/ppt-generator/tools/generate_pptx.py ppt_assets/`
3. **禁止**现场手写 rsvg-convert 循环或 python-pptx 代码
4. 验证输出：PNG 文件数量 = SVG 文件数量，PPTX 文件已生成
5. 向用户报告最终交付物列表

---

## Quick Reference

### 必检项

- [ ] 背景色: #fafafa
- [ ] 容器圆角: rx="20" ry="20"
- [ ] 边框粗细: 0.5-0.75
- [ ] 红色占比: <15%
- [ ] 投影: 极淡悬浮感
- [ ] 字号白名单: 60/52/46/40/32/28/26/24/22/20/19/18/17/16/15/14
- [ ] 字号下限: 禁止 <14
- [ ] 字体家族: 标题 `Microsoft YaHei, PingFang SC, sans-serif`；正文 `Microsoft YaHei, sans-serif`
- [ ] 典型字号: 内容页主标题32，正文15-16，注释14-15
- [ ] 排版: 等距阵列
- [ ] 留白: 大面积呼吸感
- [ ] PNG 转换: 3840×2160, 300DPI, 白底, 16:9（可选 --8k 升级到 7680×4320）
- [ ] PPTX 生成: 16:9 宽屏，全出血布局

### 配色速查

```
背景:     #fafafa
容器:     #ffffff
填充:     #f8f8f8
强调:     #e60012
高亮背景: #fff5f5
标题:     #1a1a1a
正文:     #666666
辅助:     #999999
边框:     #e8e8e8
```

---

**Skill Status**: COMPLETE
**Line Count**: < 500 (following 500-line rule)
