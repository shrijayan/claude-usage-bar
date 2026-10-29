#!/usr/bin/env bash
# Install claude-usage-bar as the Claude Code status line.
#   curl -fsSL https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main/install.sh | bash
#   ... | bash -s -- --uninstall
set -euo pipefail
REPO_RAW="https://raw.githubusercontent.com/shrijayan/claude-usage-bar/main"
DIR="$HOME/.claude"
SCRIPT="$DIR/claude-usage-bar.sh"
SETTINGS="$DIR/settings.json"
BACKUP="$DIR/settings.json.claude-usage-bar.bak"

command -v jq >/dev/null || { echo "claude-usage-bar needs jq (brew install jq / apt install jq)" >&2; exit 1; }
mkdir -p "$DIR"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

if [ "${1:-}" = "--uninstall" ]; then
  if [ -f "$BACKUP" ]; then
    prev=$(jq '.statusLine' "$BACKUP")
    jq --argjson p "$prev" 'if $p == null then del(.statusLine) else .statusLine = $p end' "$SETTINGS" > "$SETTINGS.tmp"
    command rm -f "$BACKUP"
  else
    jq 'del(.statusLine)' "$SETTINGS" > "$SETTINGS.tmp"
  fi
  mv "$SETTINGS.tmp" "$SETTINGS"; command rm -f "$SCRIPT"
  echo "claude-usage-bar removed; previous status line restored."; exit 0
fi

src="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)/statusline.sh"
if [ -f "$src" ]; then cp "$src" "$SCRIPT"; else curl -fsSL "$REPO_RAW/statusline.sh" -o "$SCRIPT"; fi
chmod +x "$SCRIPT"

[ -f "$BACKUP" ] || cp "$SETTINGS" "$BACKUP"
jq --arg c "$SCRIPT" '.statusLine = {type: "command", command: $c, padding: 0, refreshInterval: 1}' \
  "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
echo "claude-usage-bar installed. Restart Claude Code to see it."
echo "Old settings backed up to $BACKUP"
