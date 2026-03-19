#!/bin/bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Build context usage string
if [ -n "$used" ] && [ -n "$remaining" ]; then
  used_int=$(printf "%.0f" "$used")
  remaining_int=$(printf "%.0f" "$remaining")

  # Color coding based on remaining percentage
  if [ "$remaining_int" -le 10 ]; then
    ctx_color=$'\033[0;31m'   # Red: critical
  elif [ "$remaining_int" -le 25 ]; then
    ctx_color=$'\033[0;33m'   # Yellow: warning
  else
    ctx_color=$'\033[0;32m'   # Green: ok
  fi
  reset=$'\033[0m'
  ctx_str="${ctx_color}Context: ${used_int}% used / ${remaining_int}% remaining${reset}"
else
  ctx_str="Context: --"
fi

printf "%s | %s | %s\n" "$cwd" "$model" "$ctx_str"
