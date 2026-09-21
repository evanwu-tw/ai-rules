# GENERATE.md：生成模式規格

本檔是 source/output 分離的**生成行為唯一權威**。一般專案直接維護 `AGENTS.md`，不使用本流程，見 [README](README.md)。既有直接維護的檔案不得因採用模板而自動被 generator 接管；已有生成物的專案也不自動轉換模式。

## 0. 心智模型

- source 是規則原稿；agent 負責組裝、拆檔與索引，不增刪規則或改變語意。不依執行 agent 改寫稱呼、語氣或產出另一份平台版本。
- 本系統只生成 Instruction 與 Context；Runtime、Memory、Workflow 與各平台能力的設定不在生成範圍。五層對照見 [README](README.md#設定分層五層模型)。
- 生成物不寫 model、session、生成日期身世或「已生效」等狀態敘事；source 中若有，生成時濾掉。純 `last-updated:` 與 §5 的 banner 可保留。理由與歷史留在決策紀錄。

### 決策 / 放置表（僅適用生成模式；canonical 在此）

| 需求 | 放哪 | 本系統生成? |
|---|---|---|
| 每次都該遵守的規則 | `agent-rules/` 頂層 core | 是 |
| 按需閱讀的資料 | source 子資料夾 → `agent-context/` + 索引 | 是，僅專案 |
| 特定路徑的指令 | 手動：Claude `.claude/rules/`；Codex nested `AGENTS.md` | 否 |
| 可程式檢查或事件觸發的強制限制 | 平台 hook / 權限設定 | 否 |
| 個人偏好或歷史脈絡 | memory；長存修改依 §6 | 否 |
| 多步驟、可重複工作 | skill / command / plugin | 否 |
| 特定角色的可重複任務 | 平台 subagent 設定 | 否 |

Reviewer 遇到可程式驗證的強制規則，標為 hook 候選；遇到特定角色的重複任務，標為 subagent 候選。提醒使用者依平台設定，不替使用者生成。平台機制不保證等價，不能把 markdown 指令當成強制執行機制。

## 1. 兩個 scope

| scope | source root | 平台目標 |
|---|---|---|
| 全域 | `~/agent-rules/source/` | 部署 repo 第一層 `AGENTS.md` 共用內容、`CLAUDE.md` 引用入口；由安裝器連到平台位置 |
| 專案 | `<專案>/agent-rules/` | 專案根 `AGENTS.md` 共用內容、`CLAUDE.md` 引用入口；細節在 `agent-context/` |

- 每次固定檢查共用檔與引用入口，不再接受平台 profile 或 single-target 分支。任一 agent 均依同一規格產出這一組檔案。
- 全域 source 只准頂層 core，出現子資料夾就停止。不得把 output 寫進 source root，也不得把部署 repo 第一層的 output、安裝器或 skills 當 source。
- 全域走 symlink 部署時，保留既有部署方式，見 [README](README.md#跨裝置部署)。全域不生成 `agent-context/`。
- 專案不重抄全域規則。細節只能輸出到 `agent-context/`，不得寫進專案根既有的 `wiki/`、`docs/` 等同名資料夾。

## 2. source 佈局規則（資料夾即分類）

1. 頂層 `.md` 為 core，依檔名排序只內嵌進 `AGENTS.md`；可用 `00-`、`10-` 前綴固定順序。
   - 排除 `GENERATE.md`、`generate.md`、`README.md`、`CHANGELOG.md` 與所有 `*.vendored.md`（含 `GENERATE.vendored.md`），不將這些工具檔內嵌。
2. 專案的任意子資料夾為按需資料，保留檔名與巢狀路徑，近乎逐字複製到 `agent-context/<原相對路徑>`，兩個 agent 共用，不依平台改寫。全域不適用。
3. `AGENTS.md` 只索引按需資料，逐檔加一般相對連結及「何時該讀」。連結不會強制載入，讀取時機必須清楚。

4. `CLAUDE.md` 的生成區只有 §5 banner 與獨立一行 `@AGENTS.md`；保留其原有 manual。不再複製 core。沒有 manual 時，import 是唯一非註解內容。

### 根檔大小預算

- Claude 引用入口展開共用檔與 manual 後，常駐規則目標低於約 200 行，不能只計算 wrapper 行數。Codex `project_doc_max_bytes` 預設 32 KiB；本系統保守以全域與專案鏈合計控制預算，避免後面的深層指引被截停。
- Claude `@import` 會載入內容，不省 context。按需細節不得用 `@import`；一般相對連結依 §2.3。
- 超標就停止生成並提出 source 精簡建議；generator 不自行刪改或搬移 source。專案要拆 source 子資料夾，先取得修改授權；全域維持 core-only。
- 官方來源（查閱：2026-09-15）：[Claude memory](https://code.claude.com/docs/en/memory)、[OpenAI AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)。

## 3. 生成程序（逐步）

1. **確認 scope 與授權**：依 §1 定位 source 與固定的兩個 root outputs。全域寫部署 repo 的實體檔，不經平台 symlink 寫入。未授權的其他專案、原生設定與 skills 不在範圍。
2. **落檔 snapshot**：正式寫入前，在 workspace 外建立 task staging。保存同批完整 source、兩個既有 root outputs、全部既有 `agent-context/` outputs、各檔 manual、每個候選路徑的 bytes／不存在狀態及 canonical path／symlink 狀態；建立 checksum manifest 並設為唯讀。保留至獨立 post-write 驗證完成，失敗則保留並回報位置。後續只用此 snapshot，source 全程唯讀。
3. **讀完整 source 與指令**：依 §2 排除工具檔；專案先讀 `generate.md` 指定的 base。專案只可覆寫內容呈現、拆檔與索引策略，不得放寬 source-only、ownership/banner、manual、snapshot、輸出邊界、gate、交易恢復與機制性唯讀驗證。
4. **檢查可共用性**：依 §7 偵測未遷移的 targeting，命中就停止。首次轉換的 `AGENTS.md` 如含 manual，未經使用者明示確認可供兩平台共用前停止；不得因 import 默默擴大其適用範圍。不把 output 當規則 source。
5. **組裝共用內容**：core 依檔名排序保留語意進 `AGENTS.md`；產生 §2 定義的引用入口，逐檔加入按需索引，檢查展開後大小。來源不存在的規則不得補入。
6. **處理細節與 orphan**：專案細節近乎逐字複製到 `agent-context/`。掃出已無 source 對應的 generated orphan，列入 dry-run，不自動刪除。無 manual 的 orphan 只有在使用者看過 dry-run 並明確確認後才納入刪除交易；有 manual 就停止，先另行遷移。未知 ownership 依 §3.8，不覆蓋。
7. **只寫 staging**：組裝全部 candidates，加 banner、依 §5 保留各檔 manual；建立 source path、heading、出現順序到候選內容的 section manifest。`CLAUDE.md` 的 coverage 透過展開 `@AGENTS.md` 計算，不要求在 wrapper 複製本文。
8. **寫入前雙重 gate**：機械檢查 scope/path allowlist、既有與候選 banner、manual 數量／順序／標記／bytes、section coverage、import 唯一性及目標可解析、targeting 零命中、orphan、大小與 source-only。另由獨立語意 reviewer 比對每項 source 義務在 `AGENTS.md` 與 Claude 展開內容中一致；不以機械 coverage 代替語意驗證。任一疑點、不確定或意見衝突就停止，正式 outputs 零寫入。既有 output 無合法 banner 時，先列候選 diff 與接管／不接管選項，告知「所有非 manual 區日後重生可能完整覆蓋」，取得明確接管授權後才可繼續；之前不得自動備份、改名或覆蓋該檔。
9. **交易與恢復**：寫入前再比對 source 與每個候選 output 的完整 pre-run state，含 bytes、manual、不存在狀態與 canonical/symlink 位置；任一 drift 就停止且 outputs 零寫入。通過後整批替換共用檔、入口與候選細節／已授權刪除。任一步或 post-write 驗收失敗，從 snapshot 恢復所有候選的原 bytes，刪除本輪新建的候選；不得用 Git reset/checkout 恢復，也不恢復 source 或改動其他檔案。snapshot 保留。
10. **獨立驗證並回報**：機制性唯讀的 fresh-context verifier 接收規格、同批 snapshot、candidates、機械與語意 gate 結果、dry-run diff 及寫入結果，不拿作者的完成結論。逐項驗收 coverage、reverse coverage、import 展開語意、banner、manual、大小、targeting 與交易結果。無此機制只能標示未驗證，不能宣稱完成。通過後才可清理 staging；回報更新／刪除檔案、保留的 manual、展開大小與實際載入驗證狀態。

## 4. 平台載入與專屬規範

共用指令只存在 `AGENTS.md`。兩平台入口載入同一份內容，不承諾模型行為完全相同。專屬規範只有實際需要才新增；不建立空規則，也不由 generator 管理平台設定。

### Claude Code

- 目標檔名依 §1。Claude 載入 user 與專案的 `CLAUDE.md`；子目錄的檔案在讀取該目錄檔案時載入。`CLAUDE.md` 透過 `@AGENTS.md` 載入共用規則。
- `@import` 只用於常駐內容；按需細節仍用一般連結。直接維護與生成模式都可用此入口，差別是原稿是否位於 source，不以 import 判斷 ownership。
- 路徑限定規則可手動放 `.claude/rules/`，以 `paths:` 限定範圍；不帶 `paths:` 的規則不是按需載入。本系統不生成。

### Codex

- 目標檔名依 §1。先讀 Codex home（預設 `~/.codex`）的全域指引，再從專案根目錄往目前工作目錄串接；全域優先取非空 `AGENTS.override.md`，否則取 `AGENTS.md`。
- 專案每個目錄依序找 `AGENTS.override.md`、`AGENTS.md`、設定的 fallback 檔名，最多取一份。越接近工作目錄越晚載入，衝突時優先。
- 路徑限定使用手動 nested `AGENTS.md` / `AGENTS.override.md`。Claude glob 可跨目錄，nested 按目錄分層，兩者不等價；跨目錄規則若改寫到 root `AGENTS.md`，須以文字標示範圍，並說明無機制保證。
- Codex execpolicy `rules` 是權限設定，不是 Claude `.claude/rules/` 的對應物；本系統不生成兩者。

- 工作方式的 Codex 專屬差異可另由原生 `developer_instructions` 設定管理；它是額外 developer 指令，不是 Markdown rules。僅在有明確差異時另行維護，不由本系統生成或覆蓋整份 TOML。來源：[OpenAI 設定欄位](https://learn.chatgpt.com/docs/config-file/config-reference)。

平台載入與大小來源見 §2。Claude 專屬差異使用其 rules；權限、hooks 與其他平台設定不混入文字指令生成。

## 5. 擁有區 vs 手動區（防 drift）

生成檔預設為 generator 擁有區，重生時整段替換；不偵測或回灌擁有區的手改。想長存就改 source。手動區用下列標記，含標記與內容原樣保留：

```markdown
<!-- agent-rules:manual:start -->
這裡是使用者手寫、重生要保留的內容。
<!-- agent-rules:manual:end -->
```

順序：先擷取每個既有檔的全部 manual 區塊，再重建擁有區，最後把 manual 放回同一檔的原相對位置，盡量貼近原前後文。未被 manual 包住的內容不保證保留。markers 只在 fenced code block（反引號或波浪號）外、整行完全匹配正式標記時解析；inline、近似寫法及帶前後空白者不解析。manual 必須成對且不巢狀；數量、順序、標記與 bytes 均不得改動。寫入 gate 依 §3。

共用 `AGENTS.md` 的 manual 對兩平台都可見；Claude 入口的 manual 只供 Claude。首次遷移的共用適用性確認依 §3.4；不得把舊 manual 搬進 source 或其他 output。

### Banner

每個生成檔頂部使用以下 banner；Claude 會剝除 block-level HTML 註解，Codex 未確認，所以仍保持精簡：

```markdown
<!--
GENERATED by agent-rules — source: <該 scope 的 agent-rules/ 路徑>
- 想長存的改動：改 source 再重生。擁有區會被重生整段覆蓋。
- 想保留在本檔的內容：包進 agent-rules:manual 區塊，重生會保留。
- 詳見 GENERATE.md §5、§6。
-->
```

合法 banner 為第一個非空白 block-level HTML comment 內含 exact string `GENERATED by agent-rules`；source path 是 metadata，不影響辨識。無合法 banner 的接管流程依 §3.8。

## 6. 修改規則：只改 source，再生成

- 依使用者授權直接改 source，再生成。生成期間 source 唯讀，不從 output 或 memory 推導、補寫或自動回灌規則。
- 可以讀既有 output 做快照、banner/manual 與 drift 檢查、失敗恢復；manual 只原樣放回同一檔，不移入 source 或其他 output。
- memory 是學習紀錄，不是生成來源。需長存的規則由使用者確認具體要求並授權修改 source，不由 generator 自動升格。
- 修改理由放 `CHANGELOG.md` 或決策紀錄，不混入常駐規則；工具檔排除依 §2。

## 7. 舊 targeting 的遷移

新共用 source 不使用平台 targeting。依 §5 相同的 fence／整行規則，掃描 core 與細節中的 `<!-- agent: claude -->`、`<!-- agent: codex -->`、`<!-- /agent -->`；命中任何一個就停止，列出位置，不自動跳過、合併或把平台專屬內容公開給兩邊。

由使用者授權另行修改 source：純措辭差異可合併為中立表達；真正的平台規範移到其原生入口，再從新 source snapshot 生成。既有鎖版專案不自動更新或批次遷移。

## 8. 重生 checklist

- [ ] Scope、source root、實體輸出位置、core-only、source-only 與專案不重抄全域符合 §1–§2。
- [ ] 同批完整 snapshot、checksum、唯讀狀態、pre-run bytes／不存在與路徑狀態已落檔並保留（§3.2）。
- [ ] 工具檔排除、排序、索引與讀取時機正確；超標停止，未自行刪改或搬移 source（§2）。
- [ ] 固定產出共用內容與 import 入口；targeting 零命中，首次轉換 manual 的共用性已確認（§3.4、§7）。
- [ ] 所有 source 義務在共用檔與 Claude 展開內容一致；未加身世敘事、平台改寫或自動生成專屬設定（§0、§4）。
- [ ] 原檔及候選 banner、manual 配對／順序／bytes、ownership、orphan 與接管授權符合 §3.6–§3.8、§5；未自動刪 orphan。
- [ ] 機械 gate 與獨立語意 review 分開通過；任何疑點零寫入（§3.8）。
- [ ] source/output 無 drift 後才整批寫入；失敗按 snapshot 恢復所有候選 pre-run state，不用 Git 恢復（§3.9）。
- [ ] fresh-context verifier 有機制性唯讀限制，已逐項回讀；否則明列未驗證（§3.10）。
- [ ] 已回報更新／保留／刪除、共用及展開大小、backup 與實際載入狀態；未把檔案存在當 runtime 驗證。
