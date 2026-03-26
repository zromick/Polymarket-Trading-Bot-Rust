<p align="center">
  <h1 align="center">Polymarket Trading Bot - Copy-Trading version with Rust</h1>
  <p align="center">
    <strong>Built from real market experience: from failed spread edges to practical, high-speed copy-trading.</strong>
  </p>
  <p align="center">
    Rust backend &middot; Real-time WebSocket &middot; Web dashboard
  </p>
</p>

---

## What Inspired Us

This is our self-hosted copy-trading system for [Polymarket](https://polymarket.com), built after a lot of trial, failure, and iteration in live markets.

We first entered Polymarket at the end of 2025. Since our background is Web3 dApp development, we initially focused on short-window crypto markets (like BTC in 5-15 minutes) and built spread-based strategies between UP and DOWN tokens.

At first, the edge looked strong. Then the same pattern repeated: once a strategy became crowded, spreads tightened and the advantage faded.

We tested and updated multiple strategy variants, but learned the same lesson again and again:
- Publicly known edges decay fast
- Static "formula" bots stop working
- Most people overfit one setup and then chase losses

After reviewing hundreds of Polymarket trading repos and private scripts, we found that most tools either:
- hide the core logic,
- overpromise with no risk framework, or
- are not production-ready for real-time execution.

That experience pushed us to build this project around what actually stayed reliable for us: disciplined copy-trading plus fast infrastructure.

Instead of manually refreshing polymarket.com and tracking wallets by hand, this bot gives you:

- **Instant copy-trading** — follow one or many high-performing wallets with configurable sizing, filters, and exit rules
- **Portfolio overview** — see your open positions, notional exposure, and active trades in one consolidated view
- **Live activity stream** — every trade from your targets, streamed as it happens and organized for quick scanning
- **AI-powered analysis** — ask the Agent about any market, trader, or position; get structured notes (sentiment, timing, catalysts, risks) and guidance
- **Simulation mode** — dry-run strategies with no real capital before you go live

It works across politics, sports, crypto, and macro. You adjust behavior via `trade.toml` (targets + filters). Everything runs locally; API keys and private keys stay on your machine.

---

## Why this exists

Our core conclusion from live testing: for most traders, stable compounding comes less from "finding one secret setup" and more from selecting the right wallets, reacting fast, and managing exits consistently.

We started tracking top Polymarket profiles (especially wallets with strong daily realized PnL) and monitoring their behavior in real time. That shift changed our results more than any single spread/arbitrage logic we tried before.

But copy-trading itself is not enough. Blind mirroring is fragile.

You actually need:

- Multiple leaders, not a single hero wallet
- Filters on market type, timing, and size
- Rules for when to follow, when to ignore, and when to exit

That is where **AI** helps in this project: not to auto-trade, but to analyze context and prioritize what deserves attention.

This bot comes from months of iterating on filters, timing, position sizing, and execution speed. Backtests + simulation + live feedback consistently pointed toward **slow, repeatable growth** instead of chasing volatility.

We chose **Rust front-to-back** (backend + Leptos/WASM UI) to keep stream processing and execution responsive under load, especially when multiple leaders fire trades around the same time.

When multiple leaders pile into the same market, the Agent can help rank signals (category performance, timing, risk context) so you do not blindly copy everyone.

Our design goal is not "one home run trade." It is **durable growth**: diversified exposure across categories, strict execution logic, and continuous adaptation as market behavior changes.

We are still researching, testing, and refining this stack. If you have real data, ideas, or improvements, we are happy to exchange notes.


---

**By [HyperBuildX](https://t.me/hyperbuildx)** — questions, ideas, and contributions are welcome.

---

## Features

| | Feature | What it does |
|---|---------|-------------|
| :bar_chart: | **Dashboard** | Live status, activity stream, copy targets — single page for "what's happening right now" |
| :robot: | **Agent** | AI chat (OpenRouter / OpenAI / Claude). Research any market or position — get trade hints, risk analysis, and confidence signals |
| :scroll: | **Logs** | Full trade and event log, streamed in real time via SSE |
| :trophy: | **Top Traders** | Follow the best wallets on Polymarket. See their activity the moment it happens |
| :briefcase: | **Portfolio** | Your wallet's active trades, total value, and per-target positions side by side |
| :gear: | **Settings** | All config at a glance — targets, multiplier, exit rules, simulation toggle |

---

## Screenshots

| **Dashboard** | **Agent** |
|:---:|:---:|
| <img src="https://i.ibb.co/Rkmq13bj/mm-1.png" alt="mm 1" border="0"> | <img src="https://i.ibb.co/HfXx5kwR/mm-2.png" alt="mm 2" border="0"> |

---

## Quick Start

### 1. Prerequisites

**Machine**

- **Linux** or **macOS** (recommended) or **Windows** (WSL2 is easier than native Windows for Rust + Trunk; native Windows works if `cargo` and `trunk` are on `PATH`).
- ~2–4 GB free disk for Rust toolchain + first compile; stable internet for crate downloads.

**Rust (required)**

1. Install **[rustup](https://rustup.rs/)** if you don’t have Rust yet.
2. Use the default **stable** toolchain (this project targets Rust **1.70+**).
3. Confirm in a **new terminal**:

   ```bash
   rustc --version   # should show 1.70 or higher
   cargo --version
   ```

**Polymarket (for live trading)**

- A Polymarket account, **USDC on Polygon**, and **CLOB API** credentials. See the [official CLOB docs](https://docs.polymarket.com/developers/CLOB/). You still need a valid `config.json` to start the app; use **simulation mode** (step 7) if you only want to explore the UI first.

### 2. Clone

```bash
git clone https://github.com/HyperBuildX/Polymarket-Trading-Bot-Rust.git
cd Polymarket-Trading-Bot-Rust
```

### 3. Configure

Create two files in the project root:

**`config.json`** — your Polymarket CLOB credentials:

```jsonc
{
  "polymarket": {
    "gamma_api_url": "https://gamma-api.polymarket.com",
    "clob_api_url": "https://clob.polymarket.com",
    "api_key": "your-api-key",
    "api_secret": "your-api-secret",
    "api_passphrase": "your-api-passphrase",
    "private_key": "your-private-key",
    "proxy_wallet_address": null,
    "signature_type": 0
  }
}
```

**`trade.toml`** — who to copy and how. Use any leader's wallet address from [Polymarket](https://polymarket.com) as `target_address` or in `target_addresses`:

```toml
[copy]
target_address = "0x1979ae6B7E6534dE9c4539D0c205E582cA637C9D"
# or target_addresses = ["0x...", "0x..."]
size_multiplier = 0.01
poll_interval_sec = 0.5

[exit]
take_profit = 0      # 0 = off
stop_loss = 0
trailing_stop = 0

[filter]
buy_amount_limit_in_usd = 0
entry_trade_sec = 0
trade_sec_from_resolve = 0
```

**`.env`** *(not required, for AI Agent)*:

```env
OPENROUTER_API_KEY=sk-or-...
# or OPENAI_API_KEY=sk-...
# or ANTHROPIC_API_KEY=sk-ant-...
```

### 4. Build & Run

```bash
# Build the frontend (once)
cd frontend && trunk build --release && cd ..

# Run
cargo run --release --bin main_copytrading
```

Open **http://localhost:8000** — that's it. Dashboard, agent, logs, portfolio, everything is there.

### 5. Simulation mode (no real orders)

```bash
cargo run --release --bin main_copytrading -- --simulation
```

Perfect for testing your setup, exploring the UI, and evaluating traders before risking capital.

---

## Requirements

| Requirement | Details |
|------------|---------|
| **Rust** | 1.70+ |
| **Polymarket account** | USDC on Polygon + CLOB API keys ([docs](https://docs.polymarket.com/developers/CLOB/)) |
| **Frontend tooling** | `cargo install trunk` and `rustup target add wasm32-unknown-unknown` |

---

## How it works

The bot subscribes to Polymarket's **activity WebSocket** (`wss://ws-live-data.polymarket.com`) and filters by your target addresses client-side. Trades are pushed the instant they happen — you copy with minimal delay and see them in the UI in real time.

A separate loop refreshes positions for the portfolio view. All copy-trading is driven by the live stream, not polling.

```
Activity WebSocket ──▶ Filter by targets ──▶ Copy trade ──▶ Dashboard + Logs
                                                │
                                         Exit rules (TP/SL/trailing)
```

---

## AI Agent

The Agent tab turns your dashboard into a research terminal. Pick a provider (OpenRouter, OpenAI, or Claude) from the dropdown — it uses whichever API keys you set in `.env`.

The agent follows the **Monitor → Analyze** method (inspired by [Mahoraga](https://mahoraga.dev/)):

- You ask a question about a market, a position, or a trader
- The LLM researches sentiment, timing, catalysts, and red flags
- You get back a structured note: **Signal → Research → Context → Confidence → Guidance**

No execution — research and guidance only. You decide when to act.

---

## Config Reference

**`config.json`** — CLOB API credentials and wallet:

| Field | Required | Notes |
|-------|----------|-------|
| `clob_api_url` | Yes | `https://clob.polymarket.com` |
| `private_key` | Yes | Polygon wallet private key |
| `api_key` / `api_secret` / `api_passphrase` | Yes | From Polymarket CLOB dashboard |
| `proxy_wallet_address` | No | For proxy/Magic wallets |
| `signature_type` | No | `0` = EOA, `1` = Proxy, `2` = GnosisSafe |

**`trade.toml`** — copy-trading behavior:

| Section | Key fields |
|---------|------------|
| `[copy]` | `target_address` or `target_addresses`, `size_multiplier`, `poll_interval_sec`, `revert_trade` |
| `[exit]` | `take_profit`, `stop_loss`, `trailing_stop` (0 = off) |
| `[filter]` | `buy_amount_limit_in_usd`, `entry_trade_sec`, `trade_sec_from_resolve` |
| `[ui]` | `delta_highlight_sec`, `delta_animation_sec` |

Top-level: `clob_host`, `chain_id`, `port`, `simulation`.

---

## Production Deployment

```bash
# 1. Build frontend
cd frontend && trunk build --release && cd ..

# 2. Run (serves both API and UI on one port)
cargo run --release --bin main_copytrading
```

Access from any device on your network at `http://<your-server-ip>:8000`. The binary is the single entry point — no separate frontend server needed.

---

## Project Layout

| Path | Role |
|------|------|
| `src/bin/main_copytrading.rs` | Entrypoint, HTTP server, agent endpoints |
| `src/activity_stream.rs` | WebSocket client for real-time trades |
| `src/copy_trading.rs` | Config, filters, copy logic, exit loop, position diff |
| `src/api.rs` | Polymarket CLOB/Data API client |
| `src/clob_sdk.rs` | FFI bindings to the CLOB SDK `.so` |
| `src/web_state.rs` | Shared state for UI, `/api/state` JSON + SSE |
| `frontend/` | Leptos (Rust → WASM): dashboard, agent, logs, portfolio, settings |

---

## References

- [Polymarket CLOB Documentation](https://docs.polymarket.com/developers/CLOB/)
- [Polymarket API Reference](https://docs.polymarket.com/api-reference/introduction)
- [OpenRouter](https://openrouter.ai/) — multi-model AI gateway
- [Mahoraga](https://mahoraga.dev/) — Monitor → Analyze method

---

<p align="center"><sub>Built for traders who want speed, transparency, and an edge.</sub></p>
