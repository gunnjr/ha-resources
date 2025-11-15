#!/bin/bash
# =============================================================================
# Home Assistant Log Retrieval Script
# =============================================================================
# This script retrieves log files from Home Assistant's /share/ha-tools/logs
# directory and stores them locally in the captured_logs directory.
#
# USAGE:
#   ./ha_get_logs.sh <file_pattern>
#
# EXAMPLES:
#   ./ha_get_logs.sh "*.log"           # Get all .log files
#   ./ha_get_logs.sh "zigbee_*.log"    # Get all zigbee logs
#   ./ha_get_logs.sh "specific.log"    # Get a specific file
#
# =============================================================================

# Configuration (matching Makefile)
HA_HOST="homeassistant.local"
HA_USER="hassio"
HA_LOG_DIR="/share/ha-tools/logs"
LOCAL_LOG_DIR="captured_logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if pattern parameter was provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No file pattern specified${NC}"
    echo ""
    echo "Usage: $0 <file_pattern>"
    echo ""
    echo "Examples:"
    echo "  $0 '*.log'              # Get all .log files"
    echo "  $0 'zigbee_*.log'       # Get all zigbee logs"
    echo "  $0 'specific.log'       # Get a specific file"
    exit 1
fi

FILE_PATTERN="$1"

# Get the script's directory to determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create local log directory if it doesn't exist
LOCAL_LOG_PATH="$PROJECT_ROOT/$LOCAL_LOG_DIR"
mkdir -p "$LOCAL_LOG_PATH"

echo "=== Home Assistant Log Retrieval ==="
echo ""
echo "Configuration:"
echo "  HA Host:        $HA_USER@$HA_HOST"
echo "  Remote dir:     $HA_LOG_DIR"
echo "  Pattern:        $FILE_PATTERN"
echo "  Local dir:      $LOCAL_LOG_PATH"
echo ""

# Check if remote directory exists and get matching files
echo "Checking for matching files on Home Assistant..."
MATCHING_FILES=$(ssh "$HA_USER@$HA_HOST" "ls $HA_LOG_DIR/$FILE_PATTERN 2>/dev/null" 2>&1)
SSH_EXIT_CODE=$?

if [ $SSH_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Error: Failed to connect to Home Assistant or no files match pattern${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check that SSH key authentication is set up"
    echo "  2. Verify Home Assistant is accessible: ssh $HA_USER@$HA_HOST"
    echo "  3. Check if files exist: ssh $HA_USER@$HA_HOST 'ls $HA_LOG_DIR'"
    exit 1
fi

if [ -z "$MATCHING_FILES" ]; then
    echo -e "${YELLOW}No files matching '$FILE_PATTERN' found in $HA_LOG_DIR${NC}"
    exit 0
fi

# Display matching files
echo ""
echo "Found matching files:"
echo "$MATCHING_FILES" | while read -r file; do
    echo "  → $(basename "$file")"
done
echo ""

# Copy files using SSH and cat (compatible with 1Password SSH agent)
echo "Copying files..."
FILE_COUNT=0
while IFS= read -r remote_file; do
    if [ -n "$remote_file" ]; then
        filename=$(basename "$remote_file")
        # Use ssh with cat to transfer the file (same approach as Makefile)
        if ssh "$HA_USER@$HA_HOST" "cat $remote_file" > "$LOCAL_LOG_PATH/$filename" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $filename"
            ((FILE_COUNT++))
        else
            echo -e "  ${RED}✗${NC} $filename (copy failed)"
        fi
    fi
done <<< "$MATCHING_FILES"

echo ""
if [ $FILE_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Successfully copied $FILE_COUNT file(s) to $LOCAL_LOG_DIR/${NC}"
else
    echo -e "${YELLOW}No files were copied${NC}"
fi
