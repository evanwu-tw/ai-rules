#!/usr/bin/env bash
#
# agent-rules 全域部署器 — 一鍵部署「全域規則 + skills」：
#   1) repo 第一層的生成 output symlink 到各 agent 的設定位置
#   2) skills/ 下含 SKILL.md 的資料夾（選配）symlink 到各 agent 的 skills 目錄
#
# 用法（新裝置）：
#   git clone <你的私有 agent-rules repo> ~/agent-rules
#   ~/agent-rules/install.sh
#
# 之後改了設定：在來源裝置 `git push`，其他裝置 `git pull` 即生效（symlink 自動跟隨，免重生）。
# 本腳本可重複執行（idempotent）；遇到擋路的實體檔會先備份再建 symlink。

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    echo "skip: 來源不存在 $src（尚未生成 output？）" >&2
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  # 目標是擋路的實體檔（非 symlink）→ 先備份
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local bak="$dest.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$bak"
    echo "backed up existing file → $bak"
  fi
  ln -sfn "$src" "$dest"
  echo "linked $dest -> $src"
}

link "$REPO_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$REPO_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"

# skills（Workflow 層資產；generator 不讀這裡）：只連含 SKILL.md 的資料夾
if [ -d "$REPO_DIR/skills" ]; then
  for skill in "$REPO_DIR"/skills/*/; do
    [ -f "${skill}SKILL.md" ] || continue
    name="$(basename "$skill")"
    link "${skill%/}" "$HOME/.claude/skills/$name"
    link "${skill%/}" "$HOME/.codex/skills/$name"
  done
fi

echo "Done. 全域 agent 設定與 skills 已透過 ~/agent-rules 同步（git pull 即更新）。"
