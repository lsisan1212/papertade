# papertade — Paper Trade Dashboard

`position-mgmt` 倉位管理框架 · 模擬盤（paper trade）策略績效儀表板。

**線上版：** https://lsisan1212.github.io/papertade/

## 功能

- 左側策略清單（可多選 / 按組切換），右側圖表
- **預設只顯示「最佳 N 個」（N 預設 5）**，避免一次畫 20+ 條線變亂。
  可切換排名依據：實盤累積報酬（預設）/ 回測 APY / 回測 NAV / 實盤 Sharpe / 實盤 APY(樣本)
- **圖表分三層，跟 Telegram 原裝圖表同款**：
  1. **淨值走勢**（全部已選，左軸）＋ 焦點帳戶**回撤 %**（右軸灰虛線）
  2. **倉位佔比**：多 / 空 / 閒置（佔帳戶淨值，堆疊面積，只畫焦點帳戶）
  3. **持幣數量**：多頭選幣 / 空頭選幣（只畫焦點帳戶）
- 「焦點帳戶」下拉＝下面兩個面板畫邊個（點側欄或點表列都會改焦點）
- 時間範圍：**近 30 天（預設）** / 全部 / 近 90 / 近 7 天；Y 軸：**淨值倍數 (log)**（預設）/ 淨值 %
- 每條線除顏色外**再用唔同線型**（實線 / 長虛線 / 短虛線 / 點劃線…共 10 種，按已選次序分配）→ 相近顏色都分得出
- 指標表（可排序、可點列只看單一策略），分兩組欄位：
  - **回測**（首次回測 2021–2026）：NAV、APY、MDD、Sharpe
  - **實盤**（模擬盤至今）：NAV、累積報酬、MDD、APY(樣本)、Sharpe、年化波動、
    當前回撤、費用+資金費、週轉(x)、平均槓桿、平均多空比、平均多/空持幣數、樣本天數
- 未開始跑的策略仍會列出（有回測數字、實盤欄顯示 `–`）

### 可直接用 URL 帶參數

```
?n=5              最佳幾個（1–23）
?by=bt_apy        排名依據：ret | bt_apy | bt_nav | sharpe | apy
?range=7          時間範圍：all | 90 | 30 | 7
?ymode=pct        Y 軸：log | pct
?focus=35m_f100_08_Yuwen   指定焦點帳戶
```
例：`https://lsisan1212.github.io/papertade/?n=5&range=7&focus=35m_f100_08_Yuwen`

> 顏色用中國慣例：**漲 = 紅、跌 = 綠**。
> ⚠️ **回測** 同 **實盤** 口徑唔同，唔可以直接比。

## 資料來源（唯讀）

```
~/Desktop/py/BN/Actual Trading/position-mgmt-papertrade/data/仓位管理回测结果/<帳戶>/资金曲线.csv
~/Desktop/py/BN/Actual Trading/logs/daily_papertrade.sh        ← ACCOUNTS（權威帳戶清單）
~/Desktop/py/BN/Actual Trading/logs/backtest_metrics.json      ← 首次回測指標（見下）
~/Desktop/py/BN/Actual Trading/position-mgmt-papertrade/accounts/<帳戶檔>.py   ← 策略描述
```

**回測指標**由 `~/Workbuddy/scripts/build_backtest_metrics.py` 產生，來源：
- `nf_*` → `~/WorkBuddy/2026-08-23-15-35-26/outputs/neutral/neutral_ranked.csv`（窗口 2021-01-01 ~ 2026-07-16）
- 原裝 2 個（`0m_2號氣泡固定5050` / `15m_2號氣泡填充`）→ accounts docstring（窗口 2021-01-01 ~ 2026-04-24）
- `f100_*` 10 個 → accounts docstring（窗口 2021-01-01 ~ 2026-06-05，跑在 bn-server position-mgmt v2.2.0）

改完帳戶或重跑回測後，重新產生一次：
```zsh
/opt/homebrew/Caskroom/miniforge/base/envs/alpha/bin/python \
  ~/Workbuddy/scripts/build_backtest_metrics.py --show
```

## 更新

```zsh
cd ~/Workbuddy/papertade-dashboard
./push.sh              # 重新產生資料 + commit + push
./push.sh --no-build   # 只 push
```

或分開跑：

```zsh
/opt/homebrew/Caskroom/miniforge/base/envs/alpha/bin/python build.py
/opt/homebrew/Caskroom/miniforge/base/envs/alpha/bin/python build.py --check   # 只檢查來源
```

自動更新：WorkBuddy automation（每日，papertrade 跑完之後）。

## 檔案

| 檔案 | 用途 |
|---|---|
| `build.py` | 讀框架輸出 → `data/strategies.json`（指標 + 回測）+ `data/equity.json`（曲線：nav/dd/多空比/槓桿/倉位佔比/持幣數） |
| `index.html` | 儀表板本體（單頁，Chart.js） |
| `vendor/chart.umd.min.js` | Chart.js 4.4.4（本地內嵌，唔靠 CDN） |
| `push.sh` | 產生 + push 一鍵 |
| `data/*.json` | 產生出嚟嘅資料（自動更新，唔使手改） |

曲線過長會自動抽稀（最近 720 點保留原解析度，之前等距抽樣），控制 `data/equity.json` 大小。

## 指標口徑

**實盤**
- `NAV` = 資金曲線 `净值` 最後一格（起始 1.0）
- `MDD` = `min(净值 / 累積峰值 − 1)`
- `APY(樣本)` = `NAV^(365/樣本天數) − 1` — **樣本短會嚴重放大，只宜排序比較，唔係預期年化**
- `Sharpe` = 小時報酬 mean/std × √(24×365)
- `avg_lev` / `avg_lsr` = `leverage_ratio` / `long_short_ratio` 平均值

**回測**（`backtest_metrics.json`）
- 直接取回測報告／帳戶 docstring 記錄嘅數字，未經重算
- `NAV` = 回測累積淨值倍數（例如 652,878 即 652,878×）

**倉位佔比（圖表第 2 層）**
- `多` = `long_pos_value / equity`、`空` = `|short_pos_value| / equity`
- `閒置` = `1 − 多 − 空`（下限 0）
- 已核實 `多 + 空 == leverage_ratio`（框架 `statistics_debug.py` 用「多头仓位/账户总净值」同一口徑；
  CSV 冇存 多头仓位 / 账户总净值，所以用 pos_value/equity 等價推算）

## 注意

- 帳戶清單以 `logs/daily_papertrade.sh` 的 `ACCOUNTS` 為準（`build.py` 會解析）。
- 淨值曲線含模擬盤本身的口徑，與回測數字唔可以直接比。
