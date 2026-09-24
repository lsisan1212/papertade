#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
papertade dashboard — 資料產生器

讀取 position-mgmt-papertrade 框架每個帳戶的「资金曲线.csv」，
計出 NAV / MDD / APY / Sharpe / 費用 / 多空比 / 槓桿 等指標，
輸出 web 用的 data/strategies.json 與 data/equity.json。

來源（唯讀）：
  <PMT>/data/仓位管理回测结果/<帳戶名>/资金曲线.csv
  <LOGS>/daily_papertrade.sh        ← ACCOUNTS 清單（權威：邊啲帳戶正跑）
  <PMT>/accounts/<帳戶檔>.py        ← strategy_name / docstring 描述

用法：
  python build.py                # 產生 JSON
  python build.py --check        # 只檢查來源，唔寫檔
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------- 路徑

HOME = Path.home()
BASE = HOME / "Desktop/py/BN/Actual Trading"
PMT = BASE / "position-mgmt-papertrade"
LOGS = BASE / "logs"
RUNNER = LOGS / "daily_papertrade.sh"
EQUITY_ROOT = PMT / "data/仓位管理回测结果"
ACCOUNTS_DIR = PMT / "accounts"
BT_PATH = LOGS / "backtest_metrics.json"       # 首次回測指標（2021–2026）

OUT_DIR = Path(__file__).resolve().parent
DATA_DIR = OUT_DIR / "data"

# 分組（顯示用）
GROUP_LABEL = {
    "orig": "原裝",
    "nf": "多空中性 nf_*",
    "f100": "論壇 f100",
    "other": "其他",
}


# ---------------------------------------------------------------- 讀 ACCOUNTS

_ACC_RE = re.compile(r'^\s*"(-?\d+)\|(\d+)\|([^|]+)\|([^"]*)"\s*$')


def read_accounts() -> list[dict]:
    """由 daily_papertrade.sh 抽 ACCOUNTS（權威清單）。"""
    if not RUNNER.exists():
        return []
    out: list[dict] = []
    inside = False
    for line in RUNNER.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.strip().startswith("ACCOUNTS=("):
            inside = True
            continue
        if inside:
            if line.strip() == ")":
                break
            m = _ACC_RE.match(line)
            if m:
                out.append({
                    "hour_delta": int(m.group(1)),
                    "offset_min": int(m.group(2)),
                    "file": m.group(3),
                    "name": m.group(4),
                })
    return out


def classify(name: str) -> str:
    if "f100" in name:
        return "f100"
    if "nf_" in name:
        return "nf"
    if "氣泡" in name:
        return "orig"
    return "other"


def account_desc(acc_file: str, name: str) -> dict:
    """由 accounts/<file>.py 抽 strategy_name + docstring 描述行。"""
    info = {"strategy_name": "", "desc": []}
    p = ACCOUNTS_DIR / acc_file
    if not p.exists():
        return info
    try:
        txt = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return info
    m = re.search(r"^strategy_name\s*=\s*['\"]([^'\"]+)['\"]", txt, re.M)
    if m:
        info["strategy_name"] = m.group(1)
    dm = re.search(r'^"""\n(.*?)\n"""', txt, re.S | re.M)
    if dm:
        for ln in dm.group(1).splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("⚠️"):
                continue
            info["desc"].append(ln)
        info["desc"] = info["desc"][:6]
    return info


def load_backtest() -> dict:
    """讀首次回測指標表（由 ~/Workbuddy/scripts/build_backtest_metrics.py 產生）。"""
    if not BT_PATH.exists():
        print(f"⚠️ 找不到 {BT_PATH}（回測欄會留空）")
        return {}
    try:
        d = json.loads(BT_PATH.read_text(encoding="utf-8"))
        return d.get("accounts", {}) or {}
    except Exception as e:
        print(f"⚠️ 讀取 backtest_metrics.json 失敗: {e}")
        return {}


# ---------------------------------------------------------------- 指標

def _safe(x, nd=6):
    try:
        f = float(x)
    except Exception:
        return None
    if math.isnan(f) or math.isinf(f):
        return None
    return round(f, nd)


def round_list(seq, nd):
    out = []
    for v in seq:
        f = float(v)
        if math.isnan(f) or math.isinf(f):
            out.append(None)
        else:
            out.append(round(f, nd))
    return out


