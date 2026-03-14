#!/bin/bash
# Copy CHANGELOG from main repository
# Usage: ./scripts/copy-changelog.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAIN_REPO_PATH="$PROJECT_ROOT/../congraphdb"

echo "Copying CHANGELOG from main repository..."

# Check if main repo exists
if [ ! -d "$MAIN_REPO_PATH" ]; then
    echo "Warning: Main repository not found at $MAIN_REPO_PATH"
    exit 0
fi

# Copy CHANGELOG
if [ -f "$MAIN_REPO_PATH/CHANGELOG.md" ]; then
    cp "$MAIN_REPO_PATH/CHANGELOG.md" "$PROJECT_ROOT/docs/releases/changelog.md"
    echo "CHANGELOG.md copied successfully"
else
    echo "Warning: CHANGELOG.md not found in main repository"
fi
