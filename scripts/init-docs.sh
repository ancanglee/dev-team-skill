#!/usr/bin/env bash
# 初始化 dev-team 的文档目录。只创建缺失的目录和 README，不覆盖已有文件。
set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  init-docs.sh [项目根目录] [--docs-dir 目录]
  init-docs.sh --help

默认在 ./docs 下建结构。已有项目建议用独立目录，避免和原文档混在一起:
  init-docs.sh . --docs-dir docs/dev-team

只创建缺失的目录和 <文档根>/README.md，已有文件不覆盖。
EOF
}

root="."
docs_dir="docs"

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --docs-dir)
      [ $# -ge 2 ] || { echo "--docs-dir 需要一个目录参数" >&2; exit 2; }
      docs_dir="$2"
      shift 2
      ;;
    -*)
      echo "未知参数: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      root="$1"
      shift
      ;;
  esac
done

[ -n "$docs_dir" ] || { echo "--docs-dir 不能为空" >&2; exit 2; }
[ -d "$root" ] || { echo "目录不存在: $root" >&2; exit 1; }

dirs=(
  01-product
  02-design/prototype
  03-architecture/api
  03-architecture/adr
  03-architecture/diagrams
  04-dev
  05-test
  06-security
  07-project/status
  07-project/reviews
  08-manual
)

for d in "${dirs[@]}"; do
  mkdir -p "$root/$docs_dir/$d"
done

if [ ! -f "$root/$docs_dir/README.md" ]; then
  cat > "$root/$docs_dir/README.md" <<'EOF'
# 项目文档

> 读者：全体角色、后续维护者
> 状态：草案
> 更新：YYYY-MM-DD

本目录由 dev-team skill 维护，结构固定。已有项目可以整体放在独立目录里（例如 docs/dev-team/），不影响原项目文档。

| 目录 | 内容 | Owner |
|---|---|---|
| 01-product | PRD、用户流程、非功能需求 | 产品经理 |
| 02-design | 交互规范、状态矩阵、视觉规范、原型 | 交互设计师 |
| 03-architecture | 架构设计、ADR、接口契约、图 | 架构师 |
| 04-dev | 开发计划、模块说明、技术债 | 架构师、开发工程师 |
| 05-test | 测试计划、用例、测试报告 | 测试工程师 |
| 06-security | 威胁模型、安全评审 | 安全工程师 |
| 07-project | 章程、计划、风险、状态、决策、盘点、评审报告 | 项目经理、评审者 |
| 08-manual | 交付手册、使用、测试、部署、排障 | 技术文档工程师 |

规则：每份文档开头写读者、状态、更新日期；流程与结构用 Mermaid 配图；待决策项标「待确认」。
EOF
fi

echo "已就绪: $root/$docs_dir"
