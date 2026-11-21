#!/usr/bin/env bash
# 安装 dev-team skill。默认装到用户级 ~/.claude，也可用 --project 装到某个项目。
set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  install.sh                     装到用户级 ~/.claude，所有项目可用
  install.sh --project [目录]    装到 <目录>/.claude，默认当前目录
  install.sh --help              显示帮助

重复执行是安全的，已安装的项会跳过。
EOF
}

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
mode="user"
proj=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project|-p)
      mode="project"
      shift
      if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
        proj="$1"
        shift
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[ -f "$SKILL_DIR/SKILL.md" ] || {
  echo "找不到 SKILL.md，脚本位置不对: $SKILL_DIR" >&2
  exit 1
}

if [ "$mode" = "user" ]; then
  [ -n "${HOME:-}" ] || { echo "HOME 未设置" >&2; exit 1; }
  base="$HOME/.claude"
else
  proj="${proj:-.}"
  [ -d "$proj" ] || { echo "项目目录不存在: $proj" >&2; exit 1; }
  base="$(cd "$proj" && pwd)/.claude"
fi

mkdir -p "$base/skills" "$base/agents"

# 把软链接解析成绝对路径；目标不存在时原样返回。
# 解析软链接，跟随多层链接；目标不存在时返回最后一跳的路径。
read_link_abs() {
  local p="$1" target hops=0
  while [ -L "$p" ] && [ "$hops" -lt 20 ]; do
    target="$(readlink "$p")"
    case "$target" in
      /*) p="$target" ;;
      *) p="$(dirname "$p")/$target" ;;
    esac
    hops=$((hops + 1))
  done
  if [ -e "$p" ]; then
    ( cd "$(dirname "$p")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename "$p")" )
  else
    printf '%s\n' "$p"
  fi
}

conflicts=0

# 技能本体
link="$base/skills/dev-team"
if [ -L "$link" ]; then
  if [ "$(read_link_abs "$link")" = "$SKILL_DIR" ]; then
    echo "技能: 已安装，跳过"
  else
    echo "技能: 冲突，$link 已指向 $(readlink "$link")，未修改" >&2
    conflicts=$((conflicts + 1))
  fi
elif [ -e "$link" ]; then
  echo "技能: 冲突，$link 已存在且不是软链接，未修改" >&2
  conflicts=$((conflicts + 1))
else
  ln -s "$SKILL_DIR" "$link"
  echo "技能: 已链接 $link -> $SKILL_DIR"
fi

# 九个角色 agent
added=0
skipped=0
for src in "$SKILL_DIR"/agents/*.md; do
  name="$(basename "$src")"
  dest="$base/agents/$name"
  if [ -L "$dest" ]; then
    if [ "$(read_link_abs "$dest")" = "$src" ]; then
      skipped=$((skipped + 1))
      continue
    fi
    echo "角色: 冲突，$dest 已指向 $(readlink "$dest")，未修改" >&2
    conflicts=$((conflicts + 1))
    continue
  fi
  if [ -e "$dest" ]; then
    echo "角色: 冲突，$dest 已存在且不是软链接，未修改" >&2
    conflicts=$((conflicts + 1))
    continue
  fi
  ln -s "$src" "$dest"
  added=$((added + 1))
done

echo "角色: 新增 ${added}，已存在 $skipped"
if [ "$conflicts" -gt 0 ]; then
  echo "安装完成，有 $conflicts 项冲突未处理，请检查上面的提示。" >&2
else
  echo "安装完成。重开会话后输入 /dev-team，或说「用研发团队做……」。"
fi
