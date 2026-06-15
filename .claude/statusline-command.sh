#!/bin/bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

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

format_limit() {
  local pct="$1"
  local reset_epoch="$2"
  local label="$3"
  [ -z "$pct" ] && return
  local pct_int
  pct_int=$(printf "%.0f" "$pct")
  local color
  if [ "$pct_int" -ge 90 ]; then
    color=$'\033[0;31m'
  elif [ "$pct_int" -ge 70 ]; then
    color=$'\033[0;33m'
  else
    color=$'\033[0;32m'
  fi
  local reset_str=""
  if [ -n "$reset_epoch" ]; then
    reset_str="→$(TZ=Asia/Tokyo date -d "@${reset_epoch}" +%H:%M 2>/dev/null)"
  fi
  printf '%s%s:%d%%%s%s' "$color" "$label" "$pct_int" "$reset_str" $'\033[0m'
}

five_hour_str=$(format_limit "$five_hour_pct" "$five_hour_reset" "5h")
seven_day_str=$(format_limit "$seven_day_pct" "$seven_day_reset" "7d")

limits_str=""
if [ -n "$five_hour_str" ] || [ -n "$seven_day_str" ]; then
  limits_str=" | ${five_hour_str}"
  [ -n "$five_hour_str" ] && [ -n "$seven_day_str" ] && limits_str="${limits_str} ${seven_day_str}"
  [ -z "$five_hour_str" ] && limits_str=" | ${seven_day_str}"
fi

printf "%s | %s | %s%s\n" "$cwd" "$model" "$ctx_str" "$limits_str"
