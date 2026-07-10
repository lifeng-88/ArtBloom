#!/usr/bin/env bash
# Debug 构建安装后，用 simctl 注入本地 H5 地址并启动 ArtBloom。
# 前置：模拟器已 boot，且 H5 已在本地运行（如 npm run dev → :5173）。

set -euo pipefail

H5_URL="${APP_H5_URL:-http://localhost:5173/}"
CHANNEL="${APP_CHANNEL:-888886}"
CFG_URL="${APP_CFG_URL:-https://raw.githubusercontent.com/wwqxs/TXDNF/refs/heads/main/888886.json}"
BUNDLE_ID="${BUNDLE_ID:-com.artbloom.app}"

echo "Launching ${BUNDLE_ID}"
echo "  APP_H5_URL=${H5_URL}"
echo "  APP_CHANNEL=${CHANNEL}"
echo "  APP_CFG_URL=${CFG_URL}"

SIMCTL_CHILD_APP_H5_URL="${H5_URL}" \
SIMCTL_CHILD_APP_CHANNEL="${CHANNEL}" \
SIMCTL_CHILD_APP_CFG_URL="${CFG_URL}" \
xcrun simctl launch --terminate-running-process booted "${BUNDLE_ID}"
