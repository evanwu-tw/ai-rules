# agent-rules v0.2（Phase A）最終定稿：分層邊界 + 精度（含具體錨點）

> Claude × Codex 多輪（v1–v5）收斂後的**單一權威定稿**，取代先前所有 plan 版本；實作直接依此。

## Summary

把 agent-rules 的產品邊界寫清楚：**只 compile 兩件事——Instruction（core，內嵌根檔）+ Context（on-demand → `agent-context/`）；Runtime / Memory / Workflow 三層一律不生成。** 純文件/規格層、低風險、不需 build。runtime 範例（Phase B）延後。

整合來源：採 Codex 版的敘事結構與 execpolicy 精準度；保留三道防護——**canonical-per-table（防 drift）、R2 全域影本同步、design-log 為主 + memory 非阻塞**；並**排除** Codex v4/v5 反覆塞入的個人 skills 路徑（理由見 Out of Scope）。

## Canonical 紀律（核心，先講）

每張表**只有一個權威位置**，其餘檔只放**一行指針**，嚴禁複製整表（否則就是本系統最該消滅的 drift）：
- **表 A（五層×雙平台）** → canonical 在 **README**。
- **表 B（決策/放置）** → canonical 在 **GENERATE.md §0**。

### 表 A — 五層 × 雙平台（canonical：README）
| Layer | 本系統 | Claude | Codex |
|---|---|---|---|
| Instruction（常駐） | ✅ 生成 | `CLAUDE.md` | `AGENTS.md` |
| Context（按需/路徑範圍） | ✅ 生成 `agent-context/`；path-scoping 為手動選項 | `agent-context`(on-demand) + `.claude/rules/`(glob，路徑觸發) | `agent-context`(on-demand) + nested `AGENTS.md`/`override`(目錄範圍) |
| Runtime（強制/權限/hook） | ❌ | `settings.json`(perm, hooks) | `config.toml`(hooks, sandbox, approval) + execpolicy `rules` |
| Memory（自累積學習） | ❌；長存規則回灌 source | auto memory | `[memories]` |
| Workflow（可重複能力） | ❌ | skills / commands | `.agents/skills` / plugins |

> **`@import` 不列在 Context**：Claude `@import` 是 **eager（啟動即載入）＝等同內嵌進 Instruction**，**不是 on-demand**；僅在「必須每次載入」時用。progressive disclosure 一律用一般 markdown 連結指向 `agent-context/`。

### 表 B — 決策/放置（canonical：GENERATE.md §0）
| 需求 | 放哪 | 本系統生成? |
|---|---|---|
| 建議性、每次都該遵守 | rule → `agent-rules/` 頂層 core | ✅ |
| 偶爾才讀的大份資料 | `agent-rules/<子資料夾>/` → `agent-context/` + 索引 | ✅ |
| 某路徑/資料夾專屬指令 | 手動：Claude `.claude/rules/` 或 Codex nested `AGENTS.md` | ❌ |
| 強制、可程式檢查/事件觸發 | hook / 權限（`settings.json`/`config.toml`；Codex execpolicy）| ❌ |
| 個人偏好/歷史脈絡 | memory（不取代 source；長存才回灌）| ❌ |
| 多步驟、可重複 workflow | skill / command / plugin | ❌ |

全域只放 role/tone/通用原則 + meta「強制的事用 hook」。不放 tech stack/commands/hooks/MCP/memory/大份 reference。

## 驗證事實（2026-06 查證，以最新官方為準）
- Codex 有 hooks、skills（`.agents/skills/SKILL.md`）、plugins、memories、rules。
- **同名不同物**：Codex `~/.codex/rules` = execpolicy 權限（runtime）≠ Claude `.claude/rules/` = 路徑範圍指令（context）。Codex 指令 path-scoping 用 nested `AGENTS.md`/`AGENTS.override.md`。
- Codex `project_doc_max_bytes` 預設 **32 KiB**（防呆：視為合併載入預算、各檔精簡）；Claude `CLAUDE.md` <200 行；Claude `@import` 啟動即載入（非 lazy）；Claude 剝除 block-level HTML 註解（banner≈0）。

## 具體實作步驟（錨點 old→new）

### 1. GENERATE.md
- **§0 心智模型**：在現有 3 條 bullet 後，append：(a) 分界線引言；(b) **表 B**；(c) 一行「五層完整對照見 README」；(d) reviewer 提醒「core 規則若帶『必須/絕不/每次』且可程式檢查/事件觸發 → 標 hook 候選」。不 renumber。
- **§2 根檔大小預算**：將現有句
  > 盡量 < ~200 行、且遠低於平台合併上限（…**確切數字以各自最新官方文件為準**）

  改為：Claude `CLAUDE.md` 目標 <200 行；Codex `AGENTS.md` 合併載入受 `project_doc_max_bytes`（預設 32 KiB）約束，各檔需精簡以免擠掉後續 instruction；Claude `@import` 啟動即載入、不省 context，progressive disclosure 用一般 markdown 連結。
- **§4 Codex profile**：將現有句
  > 平台特有段落：`AGENTS.md` 是純說明文件，沒有 Claude 的 skills/hooks 概念——…

  改為：Codex **有** hooks、skills、plugins、memories、execpolicy `rules`，但屬 runtime/workflow/memory 層、**不由本系統生成**；指令 path-scoping 用 nested `AGENTS.md`/`AGENTS.override.md`；**Codex `rules`（execpolicy）≠ Claude `.claude/rules/`**。
