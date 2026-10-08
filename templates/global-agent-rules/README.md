# 全域 agent-rules 骨架

用私有部署 repo 同步全域規則。只維護 source，任一 agent 生成一次，兩平台共用同一份內容。

```text
agent-rules/
  install.sh
  AGENTS.md             # 共用生成本文
  CLAUDE.md             # generated banner + @AGENTS.md；保留原 manual
  .gitignore            # 排除 _archive/backups/ 與暫存備份
  source/               # 常駐 core，唯一生成來源
    GENERATE.md         # 複製系統 repo 的生成規格
    00-role.md
    10-tone.md
    20-work-dispatch.md # 工作原則 + 何時讀哪份 Ops
  docs/ops/             # 按需操作文件，手寫維護，不生成
    10-dispatch.md
    20-maintenance.md
  _archive/             # 歷史與備份，一般任務不讀
    history/            # 納入 Git
    backups/            # Git 忽略
  skills/               # 選配，不是生成來源
  tests/                # 選配，skills 腳本的測試
```

## 三層內容

| 層 | 位置 | 何時載入 | 怎麼維護 |
|---|---|---|---|
| 常駐 core | `source/` 頂層 `.md` | 每次對話，經生成進 `AGENTS.md` | 改 source 再生成 |
| 按需 Ops | `docs/ops/` | core 的「需要時才讀」觸發命中時 | 直接改，不經生成 |
| 歷史 | `_archive/history/` | 只在追溯決策時 | append-only |

- 全域 source 僅允許頂層 core，不生成 `agent-context/`。按需細節放 `docs/ops/`，由 core 用完整路徑寫明「什麼情況讀哪一節」。連結不會自動載入，觸發條件要寫清楚。
- 同一條規則只維護一處：core 放原則與觸發，Ops 放詳細條件，不互抄。
- output 必須在部署 repo 第一層，避免重生時被當成 source。`docs/`、`_archive/`、`skills/`、`tests/` 都不是 source。完整生成與保護規則以系統 [GENERATE.md](../../GENERATE.md) 為準。

## 第一次設定

1. 把此骨架複製到自己的私有部署 repo，並將系統 `GENERATE.md` 複製至 `source/GENERATE.md`。
2. 填好 `source/` 的三份 core，視需要補 `docs/ops/` 的章節；用不到的 placeholder 刪掉。
3. 請任一 agent 依 `source/GENERATE.md` 生成全域設定。一次產出 repo 第一層的共用 `AGENTS.md` 與 Claude 引用入口；不要經平台 symlink 寫入，也不用另一個 agent 再生成一次。
4. 執行 `bash install.sh`，建立以下三個連結：

| 平台位置 | 部署 repo 目標 |
|---|---|
| `~/.codex/AGENTS.md` | `AGENTS.md` |
| `~/.claude/AGENTS.md` | `AGENTS.md` |
| `~/.claude/CLAUDE.md` | `CLAUDE.md` |

Claude 目錄內的共用連結確保相對 import 可解析。被替換的檔案或連結保存在 `~/.agent-rules-backups/`；核心連結安裝失敗會嘗試恢復並回報。選配 skills 的既有部署流程不屬於此核心交易。

- `bash install.sh --rules-only`：只部署上述連結，不動 skills。
- `bash install.sh --target-home /path/to/test-home --rules-only`：在指定目錄測試，不改 `HOME`。
- skill 的 frontmatter 可加 `hosts: claude` 或 `hosts: codex`，只部署給指定平台；沒寫就兩邊都部署。跨模型呼叫類 skill（Claude 叫 Codex review）適合用它，避免被呼叫方自己看到。
- 設定 `AI_RULES_SPEC=<系統 repo>/GENERATE.md` 後，安裝器會比對 `source/GENERATE.md`，不一致只警告、不覆蓋。

## 跨裝置與日常維護

同步私有部署 repo 到其他裝置後執行安裝器，不必重新生成。首次改用 import 時，各裝置都要重跑一次安裝器。

平常修改 source，再由任一 agent 生成與驗收；`docs/ops/` 直接改，不需重生，流程依 `docs/ops/20-maintenance.md`。提交並同步私有 repo 後，其他裝置 pull 即取得相同本文。`@import` 省下重複維護，不減少載入本文的 token。

已有 targeting 或 manual 的部署先依生成規格遷移，不能直接丟掉差異。更新 `source/GENERATE.md` 前先比較並保留部署端安全要求。平台專屬規範依生成規格 §4 手動設定，有實際差異才新增。
