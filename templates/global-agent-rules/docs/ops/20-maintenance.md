# 規則維護流程

> last-updated:
> 只在修改這套全域規則的 Ops、source 或 install.sh 時讀。生成程序的唯一權威是部署 repo 的 `source/GENERATE.md`（從系統 repo 複製）。

## 1. 權限分級

- 提問與 review 不授權改檔；已有明確授權不重複詢問。
- 可在授權範圍內修 typo、失效連結，追加教訓或歷史決策。
- 修改鐵則、門檻、結構、core source、生成規格，或刪除規則、收斂教訓，需要明確授權。
- 型號或參數的更新附官方來源或實測證據；mapping 只維護在 [10 §4](10-dispatch.md#4-模型分層與平台-mapping)。

## 2. 修改流程

1. 先保存原檔與可恢復備份。生成中的 staging 放 workspace 外；驗證完成後把備份與驗證紀錄封存到 `_archive/backups/<日期或任務>/`，保留原相對路徑。
2. 同一條規則只維護一處。Ops 放詳細條件，source 只放日常原則與讀取觸發。
3. 改檔名或章節時，同步檢查入口與連結。source 改完依生成規格重生 `AGENTS.md`，`CLAUDE.md` 只引用它。
4. 更新 last-updated；理由與時間點放決策紀錄，不混入規則本文。驗收依 [10 §5](10-dispatch.md#5-驗證矩陣)。確認無誤且已提交後才清理備份。
5. commit、push 依本次授權執行。

## 3. 歷史與交接

- 只有追溯設計理由時才查 [_archive/history/](../../_archive/history/README.md)；舊指令不覆蓋有效規則。
- 時間點決策追加到 `_archive/history/decisions.md`，舊紀錄不改寫。
- 未完成工作的 checkpoint 記完成項、下一步、風險與驗證狀態。