- **§4 Claude profile**：在既有 `@import` 那條後 append：`.claude/rules/`(`paths:`) 是選配的**手動** path-scoping，**不由本系統生成**；detail 檔仍用一般連結。
- **§5 banner**：append：Claude 剝除 block-level HTML 註解 → banner≈0 成本；Codex 未確認故維持精簡。
- **§6 迭代回路**：append：auto-memory/memories 是 machine-local、不取代 source；長存且可共享可追溯的規則 → 回灌 source + 記一行理由。

### 2. README.md
- 新增「設定分層」段：放 **表 A** + 分界線一句。
- 「什麼放 global/project/不要塞 markdown」：放 **表 B 的指針**（連 GENERATE.md §0），不複製表。
- 註明 `.claude/rules/` ↔ Codex nested `AGENTS.md` 是手動 path-scoping、本系統不生成。

### 3. templates/project-agent-rules/（只指針，不複製表）
- `generate.md` append 一行：hook/runtime config/skill/memory 不由本系統生成；強制性規則標 hook candidate；放置原則見 `GENERATE.vendored.md` §0。
- `behavior.md`：維持「本專案例外」定位，只加一行指針，不放表。

### 4. docs/design-log.md
- 新增 §12：本輪摘要 + 驗證事實 + 與 Codex v1–v5 比較（借敘事結構；保留 canonical-per-table、R2、execpolicy 陷阱；排除個人 skills 路徑）。
- §7：勾掉「對齊官方大小數字」；`.claude/rules/`+nested 記為「手動放置選項；generator 支援待決」。

### 5. 記錄決策（design-log 為主、memory 為輔）
- **design-log §12 一定寫**——這是跨裝置、可版本、可共享的**主記錄**（見步驟 4）。
- **memory 視環境而定**：若 agent 環境有 memory 機制 → 更新 `~/.claude/projects/.../memory/agent-rules-project.md`（分界線 + 五層模型 + 驗證事實含 execpolicy 陷阱）；**否則僅靠 design-log、不阻塞完成**。memory 是 machine-local、不跨裝置、**不進 ai-rules repo**。（本環境有 memory 機制，故兩者都做。）

### 6. R2 — 同步全域影本（實作末段；**workspace 外，需 approval**）
- `cp` ai-rules `GENERATE.md` → `~/agent-rules/source/GENERATE.md`，在 `~/agent-rules` repo commit + push。專案 `GENERATE.vendored.md` 刻意 pin、不同步。
- **此步寫在主工作目錄外（`~/agent-rules`）→ 會需要 approval。**
- **fallback**：若不便授權，**輸出 `cp` + commit + push 指令清單給使用者手動執行**，不阻塞本輪 ai-rules 變更完成（R2 可獨立補做）。

## Explicitly Out of Scope
- 不生成 `.claude/rules/`、nested `AGENTS.md`/`override`、`settings.json`、`config.toml`、hooks、MCP、Codex execpolicy。
- 不新增 `templates/runtime-examples/`（Phase B）。
- **skills 邊界用通用句、不寫個人路徑**：skill 屬 Workflow 層、本系統不生成；外部 skill source（含自訂 `SKILL.md`）不由本系統管理。**不把 Evan 個人路徑（`…/skills-source/…`）寫進中立 spec**——已驗證該路徑存在，但 macOS 大小寫不敏感掩蓋了 `Evan-projects` vs `evan-projects` 不一致，**Linux 裝置會壞**；個人路徑要記就放全域 source / memory。
- 不把 memory 當 repo source；不複製表 A/B 到多檔。
- 不改 generator 既有輸出路徑、manual 區塊、banner、agent-targeting 機制。

## 備案（fallback）
- 若 §0 加表後過大（違反「§0 精簡」）：改成 §0 只放分界線 + 表 B 連結到一個新的低位章節（如 §9），README 仍持表 A。
- 若 32 KiB 語意實作時對官方發現是「單檔」而非「合併」：把 §2 用詞從「合併預算」改「單檔上限」，其餘不變（防呆寫法兩者皆通）。

## 執行排序
1. 現在：本整合版即定稿。
2. 實作：改 §1–4 檔案 → 更新本機 memory → R2 同步全域影本 → 逐項驗證 → commit ai-rules(main) + push ~/agent-rules。

## 驗證 checklist
- [ ] 表 A 只在 README、表 B 只在 GENERATE.md §0，其餘為指針（無重複整表）
- [ ] §0 仍精簡、未 renumber；§4 Codex 舊句已替換、execpolicy 陷阱已寫
- [ ] §2 數字到位、防呆寫法、附查證時間
- [ ] global 仍 core-only；專案仍只輸出 CLAUDE.md/AGENTS.md/agent-context/
- [ ] agent-context 用一般連結非 @import；agent-targeting 仍只 core 頂層
- [ ] 無個人 skills 路徑進入 spec
- [ ] design-log §7 狀態正確、§12 已記
- [ ] R2 全域影本已同步並 push
- [ ] 本機 memory 已更新且未進 repo
- [ ] 無需 build
