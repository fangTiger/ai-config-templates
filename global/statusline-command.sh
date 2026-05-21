#!/bin/bash
input=$(cat)
model_name=$(echo "$input" | jq -r '.model.display_name')
version=$(echo "$input" | jq -r '.version')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
context_window=$(echo "$input" | jq '.context_window')
current_usage=$(echo "$context_window" | jq '.current_usage')
window_size=$(echo "$context_window" | jq -r '.context_window_size')

if [ "$current_usage" != "null" ]; then
    input_tokens=$(echo "$current_usage" | jq '.input_tokens // 0')
    cache_creation=$(echo "$current_usage" | jq '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$current_usage" | jq '.cache_read_input_tokens // 0')
    current_total=$((input_tokens + cache_creation + cache_read))
    context_pct=$((current_total * 100 / window_size))
    context_display="${current_total}/${window_size} (${context_pct}%)"
else
    context_display="0/${window_size} (0%)"
fi

cost_total=$(echo "$input" | jq -r '.cost.total_cost_usd // "0.00"')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // "0"')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // "0"')

if [[ "$current_dir" == "$HOME"* ]]; then
    display_dir="~${current_dir#$HOME}"
else
    display_dir="$current_dir"
fi

cd "$current_dir" 2>/dev/null
git_branch=$(git branch --show-current 2>/dev/null || echo "no-git")

printf "\033[36m%s\033[0m | " "$model_name"
printf "\033[90m%s\033[0m | " "v$version"
printf "\033[33m%s\033[0m | " "$display_dir"
printf "\033[35m%s\033[0m | " "$git_branch"
printf "\033[32mContext: %s\033[0m | " "$context_display"
printf "\033[35mCost: \$%s\033[0m | " "$cost_total"
printf "\033[34m+%s/-%s lines\033[0m" "$lines_added" "$lines_removed"
