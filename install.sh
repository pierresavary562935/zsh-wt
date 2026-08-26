#!/usr/bin/env sh
# Append the source line for wt to ~/.zshrc, unless it is already there.
set -e

dir=$(cd "$(dirname "$0")" && pwd)
line="source $dir/wt.plugin.zsh"
rc="${ZDOTDIR:-$HOME}/.zshrc"

command -v fzf >/dev/null 2>&1 || echo "warning: fzf is not installed — wt needs it (brew install fzf)"

if [ -f "$rc" ] && grep -qF "$line" "$rc"; then
  echo "already installed in $rc"
else
  printf '\n# wt — jump between git worktrees\n%s\n' "$line" >> "$rc"
  echo "added to $rc"
fi

echo "run: source $rc"
