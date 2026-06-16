# agent-rules

一套讓 **Claude** 與 **Codex**（未來可擴充其他 agent）共用同一份規則來源、再各自產出符合自己平台慣例設定檔的系統。

## 核心心智模型

> **source 是唯一真相，agent 自己當 compiler。**

你只維護一份中立的 source。用 Claude 時，叫 Claude 讀 source、產出符合 Claude 慣例的 `CLAUDE.md`；用 Codex 時，叫 Codex 產出 `AGENTS.md`。生成不頻繁——通常一次，之後只在 retro 時回頭調整 source。

## 兩個 scope

| scope | source 位置 | 產出 |
|---|---|---|
| 全域 | `~/agent-rules/` | `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` |
| 專案 | `<專案>/agent-rules/` | `<專案>/CLAUDE.md`、`<專案>/AGENTS.md`、`<專案>/wiki/`、`<專案>/reference/` |

全域只放「我是誰、角色設定、通用 AI 語氣、產出規範」這類很 general 的東西；專案只放專案特有規則。**兩者不重複**——Claude 與 Codex 原生就會自動合併「全域 + 專案」的設定檔。

## source 佈局（資料夾即分類）

`agent-rules/` 底下，除了生成指令檔，**位置決定命運**：

規則只有兩條：**頂層 `.md` = 內嵌核心；任何子資料夾 = 按需材料**。

```
<scope>/agent-rules/
  generate.md            # 生成指令（全域是 GENERATE.md，專案是 generate.md）
  agent-rules.md   ┐ 頂層 .md = core
  behavior.md      ┘ → 內容「內嵌」進根檔 CLAUDE.md / AGENTS.md
  <任意資料夾>/*.md       → 各自「拆成」輸出端同名資料夾的獨立檔，根檔只放索引連結
```

- **頂層檔 = 常駐核心**：每次對話都會被讀進 context，所以保持精簡。例外：`GENERATE.md`、`generate.md`、`README.md`、`CHANGELOG.md` 是給人看的說明/工具用檔，**不**內嵌。
- **任何子資料夾 = 按需材料**：資料夾名稱**隨你定**（`wiki/`、`reference/`、`playbooks/`、`design-tokens/`… 不限），各自原樣拆成輸出端同名資料夾。平常不佔 context，根檔只留一行「需要時看 X」，agent 真的需要才去讀（progressive disclosure）。`wiki`、`reference` 只是常見例子，不是固定清單。

## 怎麼用

1. **第一次設定全域**：把 `templates/global-agent-rules/` 複製到 `~/agent-rules/`，把 `GENERATE.md` 也放進去，填好你的 role / tone，然後叫 agent「依 `~/agent-rules/GENERATE.md` 生成全域設定檔」。
2. **某個專案要規則**：把 `templates/project-agent-rules/` 複製成 `<專案>/agent-rules/`，編輯 source，然後叫 agent「依本專案 `agent-rules/generate.md` 生成」。
3. **要調整**：改 source → 重新叫 agent 生成。詳見 `GENERATE.md` 的「重生」與「迭代回路」章節。

## 檔案

- `GENERATE.md` — 系統的核心：完整生成規格、各 agent profile、擁有區機制、迭代回路。**所有行為以此為準。**
- `templates/global-agent-rules/` — 部署到 `~/agent-rules/` 的骨架。
- `templates/project-agent-rules/` — 複製進任一專案的骨架（含範例 core / wiki / reference）。
