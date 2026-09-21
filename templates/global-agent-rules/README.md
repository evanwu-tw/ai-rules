# 全域 agent-rules 骨架

用私有部署 repo 同步全域規則。只維護 source，任一 agent 生成一次，兩平台共用同一份內容。

```text
agent-rules/
  install.sh
  AGENTS.md             # 共用生成本文
  CLAUDE.md             # generated banner + @AGENTS.md；保留原 manual
  source/
    GENERATE.md         # 複製系統 repo 的生成規格
    role.md
    tone.md
  skills/               # 選配，不是生成來源
```

全域 source 僅允許頂層 core。output 必須在部署 repo 第一層，避免重生時被當成 source。完整生成與保護規則以系統 [GENERATE.md](../../GENERATE.md) 為準。

## 第一次設定

1. 把此骨架複製到自己的私有部署 repo，並將系統 `GENERATE.md` 複製至 `source/GENERATE.md`。
2. 填好 `source/role.md`、`source/tone.md`。
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

## 跨裝置與日常維護

同步私有部署 repo 到其他裝置後執行安裝器，不必重新生成。首次改用 import 時，各裝置都要重跑一次安裝器。

平常修改 source，再由任一 agent 生成與驗收。提交並同步私有 repo 後，其他裝置 pull 即取得相同本文。`@import` 省下重複維護，不減少載入本文的 token。

已有 targeting 或 manual 的部署先依生成規格遷移，不能直接丟掉差異。更新 `source/GENERATE.md` 前先比較並保留部署端安全要求。平台專屬規範依生成規格 §4 手動設定，有實際差異才新增。
