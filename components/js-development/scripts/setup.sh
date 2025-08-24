#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if ! command -v npm >/dev/null 2>&1; then
  ui_warning "$(fmt "js_dev_npm_not_found_skip")"
  exit 0
fi

ui_action_start "$(fmt "js_dev_configuring")"

ui_info "$(fmt "js_dev_configuring_npm")"

npm config set init.author.name "$(git config user.name 2>/dev/null || echo "")" 2>/dev/null || true
npm config set init.author.email "$(git config user.email 2>/dev/null || echo "")" 2>/dev/null || true
npm config set init.license "MIT" 2>/dev/null || true
npm config set init.version "0.1.0" 2>/dev/null || true

ui_info "$(fmt "js_dev_configuring_typescript")"

mkdir -p "$HOME/.config/typescript" 2>/dev/null || true

if [[ ! -f "$HOME/.config/typescript/tsconfig.json" ]]; then
  cat > "$HOME/.config/typescript/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
fi

ui_info "$(fmt "js_dev_configuring_eslint")"

if [[ ! -f "$HOME/.config/eslint/eslintrc.js" ]]; then
  mkdir -p "$HOME/.config/eslint" 2>/dev/null || true
  cat > "$HOME/.config/eslint/eslintrc.js" << 'EOF'
module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended'
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  plugins: [
    '@typescript-eslint'
  ],
  rules: {
    // Add your preferred rules here
  }
};
EOF
fi

ui_action_success "$(fmt "js_dev_configured_successfully")"
