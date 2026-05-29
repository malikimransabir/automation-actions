#!/bin/bash

SCAN_PATH=$1

echo "================================="
echo "Qbric Repository Scanner"
echo "================================="

echo "Scanning path: $SCAN_PATH"

echo ""
echo "Listing repository files..."
find "$SCAN_PATH" -type f

echo ""
echo "Checking TODO comments..."
grep -R "TODO" "$SCAN_PATH" || true

echo ""
echo "Checking secrets..."

if grep -R "password=" "$SCAN_PATH"; then
  echo "Potential secret detected"
  exit 1
fi

echo ""
echo "Qbric scan completed successfully"