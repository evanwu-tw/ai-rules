# generate.md — 本專案生成指令

本檔引用全域規格為 base，再補上本專案特有的生成規則。

這是生成模式的模板。新的一般專案優先使用系統 repo 的 `templates/project/`，直接維護 `AGENTS.md`；已有生成流程的專案不自動轉換。

## Base

完整生成程序、共用入口、擁有區機制、驗證與恢復，一律依 base 規格 `GENERATE.md`：

- **預設（推薦）**：本資料夾內的 **`GENERATE.vendored.md`**，從系統 repo 的指定 commit 複製並鎖版本。檔頭註明來源 repo 與 commit，供離線使用。
  - **若此檔不存在**：先**停止**，從 `ai-rules` 複製 `GENERATE.md` 成本資料夾的 `GENERATE.vendored.md`（檔頭註明來源 commit）後再繼續。不要拿頂層其他檔當 base。
- **更新來源**：上述來源 repo 的 `GENERATE.md`；比較差異後再更新 vendored 版本與註記。
- 本機已同步全域時，亦可直接用 `~/agent-rules/source/GENERATE.md`。

## 本專案特有（範例，請改成你的）

- scope：專案。source = 本資料夾 `agent-rules/`；輸出 = 專案根共用 `AGENTS.md` 與引用它的 `CLAUDE.md`，細節檔 → `agent-context/<子資料夾>/`。
- **不要**重抄全域規則（角色、語氣、通用規範）——那些靠全域設定檔自動合併，這裡只放本專案**例外/特有**規則。
- 本專案可指向其他專案查閱資料，但**只能讀、不可修改其他專案**。
- **本系統只生成 instruction + context**：hook / runtime config / skill / subagent / memory **不由本系統生成**。強制性規則（能被程式檢查或事件觸發）請標為 **hook candidate**、改用 hook，不要只寫成 markdown。放置原則見 `GENERATE.vendored.md` §0 的決策表。
- <在這裡補你的覆寫，例如：本專案 commit 訊息用英文…>

> 本檔只能覆寫內容呈現、拆檔與索引策略；source-only、ownership/banner、manual、snapshot、輸出邊界、gate、交易恢復與機制性唯讀驗證仍依 base 規格，不得放寬。

舊 targeting 先依 base 的遷移程序處理，不再分平台生成。平台專屬規範依 base §4 手動維護；既有鎖版專案不自動升版。