def decimate(series: dict, max_total: int = 4000, keep_tail: int = 720) -> dict:
    """曲線太長就抽稀：最近 keep_tail 點保持原解析度，之前的部分等距抽樣。

    json 大細直接影響載入速度；單一策略 11,000+ 點（493 天）冇必要全部傳。
    """
    n = len(series.get("dt") or [])
    if n <= max_total:
        return series
    keep_idx = set(range(max(0, n - keep_tail), n))
    head_n = max(0, n - keep_tail)
    budget = max(1, max_total - len(keep_idx))
    if head_n <= budget:
        keep_idx |= set(range(head_n))
    else:
        stride = math.ceil(head_n / budget)
        keep_idx |= set(range(0, head_n, stride))
    idx = sorted(keep_idx)
    out = {"decimated": True, "full_bars": n, "kept": len(idx)}
    for k, v in series.items():
        if isinstance(v, list) and len(v) == n:
            out[k] = [v[i] for i in idx]
        else:
            out[k] = v
    return out


def load_equity(path: Path) -> pd.DataFrame | None:
    try:
        df = pd.read_csv(path, encoding="utf-8-sig")
    except Exception:
        return None
    if "candle_begin_time" not in df.columns or "净值" not in df.columns:
        return None
    df["candle_begin_time"] = pd.to_datetime(df["candle_begin_time"], utc=True, errors="coerce")
    df = df.dropna(subset=["candle_begin_time", "净值"]).sort_values("candle_begin_time")
    df = df.reset_index(drop=True)
    return df if len(df) else None


def compute(df: pd.DataFrame) -> dict:
    nav = df["净值"].astype(float)
    n = len(nav)
    first_t = df["candle_begin_time"].iloc[0]
    last_t = df["candle_begin_time"].iloc[-1]
    days = max((last_t - first_t).total_seconds() / 86400.0, 1e-9)
    nav_last = float(nav.iloc[-1])

    cummax = nav.cummax()
    dd = nav / cummax - 1.0
    mdd = float(dd.min())

    ret = nav.pct_change().dropna()
    vol_h = float(ret.std()) if len(ret) > 1 else float("nan")
    vol_ann = vol_h * math.sqrt(24 * 365)
    sharpe = (float(ret.mean()) / vol_h * math.sqrt(24 * 365)) if vol_h and vol_h > 0 else float("nan")

    apy = nav_last ** (365.0 / days) - 1.0 if nav_last > 0 else -1.0

    def col_sum(c):
        return float(df[c].sum()) if c in df.columns else 0.0

    init = 10000.0
    fee = col_sum("fee")
    funding = col_sum("funding_fee")
    turnover = col_sum("turnover")

    def col_mean(c):
        return float(df[c].mean()) if c in df.columns else float("nan")

    liq = 0
    if "是否爆仓" in df.columns:
        try:
            liq = int((df["是否爆仓"].astype(float) > 0).sum())
        except Exception:
            liq = 0

    metrics = {
        "start": first_t.strftime("%Y-%m-%d %H:%M"),
        "end": last_t.strftime("%Y-%m-%d %H:%M"),
        "days": round(days, 1),
        "bars": n,
        "nav": _safe(nav_last),
        "total_return": _safe(nav_last - 1.0),
        "cagr_on_sample": _safe(apy),
        "mdd": _safe(mdd),
        "vol_ann": _safe(vol_ann),
        "sharpe": _safe(sharpe),
        "fee_usdt": _safe(fee, 2),
        "funding_usdt": _safe(funding, 2),
        "cost_usdt": _safe(fee + funding, 2),
        "cost_pct_init": _safe((fee + funding) / init),
        "turnover_usdt": _safe(turnover, 2),
        "turnover_x": _safe(turnover / init, 2),
        "avg_lsr": _safe(col_mean("long_short_ratio"), 4),
        "avg_lev": _safe(col_mean("leverage_ratio"), 4),
        "avg_longs": _safe(col_mean("symbol_long_num"), 1),
        "avg_shorts": _safe(col_mean("symbol_short_num"), 1),
        "liq_bars": liq,
        "nav_peak": _safe(float(cummax.iloc[-1])),
        "dd_now": _safe(float(dd.iloc[-1])),
    }

    # 小時偏移（由 t0 起算）＋序列
    t0 = int(first_t.timestamp())
    dt_h = [int(round((t - first_t).total_seconds() / 3600.0)) for t in df["candle_begin_time"]]

    # 倉位佔比（給「多 / 空 / 閒置」堆疊面積圖用）
    #   框架 statistics_debug.py 用 多头仓位/账户总净值、空头仓位/账户总净值、leverage - 兩者，
    #   但 CSV 只存 long_pos_value / short_pos_value / equity → 等價推算（已核實 lr+sr == leverage_ratio）。
    #   閒置 = 1 - 多 - 空（下限 0）；即假設槓桿上限 1（FixedRatioStrategy cap_ratios=[1]）。
    lr = sr = er = None
    if {"long_pos_value", "short_pos_value", "equity"} <= set(df.columns):
        eqv = df["equity"].astype(float).replace(0.0, float("nan"))
        lr = (df["long_pos_value"].astype(float) / eqv).fillna(0.0)
        sr = (df["short_pos_value"].astype(float).abs() / eqv).fillna(0.0)
        er = (1.0 - lr - sr).clip(lower=0.0)

    series = {
        "t0": t0,
        "dt": dt_h,
        "nav": round_list(nav, 5),
        "dd": round_list(dd, 5),
        "lsr": round_list(df["long_short_ratio"], 3) if "long_short_ratio" in df.columns else [],
        "lev": round_list(df["leverage_ratio"], 3) if "leverage_ratio" in df.columns else [],
        "nl": [int(x) for x in df["symbol_long_num"]] if "symbol_long_num" in df.columns else [],
        "ns": [int(x) for x in df["symbol_short_num"]] if "symbol_short_num" in df.columns else [],
    }
    if lr is not None:
        series["lr"] = round_list(lr, 4)
        series["sr"] = round_list(sr, 4)
        series["er"] = round_list(er, 4)
    return {"metrics": metrics, "series": series}


