# generate.md — 本專案生成指令

本檔引用全域規格為 base，再補上本專案特有的生成規則。

## Base

完整生成程序、agent profile、擁有區機制、迭代回路，一律依 base 規格 `GENERATE.md`：

- **預設（推薦）**：本資料夾內 vendored 的 **`agent-rules/GENERATE.vendored.md`**——從 private repo `github.com/evanwu-tw/ai-rules` 某 commit 複製、**鎖版本**。自包含、離線可用，不依賴網路或 GitHub auth。檔頭請註明來源 commit。
  - **若此檔不存在**：先**停止**，從 `ai-rules` 複製 `GENERATE.md` 成本資料夾的 `GENERATE.vendored.md`（檔頭註明來源 commit）後再繼續。不要拿頂層其他檔當 base。
- **更新來源**：private repo `github.com/evanwu-tw/ai-rules` 的 `GENERATE.md`（有權限時 pull 最新、重新 vendor、更新版本註記）。
- 本機已同步全域時，亦可直接用 `~/agent-rules/source/GENERATE.md`。

## 本專案特有（範例，請改成你的）

- scope：專案。source = 本資料夾 `agent-rules/`；輸出 = 專案根 `CLAUDE.md` / `AGENTS.md`，細節檔 → `agent-context/<子資料夾>/`。
- **不要**重抄全域規則（角色、語氣、通用規範）——那些靠全域設定檔自動合併，這裡只放本專案**例外/特有**規則。
- 本專案可指向其他專案查閱資料，但**只能讀、不可修改其他專案**。
- **本系統只生成 instruction + context**：hook / runtime config / skill / subagent / memory **不由本系統生成**。強制性規則（能被程式檢查或事件觸發）請標為 **hook candidate**、改用 hook，不要只寫成 markdown。放置原則見 `GENERATE.vendored.md` §0 的決策表。
- <在這裡補你的覆寫，例如：本專案 commit 訊息用英文 / 某段只給某 agent…>

> 與 base `GENERATE.md` 衝突時，以本檔為準。
