# OHLCV Data Fetching Script

Bybit から OHLCV（ローソク足）データを取得する汎用スクリプト。

## 使用方法

### 基本構文

```bash
./fetch_ohlcv.sh -s SYMBOL [OPTIONS]
```

### オプション

| オプション | 説明 | デフォルト値 |
|-----------|------|------------|
| `-s, --symbol` | 取引ペア（必須） | - |
| `-t, --timeframe` | 時間足 | `1h` |
| `-p, --period` | 期間 | `6months` |
| `-m, --market` | 市場タイプ | `linear` |
| `-o, --output` | 出力ファイル名 | 自動生成 |
| `-l, --limit` | 1回のAPI取得数 | `1000` |
| `-d, --delay` | API呼び出し間の待機秒数 | `2` |
| `-h, --help` | ヘルプ表示 | - |

### 対応時間足

`1m`, `3m`, `5m`, `15m`, `30m`, `1h`, `2h`, `4h`, `6h`, `12h`, `1d`, `1w`

### 期間形式

- `Nmonths` / `Nmonth` - 例: `6months`, `3month`
- `Nyears` / `Nyear` - 例: `1year`, `2years`
- `Ndays` / `Nday` - 例: `30days`, `90day`
- `Nweeks` / `Nweek` - 例: `2weeks`, `4week`
- 数値のみ - 例: `180` (180日)

### 市場タイプ

- `spot` - 現物市場
- `linear` - USDT建て無期限契約（デフォルト）
- `inverse` - BTC建て無期限契約

---

## 使用例

### 基本的な使用

```bash
# デフォルト: BTC/USDT 1時間足 6ヶ月（Linear perpetual）
./fetch_ohlcv.sh -s "BTC/USDT"

# ETH/USDT 15分足 3ヶ月
./fetch_ohlcv.sh -s "ETH/USDT" -t 15m -p 3months

# BTC/USDT 1日足 1年間、カスタム出力ファイル
./fetch_ohlcv.sh -s "BTC/USDT" -t 1d -p 1year -o btc_daily.csv
```

### 市場タイプ別の使用

```bash
# Spot市場（現物取引）
./fetch_ohlcv.sh -s "BTC/USDT" -m spot -t 1h -p 6months

# Linear契約（USDT建て無期限、デフォルト）
./fetch_ohlcv.sh -s "BTC/USDT" -m linear -t 1h -p 6months

# Inverse契約（BTC建て無期限）
./fetch_ohlcv.sh -s "BTC/USD" -m inverse -t 1h -p 6months
```

### トレーディング用途別

| 用途 | コマンド | データ量 |
|------|---------|---------|
| **スキャルピング** | `./fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 7days` | 約10,000本 |
| **デイトレード** | `./fetch_ohlcv.sh -s "BTC/USDT" -t 5m -p 3months` | 約26,000本 |
| **スイングトレード** | `./fetch_ohlcv.sh -s "BTC/USDT" -t 1h -p 1year` | 約8,760本 |
| **ディープラーニング** | `./fetch_ohlcv.sh -s "BTC/USDT" -t 15m -p 6months` | 約17,000本 |
| **長期バックテスト** | `./fetch_ohlcv.sh -s "BTC/USDT" -t 1d -p 5years` | 約1,825本 |

### 大量データ取得

1分足で長期間のデータを取得する場合は、待機時間を延長してください：

```bash
# 1分足で6ヶ月（約260回のAPIリクエスト）
./fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 6months -d 3

# 1分足で1年（約525回のAPIリクエスト）
./fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 1year -d 5
```

---

## データ量の目安

| 時間足 | 6ヶ月のデータ量 | ファイルサイズ | API呼び出し回数 |
|--------|----------------|--------------|----------------|
| 1m | 約259,200本 | 21MB | 約260回 |
| 5m | 約51,840本 | 4.3MB | 約52回 |
| 15m | 約17,280本 | 1.4MB | 約18回 |
| 1h | 約4,320本 | 367KB | 約5回 |
| 1d | 約180本 | 15KB | 1回 |

---

## 注意事項

### APIレート制限

- **推奨待機時間**: 2〜5秒
- **グローバル制限**: 600リクエスト/5秒/IP
- 大量データ取得時は `-d` オプションで待機時間を延長

### 実行時間の目安

| データ量 | 待機時間2秒 | 待機時間5秒 |
|---------|-----------|-----------|
| 5回のリクエスト | 約10秒 | 約25秒 |
| 50回のリクエスト | 約2分 | 約4分 |
| 260回のリクエスト | 約9分 | 約22分 |
| 525回のリクエスト | 約18分 | 約44分 |

詳細は `/docs/BYBIT_API_LIMITATIONS.md` を参照してください。

---

## トラブルシューティング

### スクリプトが実行できない

```bash
chmod +x fetch_ohlcv.sh
```

### レート制限エラー（403/429）

待機時間を延長してください：

```bash
./fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 6months -d 5
```

### 親ディレクトリから実行

```bash
cd /path/to/ohlcv
./scripts/fetch_ohlcv.sh -s "BTC/USDT"
```

---

## 出力ファイル

### 自動生成されるファイル名

フォーマット: `{symbol}_{timeframe}_{period}.csv`

例:
- `btc_usdt_1h_6months.csv`
- `eth_usdt_15m_3months.csv`
- `btc_usdt_1d_1year.csv`

### CSV形式

```csv
timestamp,iso_time,open,high,low,close,volume
1764765000000,2025-12-03T21:30:00+09:00,92736.4,92740.6,92687.9,92707.3,6.659476
1764765060000,2025-12-03T21:31:00+09:00,92707.3,92744.4,92690.2,92740.5,5.407876
```

---

## 市場タイプの説明

### Spot（現物市場）

- **説明**: 実際の暗号通貨を売買する市場
- **決済通貨**: 実際の暗号通貨
- **シンボル形式**: `BTC/USDT`, `ETH/USDT`
- **特徴**: レバレッジなし、シンプルな損益計算、実際の資産保有

### Linear（USDT建て無期限契約）

- **説明**: USDTを証拠金とする無期限先物契約
- **決済通貨**: USDT
- **シンボル形式**: `BTC/USDT`, `ETH/USDT`
- **特徴**: レバレッジ可能、USDTベースの損益計算、ファンディングレートあり

### Inverse（BTC建て無期限契約）

- **説明**: BTCまたは他の暗号通貨を証拠金とする無期限先物契約
- **決済通貨**: BTC（または基礎資産）
- **シンボル形式**: `BTC/USD`, `ETH/USD`
- **特徴**: レバレッジ可能、暗号通貨ベースの損益計算、複雑なPnL計算

### 市場タイプの使い分け

| 要素 | Spot | Linear | Inverse |
|------|------|--------|---------|
| **シンプルさ** | 最高 | 中 | 低 |
| **レバレッジ** | なし | あり | あり |
| **証拠金通貨** | Quote | USDT | Base |
| **損益計算** | シンプル | シンプル | 複雑 |
| **適した用途** | 保有 | USDTトレーダー | 仮想通貨蓄積 |

---

## 更新履歴

| 日付 | 内容 |
|------|------|
| 2025-12-04 | 市場タイプ機能追加（spot, linear, inverse） |
| 2025-12-04 | 初版作成 |
