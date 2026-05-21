# Trading System Workspace

A complete event-driven quantitative trading system deployed as a monorepo. Contains three interconnected components:

| Component | Description |
|---|---|
| [Market Data Pipeline](./Backtester-Oriented-Market-Data-Pipeline/) | Data ingestion, normalization, Parquet storage, event streaming |
| [Backtesting Engine](./Event-Driven-Backtesting-Engine/) | Event-driven strategy simulation with 10 built-in strategies |
| [Strategy Research Terminal](./strategy-research-terminal/) | Full-stack research UI (Next.js + FastAPI + WebSocket streaming) |

## Architecture

```
Frontend (Next.js on Vercel)
    ↕ REST + WebSocket
Backend (FastAPI on Railway)
    ↕ Python imports
Pipeline + Engine (bundled in Docker container)
    ↕ yfinance
Yahoo Finance API
```

## Deployment

- **Frontend**: Deployed on [Vercel](https://vercel.com) — see `strategy-research-terminal/frontend/`
- **Backend**: Deployed on [Railway](https://railway.app) via Docker — see `Dockerfile`

## Local Development

See individual README files in each component directory for setup instructions.

## License

MIT
