# agent-rules v0.2 Phase A v6 最終定稿：分層邊界 + 精度補強

> Claude × Codex 多輪收斂後的單一權威定稿，取代先前所有 plan 版本；實作直接依此。整合來源：採 Claude 版的具體錨點、canonical-per-table、R2 fallback；保留 Codex 版的版本紀律、execpolicy 精準度、memory / R2 非 blocking 風險控管；排除個人 skills 路徑進入中立 spec。

## Summary

本輪只做文件與規格層更新，目標是把 `agent-rules` 的產品邊界寫清楚：

> 只 compile 兩件事：**Instruction（core，內嵌根檔）** + **Context（on-demand → `agent-context/`）**。其餘 Runtime / Memory / Workflow 三層一律不生成。

Phase A 不生成 `.claude/rules/`、nested `AGENTS.md`、hooks、settings/config、runtime examples、memory 檔案，也不管理外部 skills source。Runtime examples 留到 Phase B。

## Canonical 紀律

每張重要表只有一個權威位置，其他檔案只放指針，避免多檔 drift：

- **表 A：五層 × 雙平台** → canonical 在 `README.md`。
- **表 B：決策 / 放置** → canonical 在 `GENERATE.md §0`。

`docs/design-log.md` 只記 narrative snapshot，不複製完整表 A / 表 B。

## 表 A — 五層 × 雙平台（canonical：README）

| Layer | 本系統 | Claude | Codex |
|---|---|---|---|
| Instruction（常駐） | 生成 | `CLAUDE.md` | `AGENTS.md` |
| Context（按需 / 路徑範圍） | 生成 `agent-context/`；path-scoping 為手動選項 | `agent-context/`、手動 `.claude/rules/` | `agent-context/`、手動 nested `AGENTS.md` / `AGENTS.override.md` |
| Runtime（強制 / 權限 / hook） | 不生成 | `settings.json`、hooks、permissions | `config.toml`、hooks、sandbox、approval、execpolicy `rules` |
| Memory（自累積學習） | 不生成；長存規則回灌 source | auto memory | Codex memories |
| Workflow（可重複能力） | 不生成 | skills / commands | skills / plugins |

註記：

- Claude `@import` 不列為 on-demand Context；它是 eager load，等同啟動即載入，只在「必須每次載入」時使用。
- Progressive disclosure 一律用一般 markdown link 指向 `agent-context/`。
- Codex `rules` 是 execpolicy / permission runtime，不是 Claude `.claude/rules/` 的對應物。
- Skills 屬 Workflow layer；各 agent 的安裝、快取、載入位置是 tool-specific，本系統不管理。

## 表 B — 決策 / 放置（canonical：GENERATE.md §0）

| 需求 | 放哪 | 本系統生成? |
|---|---|---|
| 建議性、每次都該遵守 | rule → `agent-rules/` 頂層 core | 是 |
| 偶爾才讀的大份資料 | `agent-rules/<子資料夾>/` → `agent-context/` + 索引 | 是 |
| 某路徑 / 資料夾專屬指令 | 手動：Claude `.claude/rules/` 或 Codex nested `AGENTS.md` | 否 |
| 強制、可程式檢查 / 事件觸發 | hook / 權限 / sandbox / Codex execpolicy `rules` | 否 |
| 個人偏好 / 歷史脈絡 | memory / memories；長存規則回灌 source | 否 |
| 多步驟、可重複 workflow | skill / command / plugin | 否 |

全域只放 role、tone、通用協作與工程判斷原則，以及 meta 規則「強制性的事用 hook」。  
全域不放 project tech stack、commands、hooks 實作、MCP config、memory、大份 reference。

## 驗證事實（2026-06 查證，以最新官方為準）

- Codex 有 hooks、skills、plugins、memories、rules；這些不是 `AGENTS.md` 本身的 instruction layer。
- 同名不同物：Codex `~/.codex/rules` = execpolicy 權限（Runtime），不等於 Claude `.claude/rules/` = 路徑範圍指令（Context）。
- Codex 指令 path-scoping 使用 nested `AGENTS.md` / `AGENTS.override.md`。
- Codex `project_doc_max_bytes` 預設 32 KiB；防呆寫法是視為 instruction discovery 載入預算，每份 `AGENTS.md` 都應精簡。
- Claude `CLAUDE.md` 目標 `<200 行`。
- Claude `@import` 啟動即載入，不是 lazy context。
- Claude 會剝除 block-level HTML comments，banner 在 Claude context 成本約為 0；Codex 端未確認，所以 banner 維持精簡。

## 具體實作步驟

### 1. `GENERATE.md`

- **§0 心智模型**：在現有 3 條 bullet 後 append：
  - 分界線引言。
  - 表 B（canonical placement matrix）。
  - 一行「五層完整對照見 README」。
  - reviewer 提醒：core 規則若帶「必須 / 絕不 / 每次」等強制語氣，且可被程式檢查或事件觸發驗證，標為 hook candidate。
- **§2 根檔大小預算**：將現有「確切數字以各自最新官方文件為準」改成：
  - Claude `CLAUDE.md` 目標 `<200 行`。
  - Codex `AGENTS.md` 合併載入受 `project_doc_max_bytes`（預設 32 KiB）約束；各檔需精簡，避免擠掉後續 instruction。
  - Claude `@import` 啟動即載入、不省 context；progressive disclosure 用一般 markdown link。
- **§4 Claude profile**：
  - 在 `@import` 那條後 append：`.claude/rules/`（`paths:`）是選配的手動 path-scoping，不由本系統生成；detail 檔仍用一般連結。
