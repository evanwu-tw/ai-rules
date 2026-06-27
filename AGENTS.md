# ai-rules 專案指引

- 這份檔案只是進入本 repo 工作時的薄入口，不是第二份規格。
- root `GENERATE.md` 是 agent-rules 生成行為的唯一權威；改規格就改它。
- `README.md` 說明五層分層模型與兩個 scope，供人閱讀。
- `docs/design-log.md` 是 append-only 決策紀錄；新增章節，不改寫舊決策。
- 遵守 canonical-per-table：同一張表或規則只存在一處，其餘文件用連結指過去。
- 保持此系統 repo 中立、可複用；不要加入個人資料、本機路徑或特定專案內容。
- 不重抄全域 role、tone 或通用協作規範；全域 agent guidance 會另外合併。
- 本系統只 compile Instruction 與 Context；不要把 Runtime、Memory、Workflow、hooks、skills 或 MCP 加成生成物。
- `templates/` 要保持 generic、可複用，不塞特定專案內容。
- 本 repo 是 markdown-only；不要編造 build、test 或 lint commands。
- 修改 root `GENERATE.md` 後，如需同步全域部署影本，請看 `README.md` 的「跨裝置部署」。
