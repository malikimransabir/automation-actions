#!/bin/bash
# ---------------------------------------------------------------------------
# Qbric Test Generator (pipeline-2)
#
# Analyses the repository structure to determine which test files are missing,
# then reports the findings. When QBRIC_DRY_RUN=true no files are written.
#
# ---------------------------------------------------------------------------
set -uo pipefail

SCAN_PATH="${1:-.}"

QBRIC_MODE="${QBRIC_MODE:-auto}"
QBRIC_FRAMEWORK="${QBRIC_FRAMEWORK:-auto-detect}"
QBRIC_DRY_RUN="${QBRIC_DRY_RUN:-false}"
REPO_FULL_NAME="${REPO_FULL_NAME:-unknown/unknown}"
REF_NAME="${REF_NAME:-}"
COMMIT_SHA="${COMMIT_SHA:-}"

echo "================================="
echo " Qbric Test Generator (pipeline)"
echo "================================="
echo "repo:      $REPO_FULL_NAME"
echo "path:      $SCAN_PATH"
echo "mode:      $QBRIC_MODE"
echo "framework: $QBRIC_FRAMEWORK"
echo "dry-run:   $QBRIC_DRY_RUN"
echo "commit:    $COMMIT_SHA"
echo

# ── auto-detect framework ───────────────────────────────────────────────────
detected_framework="$QBRIC_FRAMEWORK"
if [ "$QBRIC_FRAMEWORK" = "auto-detect" ]; then
  if [ -f "$SCAN_PATH/pom.xml" ]; then
    detected_framework="JUnit/Maven"
  elif find "$SCAN_PATH" -name 'build.gradle*' -not -path '*/.git/*' | grep -q .; then
    detected_framework="JUnit/Gradle"
  elif [ -f "$SCAN_PATH/package.json" ]; then
    pkg="$SCAN_PATH/package.json"
    if grep -q '"jest"' "$pkg" 2>/dev/null; then
      detected_framework="Jest"
    elif grep -q '"mocha"' "$pkg" 2>/dev/null; then
      detected_framework="Mocha"
    else
      detected_framework="Node/unknown"
    fi
  else
    detected_framework="unknown"
  fi
  echo "Auto-detected framework: $detected_framework"
fi

# ── find source files without a matching test ───────────────────────────────
echo "Scanning for untested source files..."

missing_tests=()

# Java: src/main/java/**/*.java that lack a matching src/test/java/**/*Test.java
while IFS= read -r src_file; do
  class_name=$(basename "$src_file" .java)
  test_candidate=$(echo "$src_file" | sed 's|src/main/java|src/test/java|g' | sed "s|${class_name}.java|${class_name}Test.java|g")
  if [ ! -f "$test_candidate" ]; then
    missing_tests+=("$src_file")
  fi
done < <(find "$SCAN_PATH/src/main/java" -name '*.java' -not -path '*/.git/*' 2>/dev/null || true)

# Node/TS: src/**/*.ts that lack a matching *.test.ts / *.spec.ts
while IFS= read -r src_file; do
  base="${src_file%.ts}"
  if [ ! -f "${base}.test.ts" ] && [ ! -f "${base}.spec.ts" ]; then
    missing_tests+=("$src_file")
  fi
done < <(find "$SCAN_PATH/src" -name '*.ts' -not -name '*.test.ts' -not -name '*.spec.ts' \
          -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null || true)

total_missing=${#missing_tests[@]}
echo "Framework:       $detected_framework"
echo "Missing tests:   $total_missing file(s)"

if [ "$total_missing" -gt 0 ]; then
  echo
  echo "Files without matching tests (first 20):"
  for f in "${missing_tests[@]:0:20}"; do
    echo "  - $f"
  done
fi

# ── dry-run gate ─────────────────────────────────────────────────────────────
if [ "$QBRIC_DRY_RUN" = "true" ]; then
  echo
  echo "[dry-run] Analysis complete — no test files written."
  echo "Qbric Test Generator completed (dry-run)."
  exit 0
fi

echo
echo "Qbric Test Generator completed."
