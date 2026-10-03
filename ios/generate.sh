#!/usr/bin/env bash
# Generates LifeDots.xcodeproj from project.yml and opens it.
# Uses an installed `xcodegen` if present; otherwise downloads it into .tools/
# (no Homebrew or admin rights needed). Pass --no-open to skip opening Xcode.
set -euo pipefail
cd "$(dirname "$0")"

if command -v xcodegen >/dev/null 2>&1; then
    XG="xcodegen"
else
    XG=".tools/xcodegen/bin/xcodegen"
    if [[ ! -x "$XG" ]]; then
        echo "Downloading XcodeGen…"
        mkdir -p .tools
        curl -fsSL https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip -o .tools/xcodegen.zip
        unzip -q -o .tools/xcodegen.zip -d .tools
    fi
fi

"$XG" generate
[[ "${1:-}" == "--no-open" ]] || open LifeDots.xcodeproj
