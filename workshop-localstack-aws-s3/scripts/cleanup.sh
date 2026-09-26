#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🧹 LocalStack ve Backend kaynaklari temizleniyor..."
cd "${PARENT_DIR}"
docker compose down -v
echo "✅ Tum konteynerler, aglar ve LocalStack diskleri temizlendi."
