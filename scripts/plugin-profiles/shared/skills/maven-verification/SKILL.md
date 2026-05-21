---
name: maven-verification
description: Use when selecting verification commands for Java, Maven, tests, build, or documentation changes in iuap-aip-data
---

# Maven Verification

## 命令选择

| 改动类型 | 推荐验证 |
|------|------|
| 单个测试类 | `mvn -q -Dtest=ClassName test` |
| 单个生产类且有对应测试 | `mvn -q -Dtest=RelatedTest test` |
| ontology API / TTL / Agent 查询 | 运行对应 `ontology` 测试类 |
| 公共响应、异常、工具类 | 定向测试后，考虑 `mvn -q test` |
| `pom.xml` / 构建配置 | `mvn -q -DskipTests package` 或说明无法运行原因 |
| 纯 Markdown | `rg -n '[ \t]+$' <files>` 与结构检查 |
| `.codex` JSON / hook | JSON、shell、Node 脚本语法检查 |

## 证据要求

- 完成说明必须包含实际运行的命令和结果。
- 没有运行的验证必须说明原因。
- 不能用“应该通过”代替验证输出。

## 注意

- 本项目可能依赖内部 Maven 仓库或运行环境；如果构建失败，要区分代码失败、依赖不可达、环境缺失。
- 不要为了让测试通过而放宽断言或删除有效测试。
