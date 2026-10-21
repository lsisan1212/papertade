# Automation memory — papertrade-dashboard 每日更新

## 2026-10-21 06:40（首次執行）
- 結果：**失敗（無法執行）**。`~/Workbuddy/papertrade-dashboard/` 係**完全空目錄**，`run_daily.sh` / `build_dashboard.py` / `index.html` / `.git` 全部唔存在。
- 確認動作：全機 find + grep 都搵唔到 `build_dashboard*.py`；只有無關的 `~/Desktop/py/BN/Actual Trading/pm/run_daily.sh`（BMAC + pm startup/monitor/delist，無 dashboard 邏輯）。
- 資料源本身正常：`~/Library/Application Support/bnpapertrade/position-mgmt-papertrade/data/仓位管理回测结果/` 有 **32** 個帳戶，`资金曲线.csv` 最新 candle = 2026-10-20 19:00 UTC（澳門 10-21 03:00），含 `55m_pl_long2_neutral`。
- 網絡檢查：`https://lsisan1212.github.io/papertade/` → 200（正式版仍在線）；`https://lsisan1212.github.io/papertrade/` → 404。
- 判斷：本專案已被廢棄（kb `2026-10-20-22-17-57/kb/papertrade_framework/docs/08-dashboard.md` 已記錄 `run_daily.sh` 變 stub，remote `lsisan1212/papertrade` 404）。正式儀表板由 09:00 automation 更新。
- 未做：未自行建立腳本／圖表（按指示唔改口徑），top3 報酬無法提供。
- 下輪建議：先 check 目錄是否仍空；若 Pman 未重建，直接報「專案已廢棄」即可，唔需要再等 90 分鐘。

## 2026-10-22 06:40（第 2 次執行）
- 執行：**成功**。專案已於 10-21 07:04 重建，內容齊全（.git / build.py / push.sh / index.html / data / vendor）。
- 工具鏈修正（重要）：`run_daily.sh`、`build_dashboard.py` **都唔存在**。實際入口 = `./push.sh`（內部跑 `~/Workbuddy/scripts/build_backtest_metrics.py` → `build.py` → git commit + push）。前端係 **Chart.js**（非 Plotly），`index.html` 由 data/*.json 執行時載入，正常唔需要重建。
- 目錄實況：只有 `papertrade-dashboard`（有 T）一個目錄，但其內容 = `papertade`（無 T），remote = `lsisan1212/papertade.git`（HTTP 200，gh 已 auth 為 lsisan1212）。→ 任務書「近乎重複 / repo 404」的前提已不成立；`lsisan1212/papertrade` 本身仍 404，但本專案冇用佢。
- 結果：32/32 帳戶有資料，commit 22b6af3，push ✅，Pages 200。equity end 2026-10-21 19:00 UTC（澳門 10-22 03:00）。
- 執行時間僅 6 秒（數據 04:42–04:56 已由 papertrade 跑完），唔需要等 90 分鐘。下輪可直接跑 `./push.sh`（sandbox off + 背景），再讀 data/strategies.json 取 meta 與 top3。