# ---------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只檢查來源，唔寫檔")
    args = ap.parse_args()

    accounts = read_accounts()
    bt_table = load_backtest()
    print(f"ACCOUNTS（runner）: {len(accounts)} 個")
    print(f"回測指標表        : {len(bt_table)} 個帳戶")
    print(f"EQUITY_ROOT       : {EQUITY_ROOT}")
    print(f"exists            : {EQUITY_ROOT.exists()}")

    strategies = []
    equity = {}
    skipped = []

    for a in accounts:
        name = a["name"]
        csv = EQUITY_ROOT / name / "资金曲线.csv"
        meta = account_desc(a["file"], name)
        bt = bt_table.get(name) or {}
        base = {
            "id": name,
            "label": name,
            "group": classify(name),
            "group_label": GROUP_LABEL[classify(name)],
            "file": a["file"],
            "offset_min": a["offset_min"],
            "time": f"{6 + a['hour_delta']:02d}:{a['offset_min']:02d}",
            "strategy_name": meta["strategy_name"],
            "desc": meta["desc"],
            "backtest": bt if bt.get("status") == "ok" else None,
        }
        if not csv.exists():
            base["status"] = "pending"
            base["metrics"] = None
            strategies.append(base)
            skipped.append(name)
            continue
        df = load_equity(csv)
        if df is None:
            base["status"] = "error"
            base["metrics"] = None
            strategies.append(base)
            skipped.append(name + " (讀取失敗)")
            continue
        got = compute(df)
        base["status"] = "ok"
        base["metrics"] = got["metrics"]
        strategies.append(base)
        equity[name] = decimate(got["series"])
        print(f"  ✓ {name:<34} bars={got['metrics']['bars']:<5} "
              f"NAV={got['metrics']['nav']:.4f} MDD={got['metrics']['mdd']*100:6.2f}% "
              f"APY={got['metrics']['cagr_on_sample']*100:9.1f}%")

    if skipped:
        print(f"\n無資料（未跑過 / 讀取失敗）: {len(skipped)}")
        for s in skipped:
            print(f"  · {s}")

    now = datetime.now(timezone.utc)
    meta = {
        "generated_at": now.astimezone().strftime("%Y-%m-%d %H:%M:%S %z"),
        "generated_ts": int(now.timestamp()),
        "source": str(EQUITY_ROOT),
        "backtest_source": str(BT_PATH),
        "n_accounts": len(accounts),
        "n_with_data": len(equity),
        "n_with_backtest": sum(1 for s in strategies if s.get("backtest")),
        "runner": str(RUNNER),
        "note": "實盤淨值來自框架輸出 data/仓位管理回测结果/<帳戶>/资金曲线.csv；"
                "回測欄來自 accounts docstring + neutral_ranked.csv（2021–2026 首次回測），"
                "兩者口徑唔同，唔可以直接比。APY(樣本) 為樣本外推到 365 天，樣本短會嚴重放大，只宜排序。",
    }

    if args.check:
        print("\n--check：唔寫檔。")
        return 0

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    (DATA_DIR / "strategies.json").write_text(
        json.dumps({"meta": meta, "strategies": strategies}, ensure_ascii=False, indent=1),
        encoding="utf-8",
    )
    (DATA_DIR / "equity.json").write_text(
        json.dumps({"meta": meta, "equity": equity}, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    s1 = (DATA_DIR / "strategies.json").stat().st_size
    s2 = (DATA_DIR / "equity.json").stat().st_size
    print(f"\n寫出：data/strategies.json {s1/1024:.1f} KB、data/equity.json {s2/1024:.1f} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
