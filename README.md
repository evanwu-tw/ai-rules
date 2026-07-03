# agent-rules

一套讓 **Claude** 與 **Codex**（未來可擴充其他 agent）共用同一份規則來源、再各自產出符合自己平台慣例設定檔的系統。

## 核心心智模型

> **source 是唯一真相，agent 自己當 compiler。**

你只維護一份中立的 source。用 Claude 時，叫 Claude 讀 source、產出符合 Claude 慣例的 `CLAUDE.md`；用 Codex 時，叫 Codex 產出 `AGENTS.md`。生成不頻繁——通常一次，之後只在 retro 時回頭調整 source。

## 設定分層（五層模型）

agent 設定可分五層。**本系統只生成前兩層（Instruction + Context）**；其餘三層是各 agent 自己設定的**相鄰層、本系統不生成**。

| Layer | 本系統 | Claude | Codex |
|---|---|---|---|
| Instruction（常駐工作指令） | ✅ 生成 | `CLAUDE.md` | `AGENTS.md` |
| Context（按需 / 路徑範圍） | ✅ 生成 `agent-context/`；path-scoping 為手動選項 | `agent-context`(on-demand) + `.claude/rules/`(glob，路徑觸發) | `agent-context`(on-demand) + nested `AGENTS.md`/`override`(目錄範圍) |
| Runtime（強制 / 權限 / hook） | ❌ | `settings.json`(權限, hooks) | `hooks.json`/`config.toml`(hooks, sandbox, approval) + execpolicy `rules` |
| Memory（自累積學習） | ❌；長存規則回灌 source | auto memory | `[memories]` |
| Workflow（可重複能力） | ❌ | skills / commands | `.agents/skills` / plugins |

- **`@import` 不算 Context**：Claude `@import` 是 eager（啟動即載入）＝等同內嵌進 Instruction，不是 on-demand；progressive disclosure 一律用一般 markdown 連結指向 `agent-context/`。
- **path-scoping 是手動選項**：Claude `.claude/rules/`（可 glob）↔ Codex nested `AGENTS.md` / `AGENTS.override.md`（目錄範圍）都**不由本系統生成**，需要時自行建立。兩機制不等價（glob 可跨目錄、nested 限所在目錄），跨目錄規則的降級策略見 `GENERATE.md` §4。
- **同名不同物**：Codex `rules`（execpolicy 權限，Runtime 層）≠ Claude `.claude/rules/`（路徑範圍指令，Context 層）。
- **skills / plugins** 屬 Workflow 層；其安裝、快取、載入位置屬 **tool-specific，不由本系統生成或管理**。
- **「什麼放哪」的決策表** canonical 在 `GENERATE.md §0`（要強制 → hook；要 path-scoped → 手動 rules/nested；個人偏好 → memory…）。

## 兩個 scope

| scope | source root 位置 | 產出 |
|---|---|---|
| 全域 | `~/agent-rules/source/` | `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`（**僅根檔，core-only**） |
| 專案 | `<專案>/agent-rules/` | `<專案>/CLAUDE.md`、`<專案>/AGENTS.md`；細節檔 → `<專案>/agent-context/`（avoid 覆蓋 repo 既有資料夾） |

全域只放「我是誰、角色設定、通用 AI 語氣、產出規範」這類很 general 的東西；專案只放專案特有規則。**兩者不重複**——Claude 與 Codex 原生就會自動合併「全域 + 專案」的設定檔。

> **全域 source root 是 `~/agent-rules/source/`**：`~/agent-rules/` 是跨裝置部署 repo，第一層放生成 output（`CLAUDE.md`/`AGENTS.md`）+ `install.sh`，source 收進 `source/`。generator 只讀 `source/`，避免把 output 當 core 內嵌污染。詳見「跨裝置部署」。
> **全域 = core-only**：全域 output 走 symlink 跨裝置同步，故 `source/` 內不放子資料夾。按需材料只用在專案 scope。

## source 佈局（資料夾即分類）

`agent-rules/` 底下，除了生成指令檔，**位置決定命運**：

規則只有兩條：**頂層 `.md` = 內嵌核心；任何子資料夾 = 按需材料**。

