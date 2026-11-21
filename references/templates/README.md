# 模板索引

复制模板到 `docs/` 下对应位置再填写，不要直接改模板本身。

| 模板 | 用于 | 产出角色 | 目标路径 |
|---|---|---|---|
| charter.md | 项目章程 | 项目经理 | docs/07-project/charter.md |
| status-report.md | 状态报告 | 项目经理 | docs/07-project/status/YYYY-MM-DD.md |
| prd.md | 产品需求文档 | 产品经理 | docs/01-product/prd.md |
| interaction-spec.md | 交互规范与状态矩阵 | 交互设计师 | docs/02-design/interaction.md |
| architecture.md | 架构设计 | 架构师 | docs/03-architecture/architecture.md |
| adr.md | 架构决策记录 | 架构师 | docs/03-architecture/adr/ADR-XXX.md |
| contract.md | 接口契约索引 | 架构师 | docs/03-architecture/contracts.md |
| development-plan.md | 开发计划与任务分工 | 架构师 | docs/04-dev/development-plan.md |
| test-plan.md | 测试计划 | 测试工程师 | docs/05-test/test-plan.md |
| test-report.md | 测试报告 | 测试工程师 | docs/05-test/report.md |
| threat-model.md | 威胁模型 | 安全工程师 | docs/06-security/threat-model.md |
| security-review.md | 安全评审报告 | 安全工程师 | docs/06-security/review.md |
| review-report.md | 评审报告 | 评审者 | docs/07-project/reviews/ |
| delivery-manual.md | 交付手册 | 技术文档工程师 | docs/08-manual/ |

## 通用规则

每份文档开头三行：

```
> 读者：<谁看>
> 状态：草案 | 已确认 | 已废弃（替代：<路径>）
> 更新：YYYY-MM-DD
```

- 流程、结构、状态、时序用 Mermaid，图配一句结论。
- 待决策项标「待确认」，列选项和建议。
- 不写空话。表格里每个单元格都要有实际内容或「不适用」。
