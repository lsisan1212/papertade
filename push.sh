#!/bin/zsh
# 重新產生資料並 push 去 GitHub（給 automation / 手動用）
#
# 用法：
#   ./push.sh            # 產生 + commit + push
#   ./push.sh --no-build # 只 commit + push（資料已產生好）
set -u
cd "$(dirname "$0")"

PY="/opt/homebrew/Caskroom/miniforge/base/envs/alpha/bin/python"
BT="/Users/leongsisan/Workbuddy/scripts/build_backtest_metrics.py"
REPO_URL="https://github.com/lsisan1212/papertade.git"
BRANCH="main"

if [[ "${1:-}" != "--no-build" ]]; then
  # 首次回測指標（由 accounts docstring + neutral_ranked.csv 抽）— 帳戶有變時才會唔同
  if [[ -f "$BT" ]]; then
    echo "== 更新回測指標 =="
    "$PY" "$BT" || echo "（回測指標更新失敗，沿用舊檔）"
  fi
  echo "== 產生資料 =="
  "$PY" build.py || { echo "build.py 失敗，中止"; exit 1; }
fi

echo "== git =="
if [[ ! -d .git ]]; then
  git init -q
  git branch -M "$BRANCH"
  git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
fi

STAMP="$(date '+%Y-%m-%d %H:%M')"
git add -A
if git diff --cached --quiet; then
  echo "無變動，唔需要 commit。"
  exit 0
fi
git -c user.name="papertade-bot" -c user.email="papertade-bot@users.noreply.github.com" \
    commit -q -m "data: update equity curves @ ${STAMP}"
echo "已 commit：$(git log -1 --format='%h %s')"

echo "== push =="
git push -q -u origin "$BRANCH" && echo "✅ push 完成 → ${REPO_URL}" || { echo "❌ push 失敗"; exit 1; }
