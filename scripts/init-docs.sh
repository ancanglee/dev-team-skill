#!/usr/bin/env bash
# 初始化 dev-team 的 docs 目录结构。只创建缺失的目录和 docs/README.md，不覆盖已有文件。
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "用法: bash scripts/init-docs.sh [项目根目录]"
  echo "默认使用当前目录。"
  exit 0
fi

root="${1:-.}"
if [ ! -d "$root" ]; then
  echo "目录不存在: $root" >&2
  exit 1
fi

dirs=(
  docs/01-product
  docs/02-design/prototype
  docs/03-architecture/api
  docs/03-architecture/adr
  docs/03-architecture/diagrams
  docs/04-dev
  docs/05-test
  docs/06-security
  docs/07-project/status
  docs/07-project/reviews
  docs/08-manual
)

for d in "${dirs[@]}"; do
  mkdir -p "$root/$d"
done

if [ ! -f "$root/docs/README.md" ]; then
  cat > "$root/docs/README.md" <<'EOF'
# 项目文档

> 读者：全体角色、后续维护者
> 状态：草案
> 更新：YYYY-MM-DD

本目录由 dev-team skill 维护，结构固定。

| 目录 | 内容 | Owner |
|---|---|---|
| 01-product | PRD、用户流程、非功能需求 | 产品经理 |
| 02-design | 交互规范、状态矩阵、视觉规范、原型 | 交互设计师 |
| 03-architecture | 架构设计、ADR、接口契约、图 | 架构师 |
| 04-dev | 开发计划、模块说明、技术债 | 架构师、开发工程师 |
| 05-test | 测试计划、用例、测试报告 | 测试工程师 |
| 06-security | 威胁模型、安全评审 | 安全工程师 |
| 07-project | 章程、计划、风险、状态、决策、评审报告 | 项目经理、评审者 |
| 08-manual | 交付手册、使用、测试、部署、排障 | 技术文档工程师 |

规则：每份文档开头写读者、状态、更新日期；流程与结构用 Mermaid 配图；待决策项标「待确认」。
EOF
fi

echo "已就绪: $root/docs"
