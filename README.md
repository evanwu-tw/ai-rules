# agent-rules

讓 Claude Code 與 Codex 共用規則。**新的一般專案直接維護 `AGENTS.md`，`CLAUDE.md` 引用它，不必生成兩份規則。**

## 一般專案：兩個檔案就開始

1. 將 [templates/project/](templates/project/) 裡的兩個檔案放到專案根目錄，填入專案目標、實際驗證方式與重要約定，刪掉未使用的 placeholder。
2. 日常只改 `AGENTS.md`；詳細資料連到既有文件，寫明「處理什麼事情時讀」。不必另外複製到 `agent-context/`。
3. 不重抄全域偏好，不加入 agent 能從專案直接看出的通則。既有檔先比較，不用模板覆蓋；已有 generated banner 或生成流程的專案繼續使用下方生成模式。

```text
專案/
  AGENTS.md     # 共用規則原稿，直接修改
  CLAUDE.md     # 一行 @AGENTS.md
  docs/         # 可選，沿用既有詳細資料
```

`@AGENTS.md` 會把共用規則載入 Claude 的 context，省的是維護兩份規則的工作，不是 token。按需文件用一般 Markdown 連結；兩平台的載入行為見 [Claude 官方文件](https://code.claude.com/docs/en/memory#agentsmd)與 [OpenAI 官方文件](https://learn.chatgpt.com/docs/agent-configuration/agents-md)（查閱：2026-09-15）。

本 repo 自己的 `AGENTS.md` / `CLAUDE.md` 就使用這個方式。它們不是生成副本，直接維護的 `AGENTS.md` 本身就是原稿。

## 全域與既有專案：生成模式

已有獨立 source、manual 區塊或部署流程時，保留生成模式。**只改 source，再生成；不從輸出反向回灌，也不自動改成直接維護。** 轉換既有專案須另外確認 source、manual 與所有平台專屬內容的去處。

- **建立全域規則**：使用 [global-agent-rules 模板](templates/global-agent-rules/README.md)，填入全域 source，再依其生成與部署流程設定。
- **建立需生成的專案**：使用 [project-agent-rules 模板](templates/project-agent-rules/generate.md)，複製成專案的 `agent-rules/`；把本 repo 的 `GENERATE.md` 以指定 commit 鎖版為 `GENERATE.vendored.md`，依 `generate.md` 執行。
- **只生成一次**：任一 agent 產出共用 `AGENTS.md` 與 Claude import 入口。舊 targeting 須先遷移；既有鎖版專案不自動更新。
- **修改與驗收**：source 佈局、scope、平台差異、manual 保留與 checklist 只以 [GENERATE.md](GENERATE.md) 為準。一般專案不需要讀它。

## 跨裝置部署

這一節適用全域生成模式。個人資料留在私有部署 repo，本系統 repo 保持中立。

- 部署 repo 的 `source/` 放規則原稿與生成規格，repo 第一層放共用 output、Claude 入口及 `install.sh`；output 不放進 source。
- `install.sh` 將共用檔連到 `~/.codex/AGENTS.md`、`~/.claude/AGENTS.md`，入口連到 `~/.claude/CLAUDE.md`。首次遷移時，各裝置重跑安裝器；只更新規則用 `--rules-only`。選配 skills 由安裝器處理，generator 不讀。
- 來源裝置改 source、生成並同步 Git；其他裝置 pull 即取得 outputs，不必各自重生。第一次 clone 與安裝步驟見 [全域模板](templates/global-agent-rules/README.md)。
- 更新生成規格前先比較部署版，不可覆蓋部署端新增的 snapshot、寫入 gate 或失敗恢復；專案 vendored 版本另行更新。
- 專案的規則與相關文件隨專案 Git 同步，不需要全域安裝器。

## 設定分層（五層模型）

這是參考分類，不是使用前必讀步驟。生成模式只產出前兩層；其他能力依各平台設定，安裝與載入位置不由 generator 管理。

| Layer | 本系統 | Claude | Codex |
|---|---|---|---|
| Instruction（常駐指令） | 提供模板；生成模式可產出 | `CLAUDE.md` | `AGENTS.md` |
| Context（按需 / 路徑範圍） | 直接連既有資料；生成模式產出 `agent-context/` | 一般連結；手動 `.claude/rules/` | 一般連結；手動 nested `AGENTS.md` / `AGENTS.override.md` |
| Runtime（權限 / hook） | 不生成 | 平台設定 | 平台設定與 execpolicy rules |
| Memory（累積學習） | 不生成，不作生成來源 | 平台 memory | 平台 memory |
| Workflow（可重複能力） | 不生成 | skills / commands / plugins | skills / plugins |

Claude glob 與 Codex 目錄分層不是同一機制；Codex execpolicy rules 也不是 Claude `.claude/rules/`。生成模式的放置表與差異只維護在 [GENERATE.md](GENERATE.md) §0、§4。

## 檔案

- [templates/project/](templates/project/)：一般專案的預設入口。
- [GENERATE.md](GENERATE.md)：生成模式的唯一規格。
- [templates/project-agent-rules/](templates/project-agent-rules/) 與 [templates/global-agent-rules/](templates/global-agent-rules/)：既有生成模式的模板。
- [docs/design-log.md](docs/design-log.md)：歷史決策，append-only；不作日常指令入口。
