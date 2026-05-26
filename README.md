<div align="center">

# Strategy Research Platform

**A full-stack, enterprise-grade quantitative research platform for backtesting trading strategies with real-time streaming, database persistence, AI-powered analysis, and interactive dashboards.**

[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Next.js](https://img.shields.io/badge/Next.js_15-000000?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org)
[![React](https://img.shields.io/badge/React_19-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge&logo=socket.io&logoColor=white)](#architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

[**Architecture**](#architecture) · [**Features**](#features) · [**Getting Started**](#getting-started) · [**Tech Stack**](#tech-stack) · [**API Reference**](#api-reference)

</div>

---

## Overview

The **Strategy Research Platform** is a quantitative backtesting and simulation system composed of three highly-integrated components:
1. **[Market Data Pipeline](file:///Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/Backtester-Oriented-Market-Data-Pipeline)**: Standardizes and stores historical market data and corporate actions (dividends).
2. **[Event-Driven Backtesting Engine](file:///Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/Event-Driven-Backtesting-Engine)**: Runs lookahead-free historical simulations with realistic transaction cost profiles.
3. **[Strategy Research Terminal](file:///Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/strategy-research-terminal)**: Provides a web interface with real-time WebSocket streaming, PostgreSQL-backed session/run persistence, and LLM-powered strategy coding and reporting.

---

## Architecture

The system decouples data ingestion, execution logic, and presentation using an event-driven flow. Communication between backend services and the frontend dashboard utilizes REST APIs for configurations and WebSocket connections for real-time progress and trade streaming.

```mermaid
graph TB
    subgraph Frontend ["Frontend — Next.js 15 + React 19"]
        UI["Dashboard UI<br/>Zustand Store · Recharts"]
        Auth_Store["Auth Store<br/>JWT Tokens"]
    end

    subgraph Backend ["Backend — FastAPI + SQLAlchemy"]
        REST["REST API<br/>POST /api/backtest/run<br/>POST /auth/login"]
        WS["WebSocket Server<br/>/ws/backtest/{run_id}"]
        VAL["Config Validator<br/>Pydantic Schema"]
        DB_Layer["Database ORM<br/>SQLAlchemy + Asyncpg"]
    end

    subgraph DB ["Database — PostgreSQL"]
        PG[("PostgreSQL DB<br/>Users · Runs · Trades · Reports")]
    end

    subgraph Engine ["Backtesting Engine — Event-Driven Python"]
        EQ["Event Queue (FIFO)"]
        STRAT["Strategies<br/>O(1) EMA/MACD/Trend"]
        OM["Order Manager<br/>Fixed · % · Risk-Based"]
        EXEC["Execution Engine<br/>Next-Bar / Slip / Comm"]
        PORT["Portfolio Tracker<br/>Cash · Positions · Trades List"]
    end

    subgraph Pipeline ["Market Data Pipeline"]
        ING["Ingestion<br/>yfinance (auto_adjust=True)"]
        NORM["Normalization<br/>Schema + UTC UTC timezone-aware"]
        STORE["Storage<br/>Apache Parquet"]
    end

    UI -->|"HTTP POST (Auth Headers)"| REST
    UI -->|"WebSocket"| WS
    REST --> VAL
    REST --> DB_Layer
    WS --> DB_Layer
    DB_Layer --> PG
    
    VAL -->|"Launch Thread"| EQ
    STORE -->|"Chronological stream"| EQ
    
    EQ --> STRAT --> OM --> EXEC --> PORT
    PORT -->|"Stream Updates"| WS
    PORT -->|"JSON Serialize"| DB_Layer

    style Frontend fill:#1a1a2e,stroke:#4361ee,color:#fff
    style Backend fill:#1a1a2e,stroke:#f72585,color:#fff
    style DB fill:#111,stroke:#4cc9f0,color:#fff
    style Engine fill:#1a1a2e,stroke:#4cc9f0,color:#fff
    style Pipeline fill:#1a1a2e,stroke:#7209b7,color:#fff
```

### Complete Backtest Workflow

1. **Configure & Authenticate**: The user logs in via JWT authentication. The React client loads their profile settings, containing custom transaction cost rules (commission rates and slippage models).
2. **Strategy Translation**: The user describes a strategy in natural language. Groq API resolves this into a structured JSON configuration representing one of 10 built-in strategies.
3. **Configuration Submission**: The client dispatches a `POST /api/backtest/run` request with the JWT in the `Authorization` header. The backend validates the parameters and ensures the symbol data exists in the Parquet store (fetching it on-demand via `yfinance` if missing).
4. **Execution Loop & Streaming**: The server registers the backtest in the database, establishes a WebSocket connection, and executes the engine within a thread pool. The engine streams chronological market events, dividend events, and trade executions back to the client.
5. **State Persistence**: On simulation completion, the final metrics, complete trade log (Execution Blotter), and an AI-generated performance report are serialized and saved to PostgreSQL.
6. **Restoration**: The user can access the Run History panel to load any historical run, re-hydrating the charts, metrics, and Execution Blotter directly from the database.

---

## Features

### ⚡ Optimized Quantitative Engine
* **Incremental O(1) Indicators**: Key technical indicator strategies (such as MACD and Trend Following) compute values incrementally by maintaining state from the previous bar rather than recalculating the entire historical series, reducing execution time complexity from $O(n^2)$ to $O(1)$.
* **Lookahead-Free Execution**: Built-in option for next-bar pricing (`next_bar_pricing=True`) ensures signals generated at the close of bar $t$ are filled at the open of bar $t+1$, preventing execution lookahead bias.
* **Realistic Transaction Cost Profiles**: Incorporates custom user-defined commission structures (fixed per trade or percentage-based) and slippage models (fixed dollar offsets or percentage spreads).

### 🔒 Enterprise Access & Persistence
* **JWT Authentication**: Secure user registration, password hashing (bcrypt), token issuance, and authenticated endpoints.
* **PostgreSQL Integration**: Relational database storage using `SQLAlchemy` and `asyncpg` to persist run metadata, complete trade execution logs (JSON-serialized), and markdown-formatted AI analysis reports.
* **Run Restoration & Rehydration**: Allows loading any past simulation run from history, fully populating the equity curves, drawdown timelines, rolling Sharpe ratios, and the interactive Execution Blotter.

### 📊 Real-Time Interactive UI
* **WebSocket Progress Tracking**: Renders simulation progress bar-by-bar, eliminating the lag associated with polling APIs.
* **Live Dashboards**: Renders responsive charts (Recharts) for equity curves, drawdown analysis, and rolling Sharpe ratios.
* **Refined Precision & Date Presentation**: Clean formatting displaying full-precision dates (including years) and accurately scaled benchmark analytics (Alpha percentages normalized by 100).
* **Natural Language Copilot**: Translates simple prompts into validated backtesting parameters using Groq (Llama-3).

---

## Repository Structure

```
strategy-research-platform/
├── Backtester-Oriented-Market-Data-Pipeline/   # Data ingestion & storage
│   ├── market_data/
│   │   ├── api.py                              # Data access interface
│   │   ├── ingestion.py                        # yfinance downloader
│   │   ├── normalization.py                    # Schema cleaner & UTC parser
│   │   ├── storage.py                          # Parquet file manager
│   │   └── events.py                           # Event generator (Market/Dividend)
│   └── scripts/fetch_data.py                   # CLI data downloader
│
├── Event-Driven-Backtesting-Engine/            # Simulation core
│   ├── engine/
│   │   ├── engine.py                           # FIFO queue orchestrator
│   │   ├── strategy.py                         # O(1) indicators and strategies
│   │   ├── portfolio.py                        # Position, cash & trade tracking
│   │   ├── execution.py                        # Commission & slippage engines
│   │   ├── order_manager.py                    # Risk-based and fixed position sizing
│   │   └── metrics.py                          # Sharpe, Drawdown, Alpha formulas
│   └── run_backtest.py                         # CLI backtest script
│
├── strategy-research-terminal/                 # Web interface & backend API
│   ├── backend/
│   │   ├── main.py                             # FastAPI startup & websocket endpoint
│   │   ├── config.py                           # System path and env loader
│   │   ├── db/                                 # PostgreSQL schemas & sessions
│   │   ├── auth/                               # JWT token & user helpers
│   │   └── runs/                               # Run schemas & data validation
│   └── frontend/
│       ├── app/                                # Next.js pages & API proxies
│       ├── components/                         # Charts, Blotter, inputs, reports
│       ├── hooks/                              # useBacktest & useWebSocket hooks
│       └── store/                              # Zustand terminal store
│
├── pyproject.toml                              # Root tool configurations
└── README.md                                   # Monorepo documentation
```

---

## Getting Started

### Prerequisites

* Python 3.9+
* Node.js 18+
* PostgreSQL running locally (default database: `strategy_terminal`)

---

### Step 1: Clone the Repository

Clone the project along with its submodules:
```bash
git clone --recurse-submodules https://github.com/khushal0811/strategy-research-platform.git
cd strategy-research-platform
```

---

### Step 2: Database Setup

Create a PostgreSQL database for the application:
```sql
CREATE DATABASE strategy_terminal;
```

---

### Step 3: Configure and Launch the Backend

1. Navigate to the backend directory and set up a virtual environment:
   ```bash
   cd strategy-research-terminal/backend
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Create a `.env` file in `strategy-research-terminal/backend/.env`:
   ```env
   # Submodule Path Configuration
   DATA_DIR=/Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/Backtester-Oriented-Market-Data-Pipeline/data
   ENGINE_PATH=/Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/Event-Driven-Backtesting-Engine
   PIPELINE_PATH=/Users/khushalarora/Documents/Career/Trading-System-Workspace/market-data-pipeline/Backtester-Oriented-Market-Data-Pipeline

   # Security & Persistence
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/strategy_terminal
   JWT_SECRET_KEY=generate-a-secure-random-key-with-secrets-module

   # LLM Analysis
   GROQ_API_KEY=your_groq_api_key_here
   ```

3. Start the FastAPI development server:
   ```bash
   uvicorn main:app --reload --port 8000
   ```

---

### Step 4: Configure and Launch the Frontend

1. Navigate to the frontend directory and install dependencies:
   ```bash
   cd ../frontend
   npm install
   ```

2. Create a `.env.local` file in `strategy-research-terminal/frontend/.env.local`:
   ```env
   NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
   NEXT_PUBLIC_WS_URL=ws://127.0.0.1:8000
   GROQ_API_KEY=your_groq_api_key_here
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000) in your browser.

---

### Step 5: Fetch Base Market Data

Download historical market data for the assets you wish to backtest using the pipeline command:
```bash
cd ../../Backtester-Oriented-Market-Data-Pipeline
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python scripts/fetch_data.py --symbols AAPL,MSFT,SPY --start 2020-01-01 --end 2026-01-01 --dividends
```

---

### Step 6: Verify the System

Run the engine test suite to ensure the system is functional:
```bash
cd ../Event-Driven-Backtesting-Engine
source .venv/bin/activate
.venv/bin/pytest tests/ -v
```
All **126 tests** should pass.

---

## API Reference

### User Authentication
* `POST /auth/register` — Register a new user account.
* `POST /auth/login` — Login and receive a JWT token.
* `GET /auth/profile` — Fetch custom profile settings (commission/slippage profiles).
* `PUT /auth/profile` — Update custom profile settings (commission/slippage profiles).

### Backtest Configuration & Data
* `GET /api/data/symbols` — Get a list of all locally available assets.
* `GET /api/data/info/{symbol}` — Query asset data boundaries, check if dividends exist, and validate ticker existence.
* `POST /api/backtest/run` — Submit backtest configuration, fetch missing data on-demand, register run, and return a unique `run_id`.
* `GET /api/backtest/runs` — Fetch the user's historical runs.
* `GET /api/backtest/runs/{run_id}` — Retrieve detailed metrics, trades history, and AI reports for a specific run.

### WebSocket Connection
* `WS /ws/backtest/{run_id}?token={jwt_token}` — Connect to stream backtest execution progress, live trade logs, dividend entries, and final metrics.

---

## Design Principles

* **Strict Event-Driven Flow**: No vector shortcuts. Each historical price bar or dividend action is queued as an event, processed by the strategy, routed to the order manager, and executed sequentially.
* **Lookahead Protection**: Guarantees simulations are lookahead-free. Supports filling orders using next-bar pricing configurations.
* **State Optimization**: High performance is maintained even on long datasets by keeping running mathematical states for rolling indicators.
* **Cohesive Synchronization**: A WebSocket bridge links synchronous Python engine threads to asynchronous API queues, updating the Next.js client seamlessly.

---

## License

MIT — see [LICENSE](LICENSE).
