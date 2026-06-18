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
- [ ] 步驟 3：乾淨部署全域 `~/agent-rules`（只放 role/tone + GENERATE.md），填內容，跑第一次生成 `~/.claude/CLAUDE.md` 驗證整套運作
- [ ] 部署時**實測 symlink**：確認 Claude Code / Codex 真的會跟隨 symlink 讀 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md`
- [ ] 建 `~/agent-rules` 私有 repo + `install.sh`（新裝置 clone + symlink）
- [ ] 視需要補 `CHANGELOG.md`（迭代回路記理由用）
- [ ] 確認 §2 引用的平台大小數字（Codex AGENTS.md 上限、Claude CLAUDE.md 行數建議）對到最新官方文件

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
