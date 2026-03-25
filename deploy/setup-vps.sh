#!/usr/bin/env bash
# =============================================================================
# Polymarket Trading Bot - VPS Setup Script
# Run this ON the VPS after uploading the project.
# Usage: bash deploy/setup-vps.sh
# =============================================================================
set -euo pipefail

BOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BOT_DIR"

echo "============================================"
echo " Polymarket Bot - VPS Setup"
echo " Project dir: $BOT_DIR"
echo "============================================"

# ---------- 1. System packages ----------
echo ""
echo "[1/6] Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  build-essential pkg-config libssl-dev \
  tmux curl git ufw \
  python3 python3-pip python3-venv \
  > /dev/null 2>&1
echo "  Done."

# ---------- 2. Rust toolchain ----------
echo ""
echo "[2/6] Installing Rust toolchain..."
if command -v rustup &>/dev/null; then
  echo "  Rust already installed: $(rustc --version)"
  rustup update stable --no-self-update > /dev/null 2>&1
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  source "$HOME/.cargo/env"
  echo "  Installed: $(rustc --version)"
fi

# WASM target for the Leptos frontend
rustup target add wasm32-unknown-unknown > /dev/null 2>&1
echo "  wasm32-unknown-unknown target ready."

# ---------- 3. Trunk (frontend builder) ----------
echo ""
echo "[3/6] Installing Trunk..."
if command -v trunk &>/dev/null; then
  echo "  Trunk already installed: $(trunk --version)"
else
  cargo install trunk --locked 2>&1 | tail -1
  echo "  Installed: $(trunk --version)"
fi

# ---------- 4. Build frontend ----------
echo ""
echo "[4/6] Building WASM frontend..."
cd "$BOT_DIR/frontend"
trunk build --release 2>&1 | tail -5
echo "  Frontend built -> frontend/dist/"
cd "$BOT_DIR"

# ---------- 5. Build Rust binaries ----------
echo ""
echo "[5/6] Building Rust bot (release mode)..."
cargo build --release 2>&1 | tail -5
echo "  Binaries built -> target/release/"
echo "  Available binaries:"
ls -1 target/release/main_* target/release/test_* target/release/backtest 2>/dev/null | sed 's|target/release/|    |'

# ---------- 6. Python environment for clob_generator ----------
echo ""
echo "[6/6] Setting up Python environment for CLOB credential generator..."
cd "$BOT_DIR"
python3 -m venv .venv
source .venv/bin/activate
pip install --quiet py-clob-client python-dotenv pydantic web3
deactivate
echo "  Python venv ready at .venv/"

# ---------- Config file check ----------
echo ""
echo "============================================"
echo " BUILD COMPLETE"
echo "============================================"
echo ""

if [ ! -f "$BOT_DIR/.env" ]; then
  echo "[SETUP NEEDED] Create .env with your Polymarket keys:"
  echo ""
  echo "  cat > $BOT_DIR/.env << 'EOF'"
  echo "  POLYMARKET_PRIVATE_SIGNER_KEY=0xYOUR_PRIVATE_KEY"
  echo "  POLYMARKET_PUBLIC_SIGNER_KEY=0xYOUR_PUBLIC_KEY"
  echo "  POLYMARKET_PROXY_ADDRESS=0xYOUR_PROXY_ADDRESS"
  echo "  EOF"
  echo ""
else
  echo "[OK] .env file found."
fi

if [ ! -f "$BOT_DIR/config.json" ]; then
  echo "[SETUP NEEDED] Create config.json with your CLOB API credentials."
  echo "  First generate them:  source .venv/bin/activate && python clob_generator.py"
  echo "  Then copy the output into config.json (see config.example.json)"
  echo ""
else
  echo "[OK] config.json found."
fi

echo "--------------------------------------------"
echo " Quick start commands:"
echo "--------------------------------------------"
echo ""
echo " 1) Generate CLOB API keys (one-time):"
echo "    source .venv/bin/activate && python clob_generator.py"
echo ""
echo " 2) Run copy-trading bot in tmux:"
echo "    tmux new -s bot"
echo "    ./target/release/main_copytrading --config config.json --trade-config trade.toml"
echo "    # Detach: Ctrl+B then D | Reattach: tmux attach -t bot"
echo ""
echo " 3) Run sports trailing bot:"
echo "    ./target/release/main_sports_trailing --config config.json --no-simulation"
echo ""
echo " 4) Install as systemd service (auto-start on reboot):"
echo "    sudo bash deploy/install-service.sh"
echo ""
echo " 5) Web UI available at: http://$(hostname -I | awk '{print $1}'):8000"
echo ""
