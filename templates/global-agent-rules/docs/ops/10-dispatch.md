# 派工與驗證

> last-updated:
> 按需閱讀，只讀與當前任務相關的章節。常駐 core 只放讀取觸發，不重抄本檔。

## 0. 原則

- 何時派工、何時直接做的共同判準。

## 1. 派工判斷

- 可獨立驗收才派工；context 管理本身不是派工理由。

## 2. Context 與 ownership

- 主 context 的原文上限、平行讀取、寫入 ownership 與 Git mutation 的歸屬。

## 3. 派工與回報合約

- 派工必附：目標、可判 pass/fail 的驗收條件、回報格式與長度上限。

## 4. 模型分層與平台 mapping

- 型號、effort 與不適用條件的唯一對照。其他文件只引用本節。
- 型號會變動，更新時附官方來源或實測證據。

## 5. 驗證矩陣

| 產出 | 最低驗證 | 執行者 |
|---|---|---|
| 規則、source、Ops 與生成物 | 逐項 fresh-context read-back | 未參與修改、機制性唯讀的 verifier |
| 程式碼或 script | 測試、syntax check 或實跑 | 未參與修改者優先 |
| 一般低風險文件 | diff 加回讀 | 執行者 |

## 6. 重試與升級

- 先改善 prompt，再調 effort，最後才升 model tier；同一子任務的重試上限。

## 7. 落檔與成本

- 長任務的 checkpoint 位置與交接內容。

## 8. 教訓紀錄（append-only）

- 格式：日期｜情境｜教訓｜如何套用。只追加，收斂需明確授權。