```
<scope>/agent-rules/
  generate.md            # 生成指令（全域是 GENERATE.md，專案是 generate.md）
  agent-rules.md   ┐ 頂層 .md = core
  behavior.md      ┘ → 內容「內嵌」進根檔 CLAUDE.md / AGENTS.md
  <任意資料夾>/*.md       → 拆成 <專案>/agent-context/<同名>/ 的獨立檔，根檔只放索引連結（僅專案 scope）
```

- **頂層檔 = 常駐核心**：每次對話都會被讀進 context，所以保持精簡。例外：`GENERATE.md`、`generate.md`、`README.md`、`CHANGELOG.md`、`GENERATE.vendored.md`（及任何 `*.vendored.md`）是說明/指令/vendored 規格，**不**內嵌。建議 core 用數字前綴（`00-`、`10-`…）固定內嵌順序，並控制根檔大小（見 `GENERATE.md` §2 大小預算）。
- **任何子資料夾 = 按需材料**（**僅專案 scope**）：資料夾名稱**隨你定**（`wiki/`、`reference/`、`playbooks/`… 不限），各檔拆成 `<專案>/agent-context/<同名>/` 的獨立檔（收進 namespace，避免覆蓋 repo 既有的 `wiki/`、`docs/`）。平常不佔 context，根檔只留一行「需要時看 X」，agent 真的需要才去讀（progressive disclosure）。全域 scope 不放子資料夾。

## 怎麼用

1. **第一次設定全域**：把 `templates/global-agent-rules/` 複製到 `~/agent-rules/`，把 `GENERATE.md` 放進 `~/agent-rules/source/`，填好 `source/role.md`、`source/tone.md`，叫 agent「依 `~/agent-rules/source/GENERATE.md` 生成全域設定檔」，再跑 `~/agent-rules/install.sh` 建 symlink。詳見「跨裝置部署」。
2. **某個專案要規則**：把 `templates/project-agent-rules/` 複製成 `<專案>/agent-rules/`，並把 base 規格 `GENERATE.md` vendor 一份進去（`agent-rules/GENERATE.vendored.md`，檔頭註明來源 commit——因為 `ai-rules` 是 private repo，vendored 才能離線/無 auth 使用）。編輯 source，然後叫 agent「依本專案 `agent-rules/generate.md` 生成」。
3. **要調整**：改 source → 重新叫 agent 生成。詳見 `GENERATE.md` 的「重生」與「迭代回路」章節。

## 跨裝置部署

全域 output 跨裝置完全一致，所以**不該每台重生**——把 `~/agent-rules` 設成**私有 git repo**，output commit 進去、用 symlink 同步：

- **佈局**：`~/agent-rules/` 第一層放 `CLAUDE.md`、`AGENTS.md`（生成 output）+ `install.sh`；source 在 `source/`（`GENERATE.md`、`role.md`、`tone.md`）；另可放 `skills/`（選配，Workflow 層資產，generator 不讀）。
- **install.sh**：把第一層 output symlink 到 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`；若有 `skills/`，把含 `SKILL.md` 的資料夾 symlink 到兩個 agent 的 skills 目錄（idempotent，遇實體檔先備份）。
- **新裝置一鍵**：`git clone git@github.com:<you>/agent-rules.git ~/agent-rules && ~/agent-rules/install.sh`，**不需重生**。
- **日常同步**：來源裝置改 source → 重生（指向 `source/GENERATE.md`）→ `git push`；其他裝置 `git pull` 即生效（symlink 自動跟隨）。
- **這個系統 repo（`ai-rules`）與個人全域 repo（`~/agent-rules`）分開**：前者放範本/規格、不含個資；後者含 role/tone、必須私有。

> **專案 scope 不需這套**：專案的 `CLAUDE.md`/`AGENTS.md`/`agent-context/` 直接 commit 進各專案自己的 repo，新裝置 clone 專案時一起帶過來，不需重生。

## 檔案

- `GENERATE.md` — 系統的核心：完整生成規格、各 agent profile、擁有區機制、迭代回路。**所有行為以此為準。**
- `templates/global-agent-rules/` — 部署到 `~/agent-rules/` 的骨架。
- `templates/project-agent-rules/` — 複製進任一專案的骨架（含範例 core / wiki / reference）。
