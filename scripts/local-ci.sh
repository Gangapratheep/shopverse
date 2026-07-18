#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR/backend"
echo "[1/4] Running Go tests"
go mod tidy
go test ./...

cd "$ROOT_DIR/frontend"
echo "[2/4] Installing frontend dependencies"
npm install

echo "[3/4] Running frontend lint"
npx eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0 --config .eslintrc.cjs

echo "[4/4] Building Docker images"
cd "$ROOT_DIR"
docker build -t shopverse-frontend:local ./frontend
docker build -t shopverse-backend:local ./backend

echo "Local CI checks completed successfully."
