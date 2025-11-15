#!/usr/bin/env bash
# Lightweight wrapper around lychee to check Markdown links in this repo.
#
# Usage:
#   tools/repo-maint/check-links.sh          # check internal links only
#   tools/repo-maint/check-links.sh --all    # check all links, including external HTTP(S)
#   tools/repo-maint/check-links.sh --help   # show help
#
# This script assumes it is located somewhere inside a git repo. It will
# automatically cd to the repo root before running lychee.

set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [--all]

Options:
  --all        Check all links, including external HTTP(S) URLs.
               Default is to check only internal file paths.

Notes:
  - Run this script from anywhere inside the git repo; it will
    automatically switch to the repo root.
  - Requires: lychee (https://github.com/lycheeverse/lychee)
EOF
}

MODE="internal"

while [ "${1-}" != "" ]; do
  case "$1" in
    --all)
      MODE="all"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "[WARN] Unknown argument: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

if ! command -v lychee >/dev/null 2>&1; then
  echo "[ERROR] 'lychee' not found in PATH. Install it first, e.g.:" >&2
  echo "       brew install lychee" >&2
  exit 1
fi

# Move to repo root if inside a git repo; otherwise stay in current dir
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

COMMON_ARGS=("--no-progress" "./**/*.md")

case "$MODE" in
  internal)
    echo "[INFO] Checking INTERNAL links only (file paths within repo)..."
    echo "       External HTTP(S) links are excluded for now."
    lychee --exclude "https?://.*" "${COMMON_ARGS[@]}"
    ;;
  all)
    echo "[INFO] Checking ALL links (internal + external)..."
    echo "       Placeholder and known noisy URLs may still fail; you can add" >&2
    echo "       more --exclude patterns inside this script if needed." >&2
    lychee "${COMMON_ARGS[@]}"
    ;;
  *)
    echo "[ERROR] Unknown mode: $MODE" >&2
    exit 1
    ;;
esac
