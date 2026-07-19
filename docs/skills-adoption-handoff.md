# 社群 skills 採用評估：交接文件

日期:2026-07-19。用途:給另一台電腦的 Claude 接續討論。內容 = Claude 查證結論 + Codex 對抗式 review + 未決事項。

## 背景與限制

- Evan 用 Claude Code Pro,額度稀缺,context 經濟是硬約束。
- 已有自建體系:全域工作調度鐵則(指揮官不下場、派工三件套、驗證不自驗、模型升降級)、memory 系統、`docs/ops/10-dispatch.md` 教訓區、自建 skills(grill-me、spec-review、claude-cross-review、codex-cross-review、doc2md)。
- 評估對象:四個社群 skill。目標是決定「裝整包 / 受控引入 / 不碰」。

## 四個 skill 摘要

| Skill | 來源 | 一句話 | 關鍵機制 |
|---|---|---|---|
| find-skills | vercel-labs/skills | skill 版 npm search | 被動觸發,跑 `npx skills find` 查 skills.sh 第三方生態,靠星數/安裝數篩選,無官方審核 |
| impeccable | pbakaus/impeccable | 前端設計品質規則庫,防「AI 味」UI | `/impeccable` 帶 23 子命令 + 46 條 deterministic detector rules;init 生成 PRODUCT.md/DESIGN.md 常駐;hook 自動偵測 UI 改動注回 findings;有獨立 CLI `npx impeccable detect` |
| superpowers | obra/superpowers(官方 marketplace 收錄) | 強制串接的開發方法論 | 14 skills:brainstorming → writing-plans → subagent-driven-development(乾淨 subagent 防 context 污染)→ TDD → code review → verification;prompt 層級軟強制,非 harness hook |
| task-observer | rebelytics/one-skill-to-rule-them-all | 觀察使用模式、自動改進 skill 的 meta-skill | 常駐觀察 → 三段式觀察記錄(issue/改法/可泛化原則)→ 人工核准 → skill-creator 動手改;手動安裝,非 plugin 系統 |

注意:impeccable 的資料有版本漂移疑慮(Claude 查到 376 規則/四階段流程,Codex 查 upstream 現況是 46 detector rules/Plan-Build-Review-Refine),引用前先重新確認 upstream。

## Claude 初版建議

1. find-skills:不裝 skill,手動跑 CLI 瀏覽、讀過 SKILL.md 再決定(供應鏈風險)。
2. impeccable:四個中最值得裝,只在前端專案 init、關 hook 改收尾手動 audit。
3. superpowers:不裝整包(與既有鐵則高度重疊),抽 systematic-debugging 與 writing-skills 概念進 docs/ops。
4. task-observer:不裝(與 memory + 教訓區雙軌重複),只抄三段式觀察格式進收尾流程。
5. 順序:先在 Portfolio 試 impeccable,其餘抽概念。

## Codex 對抗式 review 重點(不同意處)

核心批評兩條:

1. **「不裝、手動跑 CLI」不必然更安全**:未 pin 版本的 `npx skills find` 一樣下載執行 npm package,風險只是換入口。只讀 SKILL.md 不夠,要審 bundled scripts/hooks/install 行為/dependencies/是否 pin SHA。
2. **「抽概念」是功能降級不是等價替代**:只保留內容,丟掉 trigger、enforcement、review、approval、rollback。文件不等於 enforcement,寫進 docs 不保證 agent 會在對的時間觸發。

逐項替代方案:

- find-skills:discovery 走瀏覽器或 pin 版 CLI;候選 skill pin commit SHA、project scope、不自動更新;建立最小檢查表(tree/scripts/hooks/network/write scope/license/維護日)。同類需求出現 ≥3 次且每月估省 ≥30 分鐘才進入安裝評估。
- impeccable:降級為 detector-only pilot。Portfolio 選 2 個完成頁,不 init、不 hook、不 Live Mode,只跑 deterministic audit 人工判 findings。驗收:precision ≥70%、每頁 ≥3 項採納、audit 時間 -25%、零錯改零 artifact 污染;連 3 次未達標移除。
- superpowers:既有鐵則覆蓋度被高估(缺 lifecycle enforcement、TDD、plan approval、逐 task review、debugging 操作細節)。不抽概念,改 **vendoring 完整 systematic-debugging skill 目錄**(含 refs),記 upstream SHA/日期/license,explicit trigger、視為受控 fork、每季 diff upstream。用 6 個真實 bug 驗收:無證據修補 -25%、首次修正成功率升、總 token 增幅 ≤15%。
- task-observer:三段式格式不是它的價值,價值在即時捕捉/去重/核准/propagation/rollback 閉環。做 **observer-lite**:不常駐,只在五種事件觸發(明確糾正、同任務重試 ≥2、驗收失敗、規則衝突、subagent 回報不合格);每筆含 Issue/Improvement/原則/Evidence/套用範圍/核准/30 天效果/rollback;每 session ≤3 筆、每月人工 review。停止條件:核准率 <30%、overhead >10%、rollback >20%。

Codex 補充的遺漏風險(擇要):hook 衝突(多 skill 搶 session/post-edit hooks)、資料治理(截圖/log 含 NDA 內容)、缺 owner(誰追 upstream、誰 review 抽取品質)、缺 efficacy review(教訓只累積不驗證有效性)、退出成本(PRODUCT.md/observer logs 變自建基礎設施)、官方 marketplace ≠ 安全審核。

Codex 總結:最該修的是**決策語言**。不要寫「抽概念進 docs」,要寫成「受控 fork」或「刻意降級的 observer-lite」,並列明被放棄的機制、owner、版本策略、停止條件。

## 兩邊共識

- superpowers 不裝整包。
- task-observer 不 always-on 安裝。
- impeccable 是最值得試的候選(分歧只在「直接裝」vs「detector-only pilot」)。
- find-skills 的 skill 本體不裝。

## 未決事項(帶去討論)

1. Codex 提的「先建 measurement baseline(task type/turns/token/採納率/rework)再試任何 skill」:對 Pro 個人使用者是否過重?最小可行版本長怎樣?
2. vendoring systematic-debugging:放 ai-rules repo 哪裡?owner/更新節奏怎麼定才不變成沒人追的死分支?
3. observer-lite 的五個觸發事件,跟現有教訓區/memory 的寫入規則怎麼合併,避免三軌記錄?
4. impeccable detector-only pilot 的執行細節:`npx impeccable detect` 是否也要 pin 版本?掃哪兩頁?
5. Codex 的驗收數字(precision 70%、-25% 等)是拍的,要不要調成可實際量測的版本?

## 來源

- find-skills: https://github.com/vercel-labs/skills
- impeccable: https://github.com/pbakaus/impeccable 、https://impeccable.style/docs/
- superpowers: https://github.com/obra/superpowers (官方 marketplace: `/plugin install superpowers@claude-plugins-official`)
- task-observer: https://github.com/rebelytics/one-skill-to-rule-them-all (勿裝 Carefree-1991 二手搬運版)
- 完整查證原稿在本機 scratchpad,已不可攜;本文件為權威版本。
