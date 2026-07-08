# Design Log — agent-rules

本檔記錄 agent-rules 系統的設計決策與建置歷程。
首次整理：2026-06-16。

---

## 1. 目標

建立一套 **Claude 與 Codex（未來可擴充其他 agent）共用的規則系統**：維護單一份中立的規則來源（source），再讓各 agent 依自己平台慣例產出專屬設定檔（`CLAUDE.md` / `AGENTS.md`）。複雜專案允許用多個檔案組合。

---

## 2. 核心心智模型

> **source 是唯一真相，agent 自己當 compiler。**

不寫 build 腳本、不做 LLM 潤色管線。用 Claude 時就叫 Claude 讀 source、產出符合 Claude 慣例的 `CLAUDE.md`；用 Codex 時就叫 Codex 產出 `AGENTS.md`。生成不頻繁——通常一次，之後只在 retro 時回頭調整 source。

---

## 3. 關鍵設計決策（含理由）

逐條記錄定案與當初的取捨：

| # | 決策 | 理由 |
|---|---|---|
| 1 | 兩邊輸出**結構相同、語氣/格式不同**；source 預設 agent 中立、全部共用 | 差異主要在平台慣例，不在內容；不想為了少數差異到處標註「這段給誰」 |
| 2 | 轉換方式＝**agent 自己當 compiler**（非腳本、非 LLM 管線） | 生成不頻繁、各 agent 最懂自己平台慣例；簡單、零依賴 |
| 3 | 生成指令存成**跨平台中立文件 `GENERATE.md`** | 不綁特定工具、兩邊通用、唯一真相好維護 |
| 4 | 兩個 scope：**全域**只放 general（角色、語氣、產出規範）；**專案**只放專案特有 | 不重複——Claude/Codex 原生會自動合併「全域 + 專案」設定檔 |
| 5 | **資料夾即分類**（layout B，扁平）：頂層 `.md` = 內嵌核心；任何子資料夾 = 按需材料 | 根檔每次都載入 context 要精簡；大份材料拆檔 + 索引（progressive disclosure）。子資料夾名稱不限，`wiki`/`reference` 只是例子 |
| 6 | GENERATE.md 內含**簡短的 Claude / Codex profile** | 只抓真差異（輸出路徑、原生合併、平台特有段落），確保跨次一致 |
| 7 | 全域一份 `GENERATE.md` 為 base；每專案各一份 `generate.md` 引用全域並可覆寫 | 全域規則集中維護；專案保留彈性 |
| 8 | **擁有區 vs 手動區**防 drift（借鑑 agentic-stack 的檔案所有權概念） | 重生覆蓋擁有區、保留手動區，比整檔覆蓋更穩 |
| 9 | **迭代回路**：允許手改生成物，但手改擁有區要**反吐回 source + 記一行理由** | source 永遠保持最新真相，演化可追溯 |
| 10 | 命名用 **`agent-rules`** | 用 agent（非 ai）較精準、與 `AGENTS.md` 生態一致；rules 好溝通 |

### 參考過的外部專案

