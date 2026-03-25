#!/usr/bin/env bash
# =============================================================================
# Upload project to VPS from local machine.
# Usage: bash deploy/upload.sh <VPS_IP> [SSH_USER]
#
# On Windows, run from Git Bash or WSL:
#   bash deploy/upload.sh 123.45.67.89
# =============================================================================
set -euo pipefail

VPS_IP="${1:?Usage: bash deploy/upload.sh <VPS_IP> [SSH_USER]}"
SSH_USER="${2:-root}"
REMOTE_DIR="/root/bot"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Uploading project to $SSH_USER@$VPS_IP:$REMOTE_DIR ..."

# Use rsync if available (faster for updates), fall back to scp
if command -v rsync &>/dev/null; then
  rsync -avz --progress \
    --exclude 'target/' \
    --exclude 'frontend/target/' \
    --exclude 'frontend/dist/' \
    --exclude '.git/' \
    --exclude '.venv/' \
    --exclude '__pycache__/' \
    --exclude 'node_modules/' \
    --exclude '.env.txt' \
    --exclude 'config.json' \
    --exclude 'temp.json' \
    "$PROJECT_DIR/" "$SSH_USER@$VPS_IP:$REMOTE_DIR/"
else
  echo "(rsync not found, using scp - this is slower)"
  ssh "$SSH_USER@$VPS_IP" "mkdir -p $REMOTE_DIR"
  scp -r \
    "$PROJECT_DIR/src" \
    "$PROJECT_DIR/frontend" \
    "$PROJECT_DIR/lib" \
    "$PROJECT_DIR/deploy" \
    "$PROJECT_DIR/Cargo.toml" \
    "$PROJECT_DIR/Cargo.lock" \
    "$PROJECT_DIR/trade.toml" \
    "$PROJECT_DIR/clear.toml" \
    "$PROJECT_DIR/config.example.json" \
    "$PROJECT_DIR/pyproject.toml" \
    "$PROJECT_DIR/pdm.lock" \
    "$PROJECT_DIR/clob_generator.py" \
    "$PROJECT_DIR/.env.example" \
    "$PROJECT_DIR/.gitignore" \
    "$SSH_USER@$VPS_IP:$REMOTE_DIR/"
fi

echo ""
echo "Upload complete! Now SSH in and run setup:"
echo ""
echo "  ssh $SSH_USER@$VPS_IP"
echo "  cd $REMOTE_DIR"
echo "  bash deploy/setup-vps.sh"
echo ""
