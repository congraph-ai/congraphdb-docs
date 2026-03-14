#!/bin/bash
# Generate TypeScript API docs using TypeDoc
# Usage: ./scripts/generate-typedoc.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TYPEDEF_FILE="$SCRIPT_DIR/index.d.ts"
OUTPUT_DIR="$PROJECT_ROOT/docs/api/javascript"

echo "Generating TypeScript API docs..."

# Check if typedoc is installed
if ! command -v typedoc &> /dev/null; then
    echo "Warning: typedoc not found. Installing..."
    npm install
fi

# Check if type definition file exists
if [ ! -f "$TYPEDEF_FILE" ]; then
    echo "Warning: index.d.ts not found at $TYPEDEF_FILE"
    echo "Skipping TypeScript API generation..."
    exit 0
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run TypeDoc
typedoc --options "$SCRIPT_DIR/typedoc.json" "$TYPEDEF_FILE" --out "$OUTPUT_DIR"

echo "TypeScript API docs generated to $OUTPUT_DIR"
