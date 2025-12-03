# Bybit OHLCV Data Fetcher

Fetch historical OHLCV (candlestick) data from Bybit exchange for backtesting and machine learning.

## Overview

This project retrieves historical price data from Bybit and saves it in CSV format for use in backtesting and deep learning models.

### Key Features

- ✅ **No API Key Required** - Public market data access
- ✅ **Flexible Parameters** - Customize timeframe, period, and symbol
- ✅ **Large Data Support** - Automatic pagination for long-term data
- ✅ **Rate Limit Protection** - Configurable delay between requests
- ✅ **CSV Output** - Ready for backtesting frameworks

---

## Quick Start

### 1. Build

```bash
go build -o ohlcv main.go
```

### 2. Fetch Data

#### Using Script (Recommended)

```bash
# BTC/USDT 1h 6 months
./scripts/fetch_ohlcv.sh -s "BTC/USDT"

# ETH/USDT 15m 3 months
./scripts/fetch_ohlcv.sh -s "ETH/USDT" -t 15m -p 3months
```

#### Direct Command

```bash
# Latest 100 candles (1h)
./ohlcv -symbol "BTC/USDT" -timeframe 1h -limit 100

# Fetch from specific date
./ohlcv -symbol "BTC/USDT" -timeframe 5m -since "2025-11-01T00:00:00Z" -limit 1000
```

---

## Project Structure

```
ohlcv/
├── main.go                          # OHLCV data fetcher (Go)
├── ohlcv                            # Compiled binary
├── go.mod / go.sum                  # Go dependencies
├── LICENSE                          # License file
├── README.md                        # This file
│
├── scripts/                         # Data fetching scripts
│   ├── fetch_ohlcv.sh              # Generic data fetcher
│   └── README.md                    # Script documentation
│
└── docs/                            # Documentation
    └── BYBIT_API_LIMITATIONS.md     # API limitations & notes
```

---

## Usage

### Go Program (`ohlcv`)

#### Command-line Arguments

```bash
./ohlcv [OPTIONS]

Options:
  -symbol string
        Trading pair (required) e.g., "BTC/USDT", "ETH/USDT"
  -timeframe string
        Timeframe (default: "1m")
        Supported: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 12h, 1d, 1w
  -since string
        Start time (RFC3339 format)
        e.g., "2025-11-01T00:00:00Z"
        Default: 1 hour ago
  -limit int
        Maximum number of candles (default: 100, max: 1000)
```

#### Examples

```bash
# Basic usage
./ohlcv -symbol "BTC/USDT" -timeframe 1h -limit 100

# Save to CSV file
./ohlcv -symbol "BTC/USDT" -timeframe 15m -limit 500 > data.csv

# Fetch from specific period
./ohlcv -symbol "ETH/USDT" -timeframe 1d -since "2025-01-01T00:00:00Z" -limit 365
```

### Script (`scripts/fetch_ohlcv.sh`)

```bash
./scripts/fetch_ohlcv.sh -s "BTC/USDT" [OPTIONS]

Required:
  -s, --symbol SYMBOL        Trading pair

Options:
  -t, --timeframe TIMEFRAME  Timeframe (default: 1h)
  -p, --period PERIOD        Period (default: 6months)
  -o, --output FILE          Output filename (auto-generated)
  -l, --limit LIMIT          Fetch limit per request (default: 1000)
  -d, --delay SECONDS        Delay between API calls (default: 2)
  -h, --help                 Show help
```

#### Use Case Examples

| Use Case | Command | Data Points |
|----------|---------|-------------|
| Scalping | `./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 7days` | ~10,000 |
| Day Trading | `./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 5m -p 3months` | ~26,000 |
| Swing Trading | `./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 1h -p 1year` | ~8,760 |
| Deep Learning | `./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 15m -p 6months` | ~17,000 |
| Long-term Backtest | `./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 1d -p 5years` | ~1,825 |

---

## Data Format

### CSV Output

```csv
timestamp,iso_time,open,high,low,close,volume
1764765000000,2025-12-03T21:30:00+09:00,92736.4,92740.6,92687.9,92707.3,6.659476
1764765060000,2025-12-03T21:31:00+09:00,92707.3,92744.4,92690.2,92740.5,5.407876
```

### Field Descriptions

| Field | Description | Type |
|-------|-------------|------|
| timestamp | Unix millisecond timestamp | int64 |
| iso_time | RFC3339 formatted datetime | string |
| open | Opening price | float64 |
| high | Highest price | float64 |
| low | Lowest price | float64 |
| close | Closing price | float64 |
| volume | Trading volume | float64 |

---

## API Limits & Notes

### Rate Limits

- **Global limit**: 600 requests / 5 seconds / IP
- **Recommended delay**: 2~5 seconds per request
- **Max per request**: 1000 candles

### Data Volume Estimates

| Timeframe | 6 Months Data | File Size | API Calls |
|-----------|---------------|-----------|-----------|
| 1m | ~259,200 | 21MB | ~260 |
| 5m | ~51,840 | 4.3MB | ~52 |
| 15m | ~17,280 | 1.4MB | ~18 |
| 1h | ~4,320 | 367KB | ~5 |
| 1d | ~180 | 15KB | 1 |

See [docs/BYBIT_API_LIMITATIONS.md](docs/BYBIT_API_LIMITATIONS.md) for detailed information.

---

## Troubleshooting

### Rate Limit Errors (403/429)

Increase delay between requests:

```bash
./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 6months -d 5
```

### Script Not Executable

Grant execution permission:

```bash
chmod +x scripts/fetch_ohlcv.sh
```

### Large Data Fetching

For 1-minute data over long periods, increase delay:

```bash
# 1m for 1 year (~525 API calls)
./scripts/fetch_ohlcv.sh -s "BTC/USDT" -t 1m -p 1year -d 3
```

---

## Using with Backtesting Frameworks

### Python (backtrader)

```python
import backtrader as bt
import pandas as pd

# Load CSV data
df = pd.read_csv('btc_usdt_1h_6months.csv')
df['datetime'] = pd.to_datetime(df['iso_time'])
df.set_index('datetime', inplace=True)

# Convert to backtrader data feed
data = bt.feeds.PandasData(dataname=df)

# Add to Cerebro
cerebro = bt.Cerebro()
cerebro.adddata(data)
```

### Python (zipline)

```python
import pandas as pd

# Load CSV data
df = pd.read_csv('btc_usdt_1h_6months.csv', parse_dates=['iso_time'])
df.set_index('iso_time', inplace=True)
df.rename(columns={'volume': 'vol'}, inplace=True)

# Use with zipline
# ... (zipline configuration)
```

---

## Dependencies

### Go

- Go 1.20+
- [CCXT Go](https://github.com/ccxt/ccxt) v4.5.23

### Installation

```bash
go mod download
```

---

## License

This project is licensed under the MIT License.

---

## References

- [Bybit API Documentation](https://bybit-exchange.github.io/docs/)
- [CCXT Documentation](https://docs.ccxt.com/)
- [API Limitations Details](docs/BYBIT_API_LIMITATIONS.md)

---

## Changelog

| Date | Changes |
|------|---------|
| 2025-12-04 | Organized project structure (scripts/, docs/) |
| 2025-12-04 | Added generic data fetcher (fetch_ohlcv.sh) |
| 2025-12-04 | Implemented Go program (main.go) |
| 2025-12-04 | Added API limitations documentation |
