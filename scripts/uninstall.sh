#!/usr/bin/env bash
# 卸载 dev-team skill。只删除指向本 skill 的软链接，不碰其他文件。
set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  uninstall.sh                     从用户级 ~/.claude 卸载
  uninstall.sh --project [目录]    从 <目录>/.claude 卸载，默认当前目录
  uninstall.sh --help              显示帮助

只删除指向本 skill 的软链接。项目里已生成的 docs/ 不受影响。
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

if [ "$mode" = "user" ]; then
  [ -n "${HOME:-}" ] || { echo "HOME 未设置" >&2; exit 1; }
  base="$HOME/.claude"
else
  proj="${proj:-.}"
  [ -d "$proj" ] || { echo "项目目录不存在: $proj" >&2; exit 1; }
  base="$(cd "$proj" && pwd)/.claude"
fi

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

kept=0

link="$base/skills/dev-team"
if [ -L "$link" ]; then
  if [ "$(read_link_abs "$link")" = "$SKILL_DIR" ]; then
    rm "$link"
    echo "技能: 已删除 $link"
  else
    echo "技能: 跳过，$link 指向 $(readlink "$link")，不是本 skill" >&2
    kept=$((kept + 1))
  fi
elif [ -e "$link" ]; then
  echo "技能: 跳过，$link 不是软链接，未删除" >&2
  kept=$((kept + 1))
else
  echo "技能: 未安装，跳过"
fi

removed=0
for src in "$SKILL_DIR"/agents/*.md; do
  name="$(basename "$src")"
  dest="$base/agents/$name"
  if [ -L "$dest" ]; then
    if [ "$(read_link_abs "$dest")" = "$src" ]; then
      rm "$dest"
      removed=$((removed + 1))
    else
      echo "角色: 跳过，$dest 指向 $(readlink "$dest")" >&2
      kept=$((kept + 1))
    fi
  elif [ -e "$dest" ]; then
    echo "角色: 跳过，$dest 不是软链接，未删除" >&2
    kept=$((kept + 1))
  fi
done

echo "角色: 删除 ${removed}，保留 $kept"
echo "卸载完成。项目里的 docs/ 和代码不受影响。"
