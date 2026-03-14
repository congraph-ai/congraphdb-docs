#!/bin/bash
# Sync API docs from main congraphdb repository
# Usage: ./scripts/sync-api-docs.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MAIN_REPO_PATH="$PROJECT_ROOT/../congraphdb"

echo "Syncing API docs from $MAIN_REPO_PATH"

# Check if main repo exists
if [ ! -d "$MAIN_REPO_PATH" ]; then
    echo "Warning: Main repository not found at $MAIN_REPO_PATH"
    echo "Skipping API sync..."
    exit 0
fi

# Copy TypeScript definitions
if [ -f "$MAIN_REPO_PATH/index.d.ts" ]; then
    echo "Copying index.d.ts..."
    cp "$MAIN_REPO_PATH/index.d.ts" "$SCRIPT_DIR/"
else
    echo "Warning: index.d.ts not found"
fi

# Copy README for reference
if [ -f "$MAIN_REPO_PATH/README.md" ]; then
    echo "Copying README.md..."
    cp "$MAIN_REPO_PATH/README.md" "$SCRIPT_DIR/"
fi

# Copy CHANGELOG for releases
if [ -f "$MAIN_REPO_PATH/CHANGELOG.md" ]; then
    echo "Copying CHANGELOG.md..."
    cp "$MAIN_REPO_PATH/CHANGELOG.md" "$PROJECT_ROOT/docs/releases/changelog.md"
fi

echo "API sync complete!"
