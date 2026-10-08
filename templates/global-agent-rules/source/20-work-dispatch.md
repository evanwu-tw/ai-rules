# 工作方式（core）

> 全域 core。只放每次都要遵守的原則與「何時讀哪份 Ops」的觸發；詳細條件放部署 repo 的 `docs/ops/`。

## 執行與驗證

- 什麼情況直接做、什麼情況才派工：（例如：簡短或相依的工作直接做，使用者要求時才派工）
- 驗證依影響範圍：（例如：一般文件 diff 加回讀；程式碼跑測試或實跑）
- 規則、source、Ops 與生成物的驗證方式：（例如：由未參與修改、機制性唯讀的 verifier 回讀，做不到就標未驗證）

## 需要時才讀

- 派工、併發寫入或獨立驗證前，只讀 `~/agent-rules/docs/ops/10-dispatch.md` 的相關章節。
- 修改這套全域規則的 Ops、source 或 install.sh 前讀 `~/agent-rules/docs/ops/20-maintenance.md`；生成時以 `~/agent-rules/source/GENERATE.md` 為唯一程序規格。
- 一般對話不讀 Ops。歷史資料不作現行指令，只有追溯特定決策時才讀 `~/agent-rules/_archive/history/`。
