# 全域 agent-rules 骨架

部署方式：把本資料夾內容複製到 `~/agent-rules/`，並把專案根的 `GENERATE.md` 一起複製過去（全域 scope 的生成指令就是 `GENERATE.md` 本身，不需要另寫 `generate.md`）。

```
~/agent-rules/
  GENERATE.md     # 從本系統根目錄複製過來；全域的生成指令即此檔
  role.md         # core：我是誰、角色設定
  tone.md         # core：通用 AI 語氣與產出規範
```

> **全域 = core-only：不可放子資料夾。** 全域 output 會以 symlink 跨裝置同步，根檔指向子資料夾的相對路徑在 symlink 下不穩；按需材料（wiki/reference 等）只用在專案 scope。

填好 `role.md`、`tone.md` 後，叫 agent：

> 「依 `~/agent-rules/GENERATE.md` 生成全域設定檔。」

- 用 Claude → 產出 `~/.claude/CLAUDE.md`
- 用 Codex → 產出 `~/.codex/AGENTS.md`

全域只放非常 general 的東西，通常設定一次後極少再動。
