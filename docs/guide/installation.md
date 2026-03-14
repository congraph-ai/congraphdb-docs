# Installation

CongraphDB is distributed as an npm package with prebuilt native binaries for multiple platforms.

## Requirements

- **Node.js** 20 or later
- **npm** or **yarn** package manager

## Supported Platforms

| Platform | Architecture | Status |
|----------|--------------|--------|
| Windows | x64 | :white_check_mark: Supported |
| macOS | x64, arm64 | :white_check_mark: Supported |
| Linux | x64, arm64 | :white_check_mark: Supported |

## Install via npm

```bash
npm install @congraph-ai/congraphdb
```

## Install via yarn

```bash
yarn add @congraph-ai/congraphdb
```

## Verify Installation

Create a test file `test.js`:

```javascript
const { Database } = require('@congraph-ai/congraphdb');

console.log('CongraphDB version:', Database.getVersion());
```

Run it:

```bash
node test.js
```

You should see the version number printed.

## Next Steps

- [Quick Start](quick-start.md) — Learn the basics with a simple example
- [Schemas](schemas.md) — Define your graph schema
