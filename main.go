package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/ccxt/ccxt/go/v4"
)

type Candle struct {
	Time   time.Time
	Open   float64
	High   float64
	Low    float64
	Close  float64
	Volume float64
}

func main() {
	var (
		symbol    = flag.String("symbol", "", "Trading pair symbol (e.g., BTC/USDT)")
		timeframe = flag.String("timeframe", "1m", "Timeframe (e.g., 1m, 5m, 1h)")
		sinceStr  = flag.String("since", "", "Start time in RFC3339 format (default: 1 hour ago)")
		limit     = flag.Int("limit", 100, "Maximum number of candles to fetch")
	)
	flag.Parse()

	// Validate arguments
	if *symbol == "" {
		log.Fatalf("Error: -symbol is required")
	}
	if *limit <= 0 {
		log.Fatalf("Error: -limit must be greater than 0")
	}

	// Parse since time
	var since time.Time
	if *sinceStr == "" {
		since = time.Now().Add(-1 * time.Hour)
	} else {
		var err error
		since, err = time.Parse(time.RFC3339, *sinceStr)
		if err != nil {
			log.Fatalf("Error: invalid -since format (expected RFC3339): %v", err)
		}
	}

	// Fetch and output OHLCV data
	candles, err := fetchOHLCV(*symbol, *timeframe, since, *limit)
	if err != nil {
		log.Fatalf("Error: failed to fetch OHLCV data: %v", err)
	}

	if err := outputCSV(candles); err != nil {
		log.Fatalf("Error: failed to output CSV: %v", err)
	}
}

func fetchOHLCV(symbol, timeframe string, since time.Time, limit int) ([]Candle, error) {
	// Initialize Bybit client
	apiKey := os.Getenv("BYBIT_API_KEY")
	apiSecret := os.Getenv("BYBIT_API_SECRET")

	exchange := ccxt.NewBybit(map[string]interface{}{
		"apiKey":          apiKey,
		"secret":          apiSecret,
		"enableRateLimit": true,
	})

	// Load markets
	if _, err := exchange.LoadMarkets(nil); err != nil {
		return nil, fmt.Errorf("failed to load markets: %w", err)
	}

	// Fetch OHLCV data
	sinceMs := since.UnixMilli()
	ohlcvData, err := exchange.FetchOHLCV(
		symbol,
		ccxt.WithFetchOHLCVTimeframe(timeframe),
		ccxt.WithFetchOHLCVSince(sinceMs),
		ccxt.WithFetchOHLCVLimit(int64(limit)),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch OHLCV: %w", err)
	}

	// Parse OHLCV data
	candles := parseOHLCV(ohlcvData)

	return candles, nil
}

func parseOHLCV(ohlcvData []ccxt.OHLCV) []Candle {
	candles := make([]Candle, 0, len(ohlcvData))

	for _, data := range ohlcvData {
		candles = append(candles, Candle{
			Time:   time.UnixMilli(data.Timestamp),
			Open:   data.Open,
			High:   data.High,
			Low:    data.Low,
			Close:  data.Close,
			Volume: data.Volume,
		})
	}

	return candles
}

func outputCSV(candles []Candle) error {
	writer := csv.NewWriter(os.Stdout)
	defer writer.Flush()

	// Write header
	if err := writer.Write([]string{"timestamp", "iso_time", "open", "high", "low", "close", "volume"}); err != nil {
		return fmt.Errorf("failed to write header: %w", err)
	}

	// Write data rows
	for _, candle := range candles {
		record := []string{
			strconv.FormatInt(candle.Time.UnixMilli(), 10),
			candle.Time.Format(time.RFC3339),
			strconv.FormatFloat(candle.Open, 'f', -1, 64),
			strconv.FormatFloat(candle.High, 'f', -1, 64),
			strconv.FormatFloat(candle.Low, 'f', -1, 64),
			strconv.FormatFloat(candle.Close, 'f', -1, 64),
			strconv.FormatFloat(candle.Volume, 'f', -1, 64),
		}
		if err := writer.Write(record); err != nil {
			return fmt.Errorf("failed to write record: %w", err)
		}
	}

	return nil
}
