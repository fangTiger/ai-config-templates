# Spec: code-ontology

## Purpose

提供代码本体构建能力，将源代码解析为描述文档，通过 LLM 增强和 Pipeline 流程构建知识图谱，支持代码-需求追溯和语义查询。

## Requirements
### Requirement: Document Generation from Code

系统 SHALL 将解析的代码元素转换为带 YAML frontmatter 的 Markdown 描述文档，用于本体构建服务的输入。

#### Scenario: 生成带 frontmatter 的文档
- **GIVEN** 一个 CodeElement
- **WHEN** 调用 DocumentGenerator.generate_document()
- **THEN** 返回带 YAML frontmatter 的 Markdown 文档
- **AND** frontmatter 包含 doc_type, name, full_name, file_path, line_number, language, package, element_id

### Requirement: Ontology Service Integration

系统 SHALL 使用完整 Pipeline 构建本体，通过 DocumentKGPipeline 执行 5 阶段构建流程。

#### Scenario: 构建代码本体
- **GIVEN** 项目代码
- **WHEN** 执行构建命令
- **THEN** 先生成文档并保存
- **THEN** 调用 DocumentKGPipeline 构建本体
- **THEN** 导入 Neo4j

### Requirement: Ontology Project API (External)

ontology 项目 SHALL 提供代码本体构建 API，接收文档和 prompt 作为输入。

> **Note**: 此需求在 ontology 项目中实现。

#### Scenario: 从文档构建本体
- **WHEN** CodeOntologyBuilder.build_from_documents() 被调用
- **WITH** 代码描述文档列表、构建 prompt、域名、可选的模式 TTL
- **THEN** 使用 LLMPluginManager 从文档提取实体
- **AND** 使用 LLMPluginManager 从文档提取关系
- **AND** 根据提取结果生成 TTL
- **AND** 可选地导入 Neo4j
- **AND** 返回生成的 TTL 内容

### Requirement: Prompt Template Management

系统 SHALL 提供可配置的 prompt 模板，用于指导 LLM 进行本体构建。

#### Scenario: 使用默认 prompt 模板
- **WHEN** build_code_ontology() 被调用且未指定 prompt
- **THEN** 系统使用默认的代码本体构建 prompt 模板
- **AND** 模板包含本体模式定义（类型、关系）
- **AND** 模板包含输出格式要求

#### Scenario: 使用自定义 prompt
- **WHEN** build_code_ontology() 被调用且指定了自定义 prompt
- **THEN** 系统使用用户提供的 prompt
- **AND** 将文档内容插入 prompt 的指定位置

### Requirement: LLM 增强文档生成

系统 SHALL 提供 LLM 增强的文档生成能力，为代码元素生成业务意图描述。

#### Scenario: 生成类描述
- **GIVEN** 一个 CodeElement 类型为 class
- **WHEN** 调用 NLPGenerator.generate_class_description()
- **THEN** 返回包含业务意图的自然语言描述
- **AND** 描述包含类的职责、依赖关系、使用场景

#### Scenario: 生成方法描述
- **GIVEN** 一个 CodeElement 类型为 method
- **WHEN** 调用 NLPGenerator.generate_method_description()
- **THEN** 返回包含业务意图的自然语言描述
- **AND** 描述包含方法的功能、参数说明、返回值说明

### Requirement: 文档落盘

系统 SHALL 将生成的文档保存到磁盘，支持增量构建和审查。

#### Scenario: 保存文档
- **GIVEN** 一组生成的文档
- **WHEN** 调用 DocumentWriter.save()
- **THEN** 文档保存到 `docs/ontology/code_docs/<project>/<build_id>/`
- **AND** 返回构建目录路径

#### Scenario: 生成构建 ID
- **GIVEN** 未指定 build_id
- **WHEN** 调用 DocumentWriter.save()
- **THEN** 自动生成时间戳 + 短哈希格式的 build_id

### Requirement: 稳定实体 ID

系统 SHALL 为每个代码元素生成稳定的实体 ID，格式为 `code:<language>:<project>:<full_name>`。

#### Scenario: 生成实体 ID
- **GIVEN** 一个 CodeElement
- **WHEN** 生成文档
- **THEN** frontmatter 包含 `element_id` 字段
- **AND** 格式为 `code:<language>:<project>:<full_name>`

### Requirement: Pipeline 集成

系统 SHALL 使用 ontology 项目的 DocumentKGPipeline 进行本体构建。

#### Scenario: 完整 Pipeline 构建
- **GIVEN** 文档目录路径
- **WHEN** 调用 OntologyClient.build_and_import_code_ontology()
- **THEN** 执行完整的 5 阶段 Pipeline
- **AND** 结果导入 Neo4j 数据库

### Requirement: SDD 语义链接

系统 SHALL 支持基于语义匹配的需求-代码链接。

#### Scenario: 语义匹配链接
- **GIVEN** 需求文档和代码元素
- **WHEN** 执行语义匹配
- **THEN** 返回链接候选列表
- **AND** 每个候选包含置信度分数

