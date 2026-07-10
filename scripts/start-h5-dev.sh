#!/usr/bin/env bash
# 启动 H5 归档 PeachGen 本地 dev server（Vite :5173）。
set -euo pipefail

H5_DIR="${H5_DIR:-/Users/macbookpro/Desktop/H5归档/h5}"

if [[ ! -d "${H5_DIR}" ]]; then
  echo "H5 目录不存在: ${H5_DIR}" >&2
  exit 1
fi

cd "${H5_DIR}"
if [[ ! -d node_modules ]]; then
  echo "Installing npm dependencies..."
  npm install
fi

echo "Starting H5 dev server at http://localhost:5173/"
echo "Runtime cfg (native Debug): https://raw.githubusercontent.com/wwqxs/TXDNF/refs/heads/main/888886.json"
npm run dev
