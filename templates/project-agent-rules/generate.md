# generate.md — 本專案生成指令

本檔引用全域規格為 base，再補上本專案特有的生成規則。

## Base

完整生成程序、agent profile、擁有區機制、迭代回路，一律依**已發佈的規格 `GENERATE.md`**：

- **預設**：`github.com/evanwu-tw/ai-rules` 的 `GENERATE.md`（建議釘特定 tag/commit 鎖版本）。
- 本機已同步全域時，也可用 `~/agent-rules/GENERATE.md`。
- **放進團隊 repo 時**：把該版 `GENERATE.md` vendor 一份進本資料夾（如 `agent-rules/GENERATE.vendored.md`）並鎖版本，避免依賴他人本機路徑或私人規格。

## 本專案特有（範例，請改成你的）

- scope：專案。source = 本資料夾 `agent-rules/`；輸出 = 專案根 `CLAUDE.md` / `AGENTS.md`，細節檔 → `agent-context/<子資料夾>/`。
- **不要**重抄全域規則（角色、語氣、通用規範）——那些靠全域設定檔自動合併，這裡只放本專案**例外/特有**規則。
- 本專案可指向其他專案查閱資料，但**只能讀、不可修改其他專案**。
- <在這裡補你的覆寫，例如：本專案 commit 訊息用英文 / 某段只給某 agent…>

> 與 base `GENERATE.md` 衝突時，以本檔為準。
