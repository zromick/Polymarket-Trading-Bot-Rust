#!/usr/bin/env bash
# Install the bot as a systemd service so it auto-starts on reboot.
# Usage: sudo bash deploy/install-service.sh
set -euo pipefail

BOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_FILE="$BOT_DIR/deploy/polymarket-bot.service"

# Update paths in service file to match actual bot location
sed "s|WorkingDirectory=.*|WorkingDirectory=$BOT_DIR|" "$SERVICE_FILE" \
  | sed "s|EnvironmentFile=.*|EnvironmentFile=$BOT_DIR/.env|" \
  | sed "s|ExecStart=.*|ExecStart=$BOT_DIR/target/release/main_copytrading --config config.json --trade-config trade.toml --ui-dir $BOT_DIR/frontend/dist|" \
  > /etc/systemd/system/polymarket-bot.service

systemctl daemon-reload
systemctl enable polymarket-bot.service

echo "Service installed. Commands:"
echo "  sudo systemctl start polymarket-bot    # start now"
echo "  sudo systemctl stop polymarket-bot     # stop"
echo "  sudo systemctl status polymarket-bot   # check status"
echo "  sudo journalctl -u polymarket-bot -f   # live logs"
