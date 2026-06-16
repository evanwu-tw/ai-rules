# generate.md — 本專案生成指令

本檔引用全域規格為 base，再補上本專案特有的生成規則。

## Base

完整生成程序、agent profile、擁有區機制、迭代回路，一律依 **`~/agent-rules/GENERATE.md`**。
（若你的全域規格放在別處，改成對應路徑。）

## 本專案特有（範例，請改成你的）

- scope：專案。source = 本資料夾 `agent-rules/`；輸出 = 專案根的 `CLAUDE.md` / `AGENTS.md` / `wiki/` / `reference/`。
- **不要**重抄全域規則（角色、語氣、通用規範）——那些靠全域設定檔自動合併。
- 本專案可指向其他專案查閱資料，但**只能讀、不可修改其他專案**。
- <在這裡補你的覆寫，例如：本專案語氣要更正式 / 某段只給某 agent / 額外的輸出資料夾…>

> 與 `~/agent-rules/GENERATE.md` 衝突時，以本檔為準。
