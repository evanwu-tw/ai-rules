# 全域 agent-rules 骨架

這個資料夾是**全域部署 repo** 的骨架。部署後，`~/agent-rules` 是一個**私有 git repo**，跨裝置同步你的全域 agent 設定。

## 佈局

```
~/agent-rules/              # 私有 git repo（部署殼）
  install.sh               # 建立 symlink 的部署器
  CLAUDE.md               # 生成 output（symlink target）← 第一層
  AGENTS.md              # 生成 output（symlink target）← 第一層
  source/                  # source root（core-only、扁平）
    GENERATE.md           # 從本系統根目錄複製過來；全域的生成指令即此檔
    role.md               # core：我是誰、角色設定
    tone.md               # core：通用 AI 語氣與產出規範
  .gitignore
```

> **為什麼 source 要收進 `source/`、output 放第一層？**
> 全域 generator 把 source root 頂層的 `.md` 都當 core 內嵌。若 output（`CLAUDE.md`/`AGENTS.md`）和 source 同層，重生會把舊 output 當 core 又塞回去 → 自我參照污染。所以 source 收進 `source/`（generator 只讀這裡），第一層只放 output 與部署檔。
>
> **全域 = core-only：`source/` 內不放子資料夾。** 全域 output 以 symlink 跨裝置同步，根檔指向子資料夾的相對路徑在 symlink 下不穩；按需材料（wiki/reference 等）只用在專案 scope。

## 第一次設定（來源裝置）

1. 把本資料夾內容複製到 `~/agent-rules/`，並把系統根目錄的 `GENERATE.md` 複製到 `~/agent-rules/source/GENERATE.md`。
2. 填好 `source/role.md`、`source/tone.md`。
3. 叫 agent 生成（**指令路徑指向 `source/`**）：
   > 「依 `~/agent-rules/source/GENERATE.md` 生成全域設定檔。」
   - 用 Claude → 產出 `~/.claude/CLAUDE.md`
   - 用 Codex → 產出 `~/.codex/AGENTS.md`
4. 跑 `~/agent-rules/install.sh`，把 output symlink 到 `~/.claude/`、`~/.codex/`。
5. `git init` → commit → push 到你的**私有** remote（例 `git@github.com:<you>/agent-rules.git`）。

## 換裝置 / 新裝置（一鍵）

```sh
git clone git@github.com:<you>/agent-rules.git ~/agent-rules && ~/agent-rules/install.sh
```

完成，**不需重生**。

## 日常同步

- 改了設定 → 在來源裝置重生（指向 `~/agent-rules/source/GENERATE.md`）→ `git commit && git push`。
- 其他裝置 → `git pull`，symlink 自動跟隨，立即生效。

> **caveat**：重生時 generator 寫 `~/.claude/CLAUDE.md`（symlink → repo 第一層）。多數寫入會保留 symlink；若某次把 symlink 換成實體檔，repo 第一層不會更新。重生後 `git status` 檢查，必要時把實體檔內容移回第一層、重跑 `install.sh`。

全域只放非常 general 的東西（角色、語氣、產出規範），通常設定一次後極少再動。