- **[agentic-stack](https://github.com/codejunkie99/agentic-stack)** — 同類但重得多（記憶分層、夜間自學、Python backend）。借鑑了「adapter/per-harness profile」「檔案所有權 skeleton-owned vs user-owned」「progressive disclosure」「決策附 rationale」。刻意**不**借記憶分層、自學飛輪、daemon——保持輕量。

---

## 4. 架構總覽

### 兩個 scope

| scope | source | 產出 |
|---|---|---|
| 全域 | `~/agent-rules/` | `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`（core-only） |
| 專案 | `<專案>/agent-rules/` | `<專案>/CLAUDE.md`、`AGENTS.md`；細節檔 → `<專案>/agent-context/…` |

### source 佈局 → 產出

```
<scope>/agent-rules/
  generate.md            # 生成指令（全域是 GENERATE.md，專案是 generate.md）
  agent-rules.md   ┐ 頂層 .md = core → 內嵌進根檔
  behavior.md      ┘
  <子資料夾>/*.md         → 拆成 agent-context/<同名>/ + 根檔索引連結（僅專案）
        │ 生成
        ▼
  CLAUDE.md / AGENTS.md          # core 內嵌 + 指向 agent-context 的索引
  agent-context/<子資料夾>/*.md   # 按需載入（namespace，避免覆蓋 repo 既有資料夾）
```

**保留檔名例外**（不視為 core、不內嵌）：`GENERATE.md`、`generate.md`、`README.md`、`CHANGELOG.md`。
**全域 = core-only**（不放子資料夾）；**專案細節檔收進 `agent-context/`**（不寫專案根）。

### 防 drift 機制（Codex review 後簡化）

- 生成檔頂部加 banner（標明由 source 生成、優先改 source）。
- `<!-- agent-rules:manual:start -->` … `<!-- :end -->` 之間＝手動區，重生**原樣保留**；其餘＝擁有區，重生**整段覆蓋、不做差異偵測**。
- 想長存的改動 → **使用者主動提出**時回灌 source + 記理由；不要求 agent 自動偵測手改（非確定性生成下不可靠，見 §8）。

完整規格見 [GENERATE.md](../GENERATE.md)。

---

## 5. 跨裝置設計

- 同步機制：**git 私有 repo**（非 iCloud——要版本歷史/diff，且 iCloud 會 evict 檔案、易衝突、限 Mac）。
- 全裝置規則**一致**（不需裝置差異）→ 全域 output 可進 repo + **symlink** 到 `~/.claude/`、`~/.codex/`，`git pull` 即生效、免重生。
- 約束：因 symlink，**全域 scope 維持 core-only**（不放子資料夾，避免相對路徑在 symlink 下不穩）。
- **兩個 repo 分開**：
  - 系統/範本 repo（本專案，無個人資料，但**設為私有**；故專案 base 規格採 vendored 副本、不依賴 private remote）。
  - 個人全域 source `~/agent-rules`（含 role/tone，必須私有，跨裝置同步用）。

---

## 6. 重要教訓 ⚠️

**不要用 `mv` 搬動專案工作目錄。**

本次曾把 dev repo 直接 `mv` 到 `~/agent-rules`，造成兩個問題：

1. Claude Code 的對話記憶資料夾以**專案路徑**為 key，搬移後新對話對應到不同記憶資料夾而失憶，當下對話也在搬移步驟斷掉。
2. `~/agent-rules` 正是規格保留給「乾淨全域 source」的部署路徑。dev repo（帶 README/templates）坐進去後，generator 純看位置，會把 README/templates 當 core/材料污染進 `CLAUDE.md`。**改名無法解決——根因是「兩種身分共用一個資料夾」。**

**結論**：系統 repo 與部署 source 必須是不同資料夾。需要搬移效果時用另建/clone/copy，且動手前先確認。

---

## 7. 本次進度與待辦

**已完成**
- [x] 設計定案（上述決策）
- [x] 建立骨架：`GENERATE.md`、`README.md`、`templates/`（global / project）
- [x] 修正 spec 漏洞：`README.md`/`CHANGELOG.md` 等說明檔排除在 core 外（GENERATE.md §2）
- [x] 系統 repo 首次 commit 定版（`c633ce8`），push 到 `git@github.com:evanwu-tw/ai-rules.git`

**待辦 / 下一步**
- [x] 步驟 3：部署全域 `~/agent-rules`（source 在 `source/`），跑第一次生成驗證整套運作
- [x] 建 `~/agent-rules` 私有 repo + `install.sh`（新裝置 clone + symlink）→ 見 §11
- [ ] 部署時**實測 symlink**：確認 Claude Code / Codex 真的會跟隨 symlink 讀 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`（§11 已建 symlink，待開新 session 實測讀取）
- [ ] 視需要補 `CHANGELOG.md`（迭代回路記理由用）
- [x] 確認 §2 平台大小數字（Codex `project_doc_max_bytes` 32 KiB、Claude `CLAUDE.md` <200 行）→ 已查證並寫入 GENERATE.md §2（見 §12）
- [ ] `.claude/rules/` / nested `AGENTS.md` 是否由 generator 輸出 → 決議「**文件化為手動放置選項；generator 支援待決**」（見 §12）

---

## 8. Codex 交叉檢查與修正（2026-06-16）

請 Codex 對規格做 review，逐條處理如下：

| 嚴重度 | 發現 | 處理 |
|---|---|---|
| High | 全域子資料夾規格自相矛盾（§1 只輸出根檔，§2 又說任何子資料夾都拆出） | 明文規定**全域 = core-only、不可有子資料夾**；出現就停下提醒（GENERATE.md §1/§2、global README） |
| High | 專案輸出到根 `wiki/`/`reference/` 會覆蓋 repo 既有資料夾 | 改成 **namespace**：細節檔一律輸出到 `<專案>/agent-context/`；並加「無 banner 不覆蓋」安全條件 |
| High | 擁有區 drift 偵測在 LLM 改寫模式下不可靠 | **簡化 §5/§6**：擁有區一律覆蓋、**不做差異偵測**；回灌 source 改為**使用者主動觸發**；細節檔改「近乎逐字複製、agent 共用」減少改寫 |
| Medium | project `behavior.md` 重抄全域 tone | 砍成「只放本專案例外行為」的空模板 |
| Medium | project `generate.md` 綁死私人 `~/agent-rules` 路徑 | base 改**指向 GitHub repo**（可釘版本）；**團隊可 vendor** 一份鎖版本 |
| Medium | 沒有根檔大小預算 | 加「根檔大小預算」：目標 < ~200 行、超標先拆檔否則停；確切數字待核官方文件 |
| Low | `docs/` 未進 git | 連同本次修正一起 commit |

**另外自行收緊的點**：core 內嵌**依檔名排序**、建議數字前綴（可重現）；§0/§4 強調**保留規則語意、不改寫規則內容**（減少跨 agent 發散）。

**未解（留待步驟 3 驗證）**：symlink 相容性實測；§2 平台大小數字對齊官方文件。

---

## 9. Codex 第二輪 review 與修正（2026-06-17）

第一輪大洞補完後再 review，無新 High，處理剩餘規格邊界與文件殘留：

| 嚴重度 | 發現 | 處理 |
|---|---|---|
| Medium | `agent-targeting` 標記與「細節檔 agent 共用」衝突——標記若出現在細節檔，兩 agent 生成會互相覆蓋 | §7 明文：**標記只允許在 core 頂層檔**；細節檔須 agent-neutral；要 agent-specific 細節改用 `agent-context/claude/`、`/codex/` 分路徑 |
| Medium | §6 manual 簡寫示例 `<!-- agent-rules:manual -->` 錯誤（少 start/end），照抄不會被保留 | 改成引用 §5 的完整 `manual:start`…`manual:end` |
| Medium-Low | project template 預設 base 指向 GitHub，但 `ai-rules` 設**私有** → 無網路/auth 時拿不到 | 決定 repo **私有**；`generate.md` 預設改用本地 **vendored 副本** `GENERATE.vendored.md`，GitHub 只當更新來源（README 怎麼用 step 2 同步） |
| Low | 範例細節檔 `api-spec.md` / `design-system.md` 仍寫舊輸出路徑 | 改成 `agent-context/reference/…`、`agent-context/wiki/…` |
| Low | design-log 舊敘事（§4 輸出、§5「可公開」） | 已更新為 `agent-context` 與「私有」 |

---

## 10. Codex 第三輪 review 與修正（2026-06-17）

| 嚴重度 | 發現 | 處理 |
|---|---|---|
| High | `GENERATE.vendored.md` 放頂層會被當 core 內嵌、污染根檔 | 加進保留檔名例外（含任何 `*.vendored.md`）——GENERATE.md §2、README 同步 |
| Medium | agent-specific 細節檔建議（`claude/`、`codex/` 分路徑）與「細節檔共用」矛盾 | 改為**暫不支援**：要 agent-specific 就放回 core 用 agent-targeting（§7） |
| Low | template 說預設 vendored，但沒附該檔，新專案會卡 | `generate.md` 加「不存在就停止、先從 ai-rules 複製」指示（不附副本以免 drift） |

---

## 11. 跨裝置一鍵部署（2026-06-26）

落實 §5 的跨裝置設計、補完 §7 待辦。痛點：換裝置時全域 `CLAUDE.md`/`AGENTS.md` 沒有同步管道，只能每台重跑 LLM 生成（慢、非確定性）。但全域 output 跨裝置完全一致，不該每台重生。

**定案做法**：`~/agent-rules` 設為**私有 git repo**，生成 output commit 進 repo，用 **symlink + `git pull`** 同步。

| 決策 | 內容 / 理由 |
|---|---|
| 同步機制 | **symlink + git pull**：output commit 進 repo，`install.sh` symlink 到 `~/.claude/`、`~/.codex/`。新裝置 `git clone … && ./install.sh` 一鍵完成；他機 `git pull` 即生效、零重生。比「複製腳本」省一步、比「每台重生」省 LLM 與非確定性。 |
| 佈局：source 收進 `source/`、output 放第一層 | **關鍵約束**：全域 generator 把 source root 頂層 `.md` 都當 core 內嵌；若 output 與 source 同層，重生會把舊 output 當 core 又塞回去 → 自我參照污染（§6 教訓翻版）。解法：source root 改成 `~/agent-rules/source/`，generator 只讀這裡；repo 第一層只放 output + `install.sh`（部署殼）。 |
| **只動全域、不動專案** | 專案的 source 在 `<專案>/agent-rules/`、output 在專案根，**本來就分層、不污染**；專案 repo 本身就是部署殼，clone 專案即帶 output。故 `source/` 包裝是全域 scope 專屬，GENERATE.md 只改全域那一列。 |
| 私有 repo 建法 | 本機 `gh` 未安裝 → 走「GitHub 網頁建空 private repo → 本機 `git remote add` + push」；不為此裝新工具。 |
| `install.sh` 設計 | idempotent；遇擋路的實體檔先備份成 `*.bak.<ts>` 再 `ln -sfn`；路徑用 `BASH_SOURCE` 推算不寫死。 |

---

## 12. v0.2 Phase A — 分層邊界 + 精度補強（2026-06-27）

把系統的**產品邊界**寫清楚：agent-rules 是 **instruction + context compiler**，不擴張成 runtime/memory/workflow 的生成器。本輪純文件/規格層。完整 plan 與比較過程見 [agent-rules-v2.md](agent-rules-v2.md)（及 `_archive/` 的 Claude/Codex 收斂草稿）。

**分界線**：本系統只 compile 兩層——Instruction（內嵌根檔）+ Context（→ `agent-context/`）；Runtime / Memory / Workflow 不生成。五層 × 雙平台對照表 canonical 在 README；決策/放置表 canonical 在 GENERATE.md §0。（本檔只記 narrative，不複製這兩張表，守 canonical-per-table。）

**查證事實**（2026-06，以最新官方為準）：
- Codex 有 hooks、skills（`.agents/skills/SKILL.md`）、plugins、memories、rules——非只有 `AGENTS.md`。
- **同名不同物**：Codex `~/.codex/rules` = execpolicy 權限（Runtime）≠ Claude `.claude/rules/` = 路徑範圍指令（Context）。Codex 指令 path-scoping 用 nested `AGENTS.md` / `AGENTS.override.md`。
- Codex `project_doc_max_bytes` 預設 32 KiB（視為合併載入預算、各檔精簡）；Claude `CLAUDE.md` <200 行；Claude `@import` 啟動即載入（非 lazy，≈ 內嵌 Instruction）；Claude 剝除 block-level HTML 註解（banner ≈ 0 成本）。

**決策**：
- **canonical-per-table**：每張表只有一個權威位置，其餘用指針，避免多檔 drift。
- **path-scoping**（Claude `.claude/rules/`、Codex nested `AGENTS.md`）＝手動放置選項，**generator 支援待決**、本輪不生成。
- **memory**：design-log 為跨裝置主記錄；machine-local memory 為輔、非阻塞、不進 repo；長存規則回灌 source。
- **skills 邊界**：Workflow 層、tool-specific，不由本系統生成或管理；**個人 skills 路徑不寫進中立 spec**（已驗證 `Evan-projects` vs `evan-projects` 大小寫在 Linux 會壞）。
- Runtime 範例（hook/settings/config 骨架）延後 **Phase B**。

**改動**：GENERATE.md §0（分界線+決策表+hook 候選提醒）、§2（大小數字）、§4（修正 Codex profile「沒有 skills/hooks」舊敘述 + execpolicy 陷阱 + Claude `.claude/rules/` 手動選項）、§5（banner 剝除）、§6（auto-memory 回灌）；README 新增「設定分層」；project template `generate.md`/`behavior.md` 補放置指針。

**R2**：改完 ai-rules 後同步 `~/agent-rules/source/GENERATE.md`（workspace 外、需 approval；未授權則輸出手動指令、不阻塞）。

**spec 同步**：GENERATE.md §1/§2/§3.1/§8（全域 source root → `source/`、只讀 source/ 不掃第一層、output 不入 source root）；root README 加「跨裝置部署」段；`templates/global-agent-rules/` 重整成 `source/` + `install.sh` + 改寫 README。

**仍待驗證**：symlink 讀取相容性（開新 session 實測 Claude Code / Codex 是否跟隨 symlink 讀設定）；重生是否會把 symlink 換成實體檔（多數寫入 truncate-in-place 保留，需實測，README 已記 caveat）。

---

## 13. Claude/Codex 機制細節查證（2026-07-03）

重新查證 §12 的事實並補足細節層（官方文件 developers.openai.com/codex，2026-07-03 時點）。§12 結論全部仍成立。五層對照見 README 表 A、放置決策見 GENERATE.md §0；本節只記新查證細節，不複製表。

**Codex hooks 細節**（§12 只記到「有 hooks」的存在層級）：
- 位置：`~/.codex/hooks.json` 或 `config.toml` inline `[[hooks.*]]`（user 層）；`<repo>/.codex/hooks.json`（專案層）；plugin 內建；企業 `requirements.toml`（managed、使用者關不掉）。多來源並存時全部載入。
- 事件與 Claude Code 幾乎一對一：PreToolUse、PostToolUse、PermissionRequest、UserPromptSubmit、SessionStart、Stop、PreCompact/PostCompact、SubagentStart/Stop。
- 強制力：PreToolUse 回傳 `{"permissionDecision": "deny", ...}` 或 exit code 2 + stderr 可擋下工具呼叫；PostToolUse 只能 `decision: "block"` 標記、無法回滾。非 managed 的 command hook 需先 review + trust 才會執行。
- 含意：核心事件可對映（Codex 的事件名與 `permissionDecision` schema 明顯沿襲 Claude），但 **trust 模型與事件集不等價**——Codex 非 managed hook 需 review + trust、企業 managed hooks 為其特有。Phase B 若做 runtime 範例，**只做平台別範例，不做單一來源等價生成**。

**Codex subagents**（本 repo 首次記錄）：
- 定義：`~/.codex/agents/`（個人）、`.codex/agents/`（專案）下的 TOML，一檔一 agent。必填 `name`、`description`、`developer_instructions`；選配 `model`、`model_reasoning_effort`、`sandbox_mode`、`mcp_servers`、`skills.config`、`nickname_candidates`；省略欄位繼承 parent session。
- 與 Claude 的關鍵差異：(a) **Codex 不 auto-delegate**——使用者明講才 spawn，vs Claude 主 agent 讀 `.claude/agents/` frontmatter description 自動路由；(b) Codex 沒有 Claude 那種 per-subagent `tools:` 白名單，能力控制主要落在 `sandbox_mode`（read-only / workspace-write）、`mcp_servers` 與 config；(c) Codex `[agents]` 全域設定 `max_threads`(預設 6)、`max_depth`(預設 1)、`job_max_runtime_seconds`(預設 1800)，並有 `spawn_agents_on_csv` 宣告式批次。
- **決策：subagent 屬 Runtime/Workflow 層、不 compile**——Claude 定義的核心價值（description 自動路由）在 Codex 側直接失效，`tools:` 白名單也只能降級成 `sandbox_mode` / `mcp_servers` 的粗粒度控制。維持 Phase A 邊界，表 A 不加列。

**AGENTS.md 解析補充**（對 §12 的 32 KiB 事實加精度）：每層取一檔，優先序 `AGENTS.override.md` > `AGENTS.md` > `project_doc_fallback_filenames` 註冊的替代檔名；由 root 往下串接、近者覆蓋、跳過空檔、達 `project_doc_max_bytes`（預設 32 KiB）即截停。

**下一輪優化的邊界提醒**（Codex 交叉 review 後確認）：GENERATE.md 只補「不生成的理由」與 hook/subagent 候選提醒，**不加生成 runtime config 的流程**；README 表 A 維持現狀、不加 subagent row；design-log 維持決策紀錄定位、不變成第二份 spec。

**Sources**：developers.openai.com/codex 的 `hooks`、`guides/agents-md`、`subagents`、`config-reference`；Claude 側對照：code.claude.com/docs 的 `sub-agents`、`hooks`。

---

## 14. §13 查證落地：spec 精度與一致性修正（2026-07-03）

把 §13 的查證事實落回使用者查閱動線（GENERATE.md、README、templates），守 §13 邊界提醒。本輪純措辭/精度，不改產品邊界。

**改動**：
- GENERATE.md §0：補「Runtime/Memory/Workflow 為什麼不生成」段（核心理由：三層跨平台**語意不等價**，單一 source 硬 compile 只會產生假等價）；表 B 加 subagent 列；hook 候選提醒補 Codex `hooks.json` 精度；新增 subagent 候選提醒。
- GENERATE.md §2：AGENTS.md 32 KiB 預算補「root 往下串接、達上限截停、深層檔先被丟」精度。
- GENERATE.md §4：Claude profile 平台特有段落補 subagents；Codex profile 補 nested `AGENTS.md` 合併精度（每目錄取一檔、`AGENTS.override.md` 優先、近者覆蓋）、hooks 位置、subagents（明點、不自動路由）、**path-scoping 降級提醒**（跨目錄 glob → root `AGENTS.md` 文字描述，無機制保證）。
- README：表 A Runtime 列 Codex 欄補 `hooks.json`（只改 cell、不加列）；path-scoping bullet 加降級策略指針 → GENERATE.md §4。
- templates/project generate.md：不生成清單補 subagent。

**決策**：
- **表 B 加 subagent 列、表 A 不加**：§13 邊界只凍結表 A；表 B 的目的是窮舉「什麼放哪」，subagent 是真實放置問題，缺列比擴張解讀風險更實質。加的是 ❌ 列，不改 Phase A 邊界。
- **降級策略 canonical 落 §4 Codex profile**，README 只放指針（canonical-per-rule）。措辭限定「手動搬移時的提醒」，不是 generator 行為。
- 這些改動服務的是**生成/review/搬規則時刻**的 compiler agent 與人，不改變日常 session 行為——與系統定位一致。

**邊界確認**：未加生成 runtime config 流程；未複製任何 canonical 表；已 vendor 的 `GENERATE.vendored.md` 屬鎖版本設計，不追改。

**R2**：GENERATE.md 已改 → 需同步 `~/agent-rules/source/GENERATE.md`（workspace 外；未授權則手動 `cp GENERATE.md ~/agent-rules/source/GENERATE.md` 後 commit）。

---

## 15. skills 部署併入全域部署殼（2026-07-03）

**決策**：skills 從獨立 repo（`skills-source` + `sync-skills.sh`）遷入全域部署殼 `~/agent-rules/skills/`，`install.sh` 擴充成一鍵部署「全域規則＋skills」。新裝置一行：clone + install.sh。

**理由**：
- 原架構兩套部署系統、兩套維護心智；且 `sync-skills.sh` 與全部 symlink 指向小寫路徑（`~/evan-projects`），macOS 大小寫不敏感撐著、Linux/新裝置會斷（§12 已預言過這類坑）。
- **層邊界不變**：skills 是 Workflow 層資產，generator 只讀 `source/`、永不讀 `skills/`（§1 本來就規定不掃 repo 第一層），放進部署殼不污染生成。本系統依然只 compile Instruction + Context——變的是**部署殼多載一種資產**，不是 generator 多生成一層。

**改動**：`templates/global-agent-rules/install.sh` 加 skills 迴圈（只連含 `SKILL.md` 的資料夾，symlink 到 `~/.claude/skills/`、`~/.codex/skills/`）；template README 佈局圖與說明補 `skills/`（選配）；root README 跨裝置部署段同步；GENERATE.md §1 加一句「部署殼可放 Workflow 資產、generator 一律只讀 source/」。

**R2**：GENERATE.md 又改 → 同步 `~/agent-rules/source/GENERATE.md`（本輪已直接執行，含 §14 那次的欠帳）。

---

## 16. 生成物與規則檔不帶 provenance 敘事（2026-07-08）

**問題**：當 prompt 把任務框架寫成一段身世敘事（例如「這是某某 session、要為之後的環境立制度」），聽話的 agent 會把那段框架**烤進產出檔**——規則檔開頭變成在自報「我是哪個 model、哪次 session、哪天寫的」，並夾帶「某修法已生效」這類時間點狀態。這讓規則讀起來像 changelog、把規則與歷史混在一起，也讓後續 model 傾向按「作者是誰」而非「內容對不對」來對待規則。

**決策**：生成物與規則檔一律**由內容自我證成**，不寫作者身分、session 身世、生成時間點或執行狀態。三類東西各有去處：

| 內容 | 去處 |
|---|---|
| 系統層中立決策（如本條） | 本 design-log |
| 個人 ops 制度的時間點診斷／決策 | 該制度自己的 append-only log（如 `~/agent-rules/docs/ops/decisions.md`），**不進**本中立 repo |
| 不隨時間變的「為什麼」 | 放進規則檔的常駐理由段，敘述成 timeless 事實（「X 導致 Y」），不敘述成「某次發現 X」 |

**理由**：
- 規則的權威應來自它**擋掉的失效模式**，不是作者身分——身世敘事會誘發對「聰明 model 遺物」的膜拜或輕視。
- 與本 repo 既有原則一致：canonical-per-concern、design-log 是 append-only 決策紀錄而非第二份 spec；身世本就該進 log，不該滲進常駐文件。

**邊界**：本條是**措辭／文件衛生**原則，不改任何生成邊界或 Phase A 範圍。

**待辦（先問 Evan 再動，屬 core spec）**：把「生成物不帶 provenance 敘事」明文收進 `GENERATE.md`，讓每次生成都遵守而不只靠這條 log。本輪未改 `GENERATE.md`。（→ 已於 §17 落地。）

---

## 17. §16 落地：provenance 原則寫進 GENERATE.md（2026-07-08）

§16 的待辦（Evan 授權後）已執行。

**改動**：
- `GENERATE.md §0`：於「保留規則語意、不增刪」bullet 後加一條「**產出不帶 provenance 敘事**」——生成物只講規則本身，不寫 model／session／生成日期身世與「已生效」狀態；source 若夾帶則生成時濾掉。明寫兩個防呆：純 `last-updated:` 日期可留、本條不改任何生成邊界。
- `GENERATE.md §8`：重生 checklist 加一項「產出未夾帶 provenance 敘事」，確保每次生成都檢查、不只躺在 §0。

**取捨**：放 §0（compile 時的過濾動作，與「保留語意、不增刪」同層級），不放 §2（免被誤讀成改拆檔邏輯）；措辭限定「措辭衛生、不改生成邊界」，守 Phase A。

**R2**：GENERATE.md 已改 → 已同步 `~/agent-rules/source/GENERATE.md`（cp，兩份 diff 為零）。
