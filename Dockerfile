# ───────────────────────────────────────────────────────────────
# Trading System — Monorepo Backend Docker Image
#
# Bundles all 3 repos (pipeline, engine, backend) into a single
# container so the FastAPI backend can import them via sys.path.
#
# Build from this directory:
#   docker build -t trading-backend .
#
# Run locally:
#   docker run -p 8000:8000 trading-backend
# ───────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# ── Install system dependencies ──────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# ── Copy dependency files first (Docker layer caching) ───────
COPY strategy-research-terminal/backend/requirements.txt /app/backend-requirements.txt
COPY Backtester-Oriented-Market-Data-Pipeline/requirements.txt /app/pipeline-requirements.txt

RUN pip install --no-cache-dir \
    -r /app/backend-requirements.txt \
    -r /app/pipeline-requirements.txt

# ── Copy all 3 codebases ────────────────────────────────────
COPY Backtester-Oriented-Market-Data-Pipeline/market_data/ /app/pipeline/market_data/
COPY Backtester-Oriented-Market-Data-Pipeline/pyproject.toml /app/pipeline/pyproject.toml
COPY Event-Driven-Backtesting-Engine/engine/ /app/engine/engine/
COPY Event-Driven-Backtesting-Engine/run_backtest.py /app/engine/run_backtest.py
COPY strategy-research-terminal/backend/ /app/backend/

# ── Create persistent data directory ─────────────────────────
# In production (Railway), mount a volume here
RUN mkdir -p /app/data

# ── Set default environment variables ────────────────────────
ENV DATA_DIR=/app/data \
    ENGINE_PATH=/app/engine \
    PIPELINE_PATH=/app/pipeline \
    PORT=8000

WORKDIR /app/backend

EXPOSE 8000

# ── Health check ─────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# ── Start the server ────────────────────────────────────────
# Railway/Render inject PORT env var; $PORT makes it dynamic
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
