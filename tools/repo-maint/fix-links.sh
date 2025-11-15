#!/usr/bin/env bash
# Semi-automatic link fixer for this repo.
#
# This script applies a small set of **targeted** replacements to fix
# known-bad path patterns that were revealed by lychee.
#
# It is intentionally conservative: it only replaces exact strings that we
# know are wrong in specific files / contexts. After running, review the
# changes with `git diff` before committing.
#
# Usage:
#   tools/repo-maint/fix-links.sh

set -euo pipefail

# Move to repo root if inside a git repo; otherwise stay in current dir
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

replace_in_file() {
  file="$1"
  old="$2"
  new="$3"

  if [ ! -f "$file" ]; then
    echo "[WARN] File not found: $file (skipping)" >&2
    return
  fi

  if ! grep -q -- "$old" "$file"; then
    echo "[INFO] Pattern not found in $file: $old (skipping)" >&2
    return
  fi

  echo "[FIX] $file: '$old' -> '$new'"
  tmp="${file}.tmp.fixlinks"
  # Use '|' as the sed delimiter to avoid clashing with '/'
  sed "s|$old|$new|g" "$file" > "$tmp"
  mv "$tmp" "$file"
}

###############################################################################
# 1) Global fix: wrong 'ha-assets/quirks/blueprints' path
#
# We no longer have a 'ha-assets/quirks/blueprints' directory; the correct
# path is 'ha-assets/blueprints'. This showed up in README.md and tools/README.md
# (and possibly elsewhere), so we apply this replacement to all Markdown files.
###############################################################################

for f in $(find . -type f -name "*.md"); do
  replace_in_file "$f" "ha-assets/quirks/blueprints" "ha-assets/blueprints"
done

###############################################################################
# 2) Fix link from TS004F blueprint README to device research
#
# In ha-assets/blueprints/tuya-ts004f/README.md we want a **relative** link to
# the TS004F research directory under research/zigbee/devices/tuya-ts004f/.
# The correct path from that README is:
#   ../../research/zigbee/devices/tuya-ts004f/
###############################################################################

replace_in_file \
  "ha-assets/blueprints/tuya-ts004f/README.md" \
  "/research/zigbee/devices/tuya-ts004f" \
  "../../research/zigbee/devices/tuya-ts004f/"

###############################################################################
# 3) Fix links inside research/zigbee/devices/tuya-ts004f/README.md
#
# From research/zigbee/devices/tuya-ts004f/ to the repo root is four levels:
#   ../../../../
#
# From repo root to the blueprints and tools we want to link to:
#   ha-assets/blueprints/tuya-ts004f/...
#   tools/zigbee/...
#
# So the correct relative paths are e.g.:
#   ../../../../ha-assets/blueprints/tuya-ts004f/
#   ../../../../tools/zigbee/capture_ts004f_events.sh
###############################################################################

TS004F_README="research/zigbee/devices/tuya-ts004f/README.md"

# Blueprint directory link
replace_in_file \
  "$TS004F_README" \
  "../ha-assets/quirks/blueprints/tuya-ts004f" \
  "../../../../ha-assets/blueprints/tuya-ts004f"

# Specific blueprint comparison doc
replace_in_file \
  "$TS004F_README" \
  "../ha-assets/quirks/blueprints/tuya-ts004f/blueprint-comparison.md" \
  "../../../../ha-assets/blueprints/tuya-ts004f/blueprint-comparison.md"

# Event coverage audit doc
replace_in_file \
  "$TS004F_README" \
  "../ha-assets/quirks/blueprints/tuya-ts004f/event-coverage-audit.md" \
  "../../../../ha-assets/blueprints/tuya-ts004f/event-coverage-audit.md"

# Tools: capture script
replace_in_file \
  "$TS004F_README" \
  "../tools/zigbee/capture_ts004f_events.sh" \
  "../../../../tools/zigbee/capture_ts004f_events.sh"

# Tools: log formatting script
replace_in_file \
  "$TS004F_README" \
  "../tools/zigbee/ha_zigbee_logfmt.sh" \
  "../../../../tools/zigbee/ha_zigbee_logfmt.sh"

###############################################################################
# Done
###############################################################################

echo "[INFO] Link fix pass complete. Review changes with 'git diff' before committing."