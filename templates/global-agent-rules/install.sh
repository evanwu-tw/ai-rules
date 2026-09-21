#!/usr/bin/env bash
#
# agent-rules 全域部署器 — 一鍵部署「全域規則 + skills」：
#   1) 共用 AGENTS.md 與 Claude import 入口，透過三個 symlink 部署
#   2) skills/ 下含 SKILL.md 的資料夾（選配）symlink 到各 agent 的 skills 目錄
#
# 用法（新裝置）：
#   git clone <你的私有 agent-rules repo> ~/agent-rules
#   ~/agent-rules/install.sh
#
# 之後改了設定：在來源裝置 `git push`，其他裝置 `git pull` 即生效（symlink 自動跟隨，免重生）。
# 選項：--target-home DIRECTORY 指定安裝位置；--rules-only 不處理 skills。
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

# Optional destination for isolated installation checks; never reassign HOME.
TARGET_HOME="${HOME:?HOME is required}"
RULES_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-home)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "--target-home requires a directory" >&2; exit 2; }
      TARGET_HOME="$2"; shift 2 ;;
    --rules-only) RULES_ONLY=1; shift ;;
    --help) echo "Usage: install.sh [--target-home DIRECTORY] [--rules-only]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# Core rules are one transaction. Keep backups after success; restore on failure.
deploy_rules() (
  set -euo pipefail
  local shared="$REPO_DIR/AGENTS.md" entry="$REPO_DIR/CLAUDE.md"
  [ -f "$shared" ] && [ -s "$shared" ] && [ -f "$entry" ] && [ -s "$entry" ] || {
    echo "Missing shared AGENTS.md or CLAUDE.md; no rules deployed." >&2; exit 1;
  }
  grep -qx '@AGENTS.md' "$entry" || {
    echo "CLAUDE.md must contain an @AGENTS.md import; no rules deployed." >&2; exit 1;
  }
  local sources=("$shared" "$shared" "$entry")
  local destinations=("$TARGET_HOME/.codex/AGENTS.md" "$TARGET_HOME/.claude/AGENTS.md" "$TARGET_HOME/.claude/CLAUDE.md")
  local changed=(0 0 0) saved=(0 0 0) i same=1 backup
  for i in 0 1 2; do
    if [ -d "${destinations[$i]}" ] && [ ! -L "${destinations[$i]}" ]; then
      echo "Refusing directory at ${destinations[$i]}" >&2; exit 1
    fi
    if [ ! -L "${destinations[$i]}" ] || [ "$(readlink "${destinations[$i]}")" != "${sources[$i]}" ]; then same=0; fi
  done
  if [ "$same" -eq 1 ]; then echo "Rules already linked."; exit 0; fi
  mkdir -p "$TARGET_HOME/.codex" "$TARGET_HOME/.claude" "$TARGET_HOME/.agent-rules-backups"
  backup="$(mktemp -d "$TARGET_HOME/.agent-rules-backups/rules.XXXXXX")"
  rollback_rules() {
    local result=$? j dest
    trap - EXIT
    if [ "$result" -ne 0 ]; then
      for j in 2 1 0; do
        [ "${changed[$j]}" -eq 1 ] || continue
        dest="${destinations[$j]}"
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "${sources[$j]}" ]; then
          rm -f -- "$dest" || { echo "Cannot remove new link: $dest" >&2; continue; }
        elif [ -e "$dest" ] || [ -L "$dest" ]; then
          echo "Concurrent destination change; preserve backup: $dest" >&2; continue
        fi
        if [ "${saved[$j]}" -eq 1 ]; then mv -- "$backup/$j" "$dest" || echo "Restore failed: $dest" >&2; fi
      done
      echo "Rule install failed; prior destinations restored where safe. Backup: $backup" >&2
    fi
    exit "$result"
  }
  trap rollback_rules EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  for i in 0 1 2; do
    if [ -L "${destinations[$i]}" ] && [ "$(readlink "${destinations[$i]}")" = "${sources[$i]}" ]; then continue; fi
    if [ -e "${destinations[$i]}" ] || [ -L "${destinations[$i]}" ]; then
      mv -- "${destinations[$i]}" "$backup/$i"
      saved[$i]=1
    fi
    changed[$i]=1
    ln -s -- "${sources[$i]}" "${destinations[$i]}"
  done
  for i in 0 1 2; do
    [ -L "${destinations[$i]}" ] && [ "$(readlink "${destinations[$i]}")" = "${sources[$i]}" ]
    cmp -s "${destinations[$i]}" "${sources[$i]}"
  done
  trap - EXIT INT TERM
  echo "Rules linked. Backups: $backup"
)

deploy_rules
if [ "$RULES_ONLY" -eq 1 ]; then echo "Done. Rules only; skills unchanged."; exit 0; fi


# skills（Workflow 層資產；generator 不讀這裡）：只連含 SKILL.md 的資料夾
# Codex 官方 user 層 skills 位置是 ~/.agents/skills/（developers.openai.com/codex/skills）；
# ~/.codex/skills/ 官方文件未提及，僅作舊版相容而保留，確認不需要可自行拿掉該行。
if [ -d "$REPO_DIR/skills" ]; then
  for skill in "$REPO_DIR"/skills/*/; do
    [ -f "${skill}SKILL.md" ] || continue
    name="$(basename "$skill")"
    link "${skill%/}" "$TARGET_HOME/.claude/skills/$name"
    link "${skill%/}" "$TARGET_HOME/.agents/skills/$name"
    link "${skill%/}" "$TARGET_HOME/.codex/skills/$name"
  done
fi

echo "Done. 全域 agent 設定與 skills 已透過 ~/agent-rules 同步（git pull 即更新）。"
