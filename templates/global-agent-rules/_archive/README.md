# 歸檔

一般任務不讀本目錄，歸檔內容不作現行指令。

- [history/](history/README.md)：追溯用的歷史文件，納入 Git。
- `backups/`：按日期或任務保存原檔及驗證紀錄，保留原相對路徑；由 Git 忽略，不隨 push 同步。只有恢復或查驗時讀。

生成中的 staging 依 `source/GENERATE.md` 放 workspace 外，驗證完成後才封存到 `backups/`。
