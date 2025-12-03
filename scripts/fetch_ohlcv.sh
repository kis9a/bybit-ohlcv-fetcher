#!/bin/bash
set -euo pipefail

# デフォルト値
SYMBOL=""
TIMEFRAME="1h"
PERIOD="6months"
OUTPUT=""
LIMIT=1000
DELAY=2

# ヘルプ表示
show_help() {
  cat << EOF
Usage: $0 [OPTIONS]

Required:
  -s, --symbol SYMBOL        Trading pair (e.g., BTC/USDT)

Options:
  -t, --timeframe TIMEFRAME  Timeframe (default: 1h)
                            Supported: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d, 1w
  -p, --period PERIOD        Period (default: 6months)
                            Format: Nmonths, Nyear, Ndays, Nweeks
                            Examples: 6months, 1year, 30days, 90days
  -o, --output FILE          Output filename (auto-generated if not specified)
  -l, --limit LIMIT          Fetch limit per request (default: 1000, max: 1000)
  -d, --delay SECONDS        Delay between API calls (default: 2)
  -h, --help                 Show this help

Examples:
  # Default (BTC/USDT 1h 6months)
  $0 -s "BTC/USDT"

  # ETH/USDT 15m 3months
  $0 -s "ETH/USDT" -t 15m -p 3months

  # BTC/USDT 5m 30days
  $0 -s "BTC/USDT" -t 5m -p 30days

  # BTC/USDT 1d 1year with custom output
  $0 -s "BTC/USDT" -t 1d -p 1year -o btc_daily.csv
EOF
}

# 時間足を秒数に変換
timeframe_to_seconds() {
  case "$1" in
    1m) echo 60 ;;
    3m) echo 180 ;;
    5m) echo 300 ;;
    15m) echo 900 ;;
    30m) echo 1800 ;;
    1h) echo 3600 ;;
    2h) echo 7200 ;;
    4h) echo 14400 ;;
    6h) echo 21600 ;;
    12h) echo 43200 ;;
    1d) echo 86400 ;;
    1w) echo 604800 ;;
    *) echo "Error: Invalid timeframe: $1" >&2; exit 1 ;;
  esac
}

# 期間を日数に変換
period_to_days() {
  local period="$1"
  if [[ "$period" =~ ^([0-9]+)months?$ ]]; then
    echo $((${BASH_REMATCH[1]} * 30))
  elif [[ "$period" =~ ^([0-9]+)years?$ ]]; then
    echo $((${BASH_REMATCH[1]} * 365))
  elif [[ "$period" =~ ^([0-9]+)days?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$period" =~ ^([0-9]+)weeks?$ ]]; then
    echo $((${BASH_REMATCH[1]} * 7))
  elif [[ "$period" =~ ^[0-9]+$ ]]; then
    echo "$period"
  else
    echo "Error: Invalid period format: $period" >&2
    exit 1
  fi
}

# 引数解析
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--symbol) SYMBOL="$2"; shift 2 ;;
    -t|--timeframe) TIMEFRAME="$2"; shift 2 ;;
    -p|--period) PERIOD="$2"; shift 2 ;;
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -l|--limit) LIMIT="$2"; shift 2 ;;
    -d|--delay) DELAY="$2"; shift 2 ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $1" >&2; show_help; exit 1 ;;
  esac
done

# 必須パラメーターチェック
if [ -z "$SYMBOL" ]; then
  echo "Error: -s/--symbol is required" >&2
  show_help
  exit 1
fi

# 計算
TIMEFRAME_SECONDS=$(timeframe_to_seconds "$TIMEFRAME")
PERIOD_DAYS=$(period_to_days "$PERIOD")
TOTAL_SECONDS=$((PERIOD_DAYS * 86400))
TOTAL_POINTS=$((TOTAL_SECONDS / TIMEFRAME_SECONDS))
NUM_BATCHES=$(( (TOTAL_POINTS + LIMIT - 1) / LIMIT ))

# 出力ファイル名生成
if [ -z "$OUTPUT" ]; then
  SYMBOL_CLEAN=$(echo "$SYMBOL" | tr '/' '_' | tr '[:upper:]' '[:lower:]')
  OUTPUT="${SYMBOL_CLEAN}_${TIMEFRAME}_${PERIOD}.csv"
fi

# 開始日時計算（macOS対応）
if date --version >/dev/null 2>&1; then
  # GNU date (Linux)
  START_DATE=$(date -u -d "$PERIOD_DAYS days ago" "+%Y-%m-%dT%H:%M:%SZ")
else
  # BSD date (macOS)
  START_DATE=$(date -u -v-${PERIOD_DAYS}d "+%Y-%m-%dT%H:%M:%SZ")
fi

# 情報表示
cat << EOF
=================================================
Symbol: $SYMBOL
Timeframe: $TIMEFRAME
Period: $PERIOD ($PERIOD_DAYS days)
Start date: $START_DATE
Estimated data points: $TOTAL_POINTS
Required batches: $NUM_BATCHES
Limit per batch: $LIMIT
Delay between calls: ${DELAY}s
Output: $OUTPUT
=================================================
EOF

# 既存ファイル削除
rm -f "$OUTPUT"

# データ取得ループ
for ((i=0; i<NUM_BATCHES; i++)); do
  OFFSET_SECONDS=$((i * LIMIT * TIMEFRAME_SECONDS))

  # 日時計算（macOS/Linux対応）
  if date --version >/dev/null 2>&1; then
    # GNU date
    FETCH_DATE=$(date -u -d "$START_DATE $OFFSET_SECONDS seconds" "+%Y-%m-%dT%H:%M:%SZ")
  else
    # BSD date
    START_TIMESTAMP=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$START_DATE" "+%s")
    FETCH_TIMESTAMP=$((START_TIMESTAMP + OFFSET_SECONDS))
    FETCH_DATE=$(date -u -r "$FETCH_TIMESTAMP" "+%Y-%m-%dT%H:%M:%SZ")
  fi

  echo "Fetching batch $((i+1))/$NUM_BATCHES: $FETCH_DATE..."

  # データ取得
  if [ $i -eq 0 ]; then
    ./ohlcv -symbol "$SYMBOL" -timeframe "$TIMEFRAME" -since "$FETCH_DATE" -limit "$LIMIT" >> "$OUTPUT"
  else
    ./ohlcv -symbol "$SYMBOL" -timeframe "$TIMEFRAME" -since "$FETCH_DATE" -limit "$LIMIT" | tail -n +2 >> "$OUTPUT"
  fi

  # レート制限対策
  if [ $i -lt $((NUM_BATCHES - 1)) ]; then
    sleep "$DELAY"
  fi
done

# 完了メッセージ
ACTUAL_COUNT=$(($(wc -l < "$OUTPUT") - 1))
cat << EOF
=================================================
Completed!
Output file: $OUTPUT
Total data points: $ACTUAL_COUNT
=================================================
EOF