- **§4 Codex profile**：
  - 將「沒有 Claude 的 skills/hooks 概念」改為：Codex 有 hooks、skills、plugins、memories、execpolicy `rules`，但屬 Runtime / Workflow / Memory layer，不由本系統生成。
  - 補充：Codex path-scoping 用 nested `AGENTS.md` / `AGENTS.override.md`；Codex `rules`（execpolicy）不等於 Claude `.claude/rules/`。
- **§5 banner**：
  - append：Claude 剝除 block-level HTML comments，banner 在 Claude context 成本約為 0；Codex 未確認，故維持精簡。
- **§6 迭代回路**：
  - append：auto-memory / memories 是 machine-local，不取代 source。
  - 長存且可共享、可追溯的規則要回灌 source，並記一行理由。

### 2. `README.md`

- 新增「設定分層」段：放表 A + 分界線一句。
- 新增「什麼放 global / project / 不要塞 markdown」段：
  - 只放表 B 的指針，連到 `GENERATE.md §0`。
  - 不複製表 B。
- 註明 `.claude/rules/` 與 Codex nested `AGENTS.md` / `AGENTS.override.md` 是手動 path-scoping 選項，本系統不生成。
- 註明 skills 屬 Workflow layer，外部 skill source 不由 `ai-rules` 管理。

### 3. `templates/project-agent-rules/`

- `generate.md`：
  - append 一行：hook / runtime config / skill / memory 不由本系統生成；強制性規則若可程式檢查或事件觸發，請標為 hook candidate；放置原則見 `GENERATE.vendored.md §0`。
- `behavior.md`：
  - 維持「本專案例外」定位。
  - 只加一行指針到放置原則，不放表 B。

### 4. `docs/design-log.md`

- 新增 §12，記錄本輪 v0.2 Phase A v6：
  - 本輪摘要與分界線。
  - 驗證事實。
  - 決策：canonical-per-table、Codex `rules` ≠ Claude `.claude/rules/`、path-scoping 手動選項、Phase B 延後 runtime examples。
  - skills 邊界：Workflow layer 不由 `ai-rules` 生成或管理。
  - R2 全域影本同步為需 approval 的後續步驟。
- §7 更新：
  - 「確認官方大小數字」標為完成。
  - `.claude/rules/` / nested `AGENTS.md` 決議為「手動放置選項；generator 支援待決」。

## Memory 與 R2

### Memory

- Design log 是主記錄：跨裝置、可版本、可共享。
- Memory 只作輔助：若 agent 環境有可用 memory 機制，可更新 machine-local memory；若沒有，不阻塞本輪。
- 不新增或 commit repo memory 檔。

### R2 — 同步全域影本

實作 `ai-rules` repo 後，建議同步 `~/agent-rules/source/GENERATE.md`，避免全域生成仍使用舊規格。

- 此步驟會寫入 workspace 外的 `~/agent-rules`，執行時需使用者核准。
- 若未核准，Phase A 仍可先完成 `ai-rules` repo；R2 變成 follow-up。
- fallback：輸出 `cp`、commit、push 指令清單給使用者手動執行。
- 專案端 `GENERATE.vendored.md` 維持 pin，不自動同步。

## Explicitly Out of Scope

- 不生成 `.claude/rules/`。
- 不生成 nested `AGENTS.md` / `AGENTS.override.md`。
- 不生成 `.claude/settings.json`、`.codex/config.toml`、hooks、MCP config、Codex execpolicy `rules`。
- 不新增 `templates/runtime-examples/`。
- 不新增或 commit repo memory 檔。
- 不把 memory 更新列為 blocking step。
- Skills 邊界用通用句，不寫個人路徑：skill 屬 Workflow layer，本系統不生成；外部 skill source 不由本系統管理。個人路徑若要記，放全域 source / memory，不放中立 spec。
- 不改現有 output 路徑、manual block、banner、agent-targeting 機制。

## 備案

- 若 `GENERATE.md §0` 加表後過大：改成 §0 只放分界線 + 表 B 指針，表 B 移到新的低位章節，例如 §9；README 仍持表 A。
- 若未來官方確認 Codex 32 KiB 語意不同：只更新 §2 大小預算的 wording，保守精簡原則不變。
- 若 R2 未授權：本輪 `ai-rules` repo 可先完成，R2 留 follow-up。
- 若 memory 不可寫：只保留 design-log 記錄，不阻塞完成。

## 執行排序

1. 實作 `GENERATE.md`、`README.md`、project template、`docs/design-log.md`。
2. 檢查 canonical 表格紀律與 scope 邊界。
3. 視環境更新 machine-local memory（optional）。
4. R2 同步全域影本（需 approval；未核准則輸出手動指令）。
5. 驗證 checklist。
6. Commit `ai-rules` repo 到 `main`。

## 驗證 checklist

- [ ] 表 A 只在 README；表 B 只在 `GENERATE.md §0`；其他地方只放指針。
- [ ] `GENERATE.md §0` 仍精簡、未 renumber。
- [ ] `GENERATE.md §4` Codex 舊句已替換，execpolicy 陷阱已寫。
- [ ] `GENERATE.md §2` 數字到位，32 KiB 寫成 discovery budget / 防呆寫法。
- [ ] Global scope 仍 core-only。
- [ ] Project scope 仍只輸出 `CLAUDE.md`、`AGENTS.md`、`agent-context/`。
- [ ] `agent-context/` 使用一般 markdown link，不使用 Claude `@import`。
- [ ] `agent-targeting` 仍只允許 core 頂層。
- [ ] 無個人 skills 路徑進入系統 spec。
- [ ] `docs/design-log.md §7` 狀態正確，§12 已記。
- [ ] R2 若有核准：`~/agent-rules/source/GENERATE.md` 已同步並在 `~/agent-rules` commit / push。
- [ ] Memory 若有更新：確認未進 repo。
- [ ] 純 markdown 變更，不需 build。
