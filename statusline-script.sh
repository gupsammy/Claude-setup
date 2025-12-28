#!/bin/bash

# Enhanced Claude Code Status Line Script
# Multi-line layout with weather, IST time, and improved formatting

# Read Claude Code JSON data from stdin
input=$(cat)

# Test input if none provided
if [ -z "$input" ]; then
  input='{"session_id":"test","model":{"id":"claude-sonnet-4","display_name":"Claude 4"},"output_style":{"name":"default"}}'
fi

# Minimal color palette - 3 contrasting colors for light/dark themes
PRIMARY='\033[96m'   # Cyan - primary info (bright, readable)
SECONDARY='\033[93m' # Yellow - secondary info (warm contrast)
ACCENT='\033[95m'    # Magenta - accents and highlights (pop color)
WHITE='\033[97m'     # White - for emphasis
GRAY='\033[90m'      # Gray - for subdued elements
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Legacy color aliases (mapped to new palette)
CYAN=$PRIMARY
YELLOW=$SECONDARY
MAGENTA=$ACCENT
GREEN=$PRIMARY
BLUE=$PRIMARY
RED=$ACCENT
ORANGE=$SECONDARY
PURPLE=$ACCENT
TEAL=$PRIMARY

# Cache directory
CACHE_DIR="$HOME/.claude/cache"
WEATHER_CACHE="$CACHE_DIR/weather.cache"
mkdir -p "$CACHE_DIR"

# Enhanced progress bar with color gradients
create_progress_bar() {
  local percentage=$1
  local width=${2:-10}
  local color=${3:-$WHITE}
  local filled=$((percentage * width / 100))
  local empty=$((width - filled))

  # Simplified color gradient based on percentage
  if [ $percentage -le 50 ]; then
    color=$PRIMARY # Cyan for low usage
  elif [ $percentage -le 75 ]; then
    color=$SECONDARY # Yellow for medium usage
  else
    color=$ACCENT # Magenta for high usage
  fi

  printf "${color}"
  for ((i = 0; i < filled; i++)); do printf "█"; done
  printf "${GRAY}"
  for ((i = 0; i < empty; i++)); do printf "░"; done
  printf "${RESET}"
}

# Progress bar with overlapped percentage text (left-aligned with padding)
create_progress_bar_with_percentage() {
  local percentage=$1
  local width=${2:-10}
  local color=${3:-$WHITE}
  local filled=$((percentage * width / 100))
  local empty=$((width - filled))

  # Simplified color gradient based on percentage
  if [ $percentage -le 50 ]; then
    color=$PRIMARY # Cyan for low usage
  elif [ $percentage -le 75 ]; then
    color=$SECONDARY # Yellow for medium usage
  else
    color=$ACCENT # Magenta for high usage
  fi

  local percentage_text="${percentage}%"
  local text_length=${#percentage_text}
  local padding_pos=1 # Start at position 1 for left padding

  # Build the progress bar first
  local bar=""
  for ((i = 0; i < filled; i++)); do bar="${bar}█"; done
  for ((i = filled; i < width; i++)); do bar="${bar}░"; done

  # Now overlay the percentage text with proper background colors
  local result=""
  for ((i = 0; i < width; i++)); do
    if [ $i -ge $padding_pos ] && [ $i -lt $((padding_pos + text_length)) ]; then
      # Get the character position in percentage text
      local char_pos=$((i - padding_pos))
      local char="${percentage_text:$char_pos:1}"

      # Use filled color if this position should be filled, otherwise use gray
      if [ $i -lt $filled ]; then
        result="${result}${color}${BOLD}${WHITE}${char}${RESET}"
      else
        result="${result}${GRAY}${BOLD}${WHITE}${char}${RESET}"
      fi
    else
      # Regular bar character
      local char="${bar:$i:1}"
      if [ $i -lt $filled ]; then
        result="${result}${color}${char}${RESET}"
      else
        result="${result}${GRAY}${char}${RESET}"
      fi
    fi
  done

  echo -n "${result}"
}

# Weather icon mapping for more playful display
get_weather_icon() {
  local weather_text="$1"
  case "$weather_text" in
  *"Sunny"* | *"Clear"*) echo "☀️" ;;
  *"Partly cloudy"* | *"Partly Cloudy"*) echo "⛅" ;;
  *"Cloudy"* | *"Overcast"*) echo "☁️" ;;
  *"Rain"* | *"Shower"* | *"Drizzle"*) echo "🌧️" ;;
  *"Snow"* | *"Blizzard"*) echo "❄️" ;;
  *"Thunder"* | *"Storm"*) echo "⛈️" ;;
  *"Fog"* | *"Mist"*) echo "🌫️" ;;
  *"Hot"*) echo "🔥" ;;
  *"Cold"*) echo "🥶" ;;
  *) echo "🌡️" ;;
  esac
}

# Get context percentage from Claude Code's direct JSON input
get_context_percentage() {
  local usage=$(echo "$input" | jq '.context_window.current_usage // null' 2>/dev/null)

  if [ "$usage" != "null" ] && [ -n "$usage" ]; then
    local input_tokens=$(echo "$usage" | jq '.input_tokens // 0' 2>/dev/null)
    local cache_create=$(echo "$usage" | jq '.cache_creation_input_tokens // 0' 2>/dev/null)
    local cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0' 2>/dev/null)
    local current=$((input_tokens + cache_create + cache_read))
    local size=$(echo "$input" | jq '.context_window.context_window_size // 200000' 2>/dev/null)

    if [ "$DEBUG" = "1" ]; then
      echo "DEBUG: Context - Input: $input_tokens, Cache Create: $cache_create, Cache Read: $cache_read, Total: $current, Size: $size" >&2
    fi

    if [ "$size" -gt 0 ] && [ "$current" -gt 0 ]; then
      local percentage=$((current * 100 / size))
      if [ $percentage -gt 100 ]; then percentage=100; fi
      echo "$percentage"
      return
    fi
  fi

  echo "0"
}

# Simple weather function
get_weather() {
  # Check cache age (30 minute cache)
  if [ -f "$WEATHER_CACHE" ]; then
    local cache_age=$(($(date +%s) - $(stat -f %m "$WEATHER_CACHE" 2>/dev/null || echo 0)))
    if [ $cache_age -lt 1800 ]; then
      cat "$WEATHER_CACHE" 2>/dev/null && return
    fi
  fi

  # Try to fetch new weather with timeout
  local weather_data=$(timeout 2s curl -s "http://wttr.in?format=%t+%C" 2>/dev/null || echo "")
  if [ -n "$weather_data" ] && [[ ! "$weather_data" =~ "Unknown location" ]]; then
    echo "$weather_data" | tee "$WEATHER_CACHE"
  else
    echo "Weather unavailable"
  fi
}

# Get MCP status for current project
get_mcp_status() {
  local current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' 2>/dev/null)
  if [ -z "$current_dir" ]; then
    current_dir="$PWD"
  fi

  local mcp_json="$current_dir/.mcp.json"
  local claude_json="$HOME/.claude.json"

  # Check if .mcp.json exists
  if [ ! -f "$mcp_json" ]; then
    echo ""
    return
  fi

  # Get all MCP names from .mcp.json
  local mcp_names=$(jq -r '.mcpServers | keys[]' "$mcp_json" 2>/dev/null)
  if [ -z "$mcp_names" ]; then
    echo ""
    return
  fi

  # Count total MCPs
  local total_count=$(echo "$mcp_names" | wc -l | tr -d ' ')

  # Get disabled MCPs for this project
  local disabled_mcps=$(jq -r --arg path "$current_dir" '.projects[$path].disabledMcpServers[]' "$claude_json" 2>/dev/null)

  # Count enabled MCPs (those NOT in disabled list)
  local enabled_count=0
  for mcp in $mcp_names; do
    local is_disabled=0
    for disabled in $disabled_mcps; do
      if [ "$mcp" = "$disabled" ]; then
        is_disabled=1
        break
      fi
    done

    if [ $is_disabled -eq 0 ]; then
      enabled_count=$((enabled_count + 1))
    fi
  done

  # Only return status if there are MCPs configured
  if [ $total_count -gt 0 ]; then
    echo "${enabled_count}/${total_count}"
  else
    echo ""
  fi
}

# Calculate basic info
IST_TIME=$(TZ=Asia/Kolkata date "+%H:%M")
DAY_NAME=$(date +%a)
# Calculate day percentage with intermediate variables for reliability
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)
# Force decimal interpretation to avoid octal issues with 08, 09
MINUTES_ELAPSED=$((10#$CURRENT_HOUR * 60 + 10#$CURRENT_MINUTE))
DAY_PERCENTAGE=$((MINUTES_ELAPSED * 100 / 1440))
WEATHER=$(get_weather)
CONTEXT_PERCENTAGE=$(get_context_percentage)
MCP_STATUS=$(get_mcp_status)

# Additional formatting
DATE_DD=$(date +%d)
MONTH_MON=$(date +%b)
# Get project directory from Claude Code JSON input
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // ""' 2>/dev/null)
if [ -n "$PROJECT_DIR" ]; then
  CURRENT_DIR=$(basename "$PROJECT_DIR")
else
  CURRENT_DIR=$(basename "$PWD")
fi

# Get weather with icon
WEATHER_ICON=$(get_weather_icon "$WEATHER")
WEATHER_TEMP=$(echo "$WEATHER" | grep -o '+[0-9]*°C\|[0-9]*°C\|-[0-9]*°C' || echo "")

# Get Spotify currently playing info
get_spotify_info() {
  # Try to get current Spotify track using AppleScript
  local current_track=""
  if command -v osascript >/dev/null 2>&1; then
    current_track=$(osascript -e 'tell application "Spotify"
            if it is running and player state is playing then
                get name of current track & " by " & artist of current track
            end if
        end tell' 2>/dev/null || echo "")
  fi

  if [ -n "$current_track" ] && [ "$current_track" != "" ]; then
    echo "$current_track"
  fi
}

# Rotating fun phrases for music
get_music_phrase() {
  local phrases=("🎵 now playing" "🎶 grooving to" "🎧 vibing to" "🎤 jamming to" "🔥 bumping")
  # Use seconds to rotate through phrases every 10 seconds
  local phrase_index=$((($(date +%s) / 10) % ${#phrases[@]}))
  echo "${phrases[$phrase_index]}"
}

# Get ending music emojis
get_music_emoji() {
  local emojis=("🎼" "🎹" "🥁" "🎸" "🎺" "🎷" "🎻" "✨" "💫" "🌟")
  # Use seconds to rotate through emojis every 8 seconds
  local emoji_index=$((($(date +%s) / 8) % ${#emojis[@]}))
  echo "${emojis[$emoji_index]}"
}

# Get current music info
SPOTIFY_TRACK=$(get_spotify_info)
MUSIC_PHRASE=$(get_music_phrase)
MUSIC_EMOJI=$(get_music_emoji)

# Accurate quarter calculation
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
# Force base-10 interpretation to avoid octal issues with leading zeros
MONTH=$((10#$MONTH))
DAY=$((10#$DAY))

case $MONTH in
1 | 2 | 3)
  QUARTER="Q1"
  QUARTER_START_MONTH=1
  ;;
4 | 5 | 6)
  QUARTER="Q2"
  QUARTER_START_MONTH=4
  ;;
7 | 8 | 9)
  QUARTER="Q3"
  QUARTER_START_MONTH=7
  ;;
10 | 11 | 12)
  QUARTER="Q4"
  QUARTER_START_MONTH=10
  ;;
esac

# Calculate days elapsed in quarter using simpler approach
case $QUARTER_START_MONTH in
1) # Q1: Jan, Feb, Mar
  if [ $MONTH -eq 1 ]; then
    DAYS_ELAPSED=$DAY
  elif [ $MONTH -eq 2 ]; then
    DAYS_ELAPSED=$((31 + DAY)) # Jan(31) + current day in Feb
  elif [ $MONTH -eq 3 ]; then
    # Feb days depend on leap year
    if [ $((YEAR % 4)) -eq 0 ] && ([ $((YEAR % 100)) -ne 0 ] || [ $((YEAR % 400)) -eq 0 ]); then
      DAYS_ELAPSED=$((31 + 29 + DAY)) # Jan(31) + Feb(29) + current day in Mar
    else
      DAYS_ELAPSED=$((31 + 28 + DAY)) # Jan(31) + Feb(28) + current day in Mar
    fi
  fi
  # Total days in Q1
  if [ $((YEAR % 4)) -eq 0 ] && ([ $((YEAR % 100)) -ne 0 ] || [ $((YEAR % 400)) -eq 0 ]); then
    TOTAL_QUARTER_DAYS=91 # Leap year: 31+29+31
  else
    TOTAL_QUARTER_DAYS=90 # Regular year: 31+28+31
  fi
  ;;
4) # Q2: Apr, May, Jun
  if [ $MONTH -eq 4 ]; then
    DAYS_ELAPSED=$DAY
  elif [ $MONTH -eq 5 ]; then
    DAYS_ELAPSED=$((30 + DAY)) # Apr(30) + current day in May
  elif [ $MONTH -eq 6 ]; then
    DAYS_ELAPSED=$((30 + 31 + DAY)) # Apr(30) + May(31) + current day in Jun
  fi
  TOTAL_QUARTER_DAYS=91 # Apr(30) + May(31) + Jun(30) = 91
  ;;
7) # Q3: Jul, Aug, Sep
  if [ $MONTH -eq 7 ]; then
    DAYS_ELAPSED=$DAY
  elif [ $MONTH -eq 8 ]; then
    DAYS_ELAPSED=$((31 + DAY)) # Jul(31) + current day in Aug
  elif [ $MONTH -eq 9 ]; then
    DAYS_ELAPSED=$((31 + 31 + DAY)) # Jul(31) + Aug(31) + current day in Sep
  fi
  TOTAL_QUARTER_DAYS=92 # Jul(31) + Aug(31) + Sep(30) = 92
  ;;
10) # Q4: Oct, Nov, Dec
  if [ $MONTH -eq 10 ]; then
    DAYS_ELAPSED=$DAY
  elif [ $MONTH -eq 11 ]; then
    DAYS_ELAPSED=$((31 + DAY)) # Oct(31) + current day in Nov
  elif [ $MONTH -eq 12 ]; then
    DAYS_ELAPSED=$((31 + 30 + DAY)) # Oct(31) + Nov(30) + current day in Dec
  fi
  TOTAL_QUARTER_DAYS=92 # Oct(31) + Nov(30) + Dec(31) = 92
  ;;
esac

# Ensure days elapsed is positive and within bounds
if [ $DAYS_ELAPSED -lt 1 ]; then DAYS_ELAPSED=1; fi
if [ $DAYS_ELAPSED -gt $TOTAL_QUARTER_DAYS ]; then DAYS_ELAPSED=$TOTAL_QUARTER_DAYS; fi

QUARTER_PERCENTAGE_DONE=$((DAYS_ELAPSED * 100 / TOTAL_QUARTER_DAYS))
QUARTER_PERCENTAGE=$((100 - QUARTER_PERCENTAGE_DONE))
if [ $QUARTER_PERCENTAGE -gt 100 ]; then QUARTER_PERCENTAGE=100; fi
if [ $QUARTER_PERCENTAGE -lt 0 ]; then QUARTER_PERCENTAGE=0; fi

# Calculate year percentage
DAY_OF_YEAR=$(date +%j)
# Remove leading zeros to avoid octal interpretation
DAY_OF_YEAR=$((10#$DAY_OF_YEAR))
# Determine if leap year
if [ $((YEAR % 4)) -eq 0 ] && ([ $((YEAR % 100)) -ne 0 ] || [ $((YEAR % 400)) -eq 0 ]); then
  TOTAL_YEAR_DAYS=366
else
  TOTAL_YEAR_DAYS=365
fi
YEAR_PERCENTAGE_DONE=$((DAY_OF_YEAR * 100 / TOTAL_YEAR_DAYS))
YEAR_PERCENTAGE=$((100 - YEAR_PERCENTAGE_DONE))
if [ $YEAR_PERCENTAGE -gt 100 ]; then YEAR_PERCENTAGE=100; fi
if [ $YEAR_PERCENTAGE -lt 0 ]; then YEAR_PERCENTAGE=0; fi

# Calculate life percentage remaining
# Birthday: November 19, 1989
BIRTH_YEAR=1989
BIRTH_MONTH=11
BIRTH_DAY=19
LIFE_EXPECTANCY_YEARS=80

# Calculate birth date in seconds since epoch
BIRTH_DATE=$(date -j -f "%Y-%m-%d" "${BIRTH_YEAR}-${BIRTH_MONTH}-${BIRTH_DAY}" "+%s" 2>/dev/null)
CURRENT_DATE=$(date "+%s")

# Calculate age in days
AGE_IN_SECONDS=$((CURRENT_DATE - BIRTH_DATE))
AGE_IN_DAYS=$((AGE_IN_SECONDS / 86400))

# Calculate total life expectancy in days (accounting for leap years: 365.25 days/year average)
TOTAL_LIFE_DAYS=$((LIFE_EXPECTANCY_YEARS * 36525 / 100))

# Calculate days remaining
DAYS_REMAINING=$((TOTAL_LIFE_DAYS - AGE_IN_DAYS))

# Calculate percentage remaining (with 2 decimal places)
if [ $DAYS_REMAINING -lt 0 ]; then
  LIFE_PERCENTAGE_REMAINING="0.00"
else
  LIFE_PERCENTAGE_REMAINING=$(awk -v days="$DAYS_REMAINING" -v total="$TOTAL_LIFE_DAYS" 'BEGIN {
    pct = (days * 100.0) / total
    if (pct > 100) pct = 100
    if (pct < 0) pct = 0
    printf "%.2f", pct
  }')
fi

# Calculate month percentage
# Get number of days in current month
case $MONTH in
1 | 3 | 5 | 7 | 8 | 10 | 12) DAYS_IN_MONTH=31 ;;
4 | 6 | 9 | 11) DAYS_IN_MONTH=30 ;;
2)
  # Check for leap year
  if [ $((YEAR % 4)) -eq 0 ] && ([ $((YEAR % 100)) -ne 0 ] || [ $((YEAR % 400)) -eq 0 ]); then
    DAYS_IN_MONTH=29
  else
    DAYS_IN_MONTH=28
  fi
  ;;
esac

MONTH_PERCENTAGE_DONE=$((DAY * 100 / DAYS_IN_MONTH))
MONTH_PERCENTAGE=$((100 - MONTH_PERCENTAGE_DONE))
if [ $MONTH_PERCENTAGE -gt 100 ]; then MONTH_PERCENTAGE=100; fi
if [ $MONTH_PERCENTAGE -lt 0 ]; then MONTH_PERCENTAGE=0; fi

# Git branch and changes count
GIT_BRANCH="no-git"
GIT_CHANGES_COUNT=0
if git rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  [ -z "$GIT_BRANCH" ] && GIT_BRANCH="detached"

  # Truncate branch name if too long (max 25 characters)
  if [ ${#GIT_BRANCH} -gt 25 ]; then
    GIT_BRANCH="${GIT_BRANCH:0:23}.."
  fi

  # Count all uncommitted changes (staged + unstaged + untracked)
  staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  unstaged_count=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  GIT_CHANGES_COUNT=$((staged_count + unstaged_count + untracked_count))
fi

# Claude info from JSON
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
OUTPUT_STYLE=$(echo "$input" | jq -r '.output_style.name // "default"')

# DEBUG: Capture output_style JSON to see what Claude Code is actually sending
echo "$input" | jq '.output_style' > /tmp/debug-output-style.json 2>/dev/null

# Debug mode - uncomment to see debug info
DEBUG=0
if [ "$DEBUG" = "1" ]; then
  echo "DEBUG: YEAR=$YEAR, MONTH=$MONTH, DAY=$DAY" >&2
  echo "DEBUG: QUARTER=$QUARTER, QUARTER_START_MONTH=$QUARTER_START_MONTH" >&2
  echo "DEBUG: DAYS_ELAPSED=$DAYS_ELAPSED, TOTAL_QUARTER_DAYS=$TOTAL_QUARTER_DAYS" >&2
  echo "DEBUG: QUARTER_PERCENTAGE=$QUARTER_PERCENTAGE" >&2
  echo "DEBUG: CONTEXT_PERCENTAGE=$CONTEXT_PERCENTAGE" >&2

  # Add debug info for token parsing
  session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
  if [ -n "$session_id" ]; then
    echo "DEBUG: SESSION_ID=$session_id" >&2
    # Find and show actual cache_read_input_tokens occurrences
    projects_dir="$HOME/.claude/projects"
    if [ -d "$projects_dir/-Users-samarthgupta" ]; then
      projects_dir="$projects_dir/-Users-samarthgupta"
    elif [ -d "$projects_dir/Users-samarthgupta" ]; then
      projects_dir="$projects_dir/Users-samarthgupta"
    fi
    jsonl_file=$(find "$projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
    if [ -n "$jsonl_file" ] && [ -f "$jsonl_file" ]; then
      cache_count=$(grep -c '"cache_read_input_tokens"' "$jsonl_file" 2>/dev/null || echo 0)
      echo "DEBUG: Found $cache_count cache_read_input_tokens entries in $jsonl_file" >&2
    fi
  fi
fi

# Build multi-line status display with new layout
echo

# Line 1: Model Name | Style Name | Context % + progress bar | MCP Status | Music info (if playing)
LINE1="  ${ACCENT}${BOLD}✨ ${MODEL_NAME}${RESET} ${PRIMARY}🎨 ${OUTPUT_STYLE}${RESET} ${PRIMARY}🧠 ${CONTEXT_PERCENTAGE}%${RESET} $(create_progress_bar $CONTEXT_PERCENTAGE 15)"
if [ $CONTEXT_PERCENTAGE -ge 85 ]; then
  LINE1="${LINE1} ${ACCENT}${BOLD}⚠️ Run /compact${RESET}"
fi
# Add MCP status if available
if [ -n "$MCP_STATUS" ]; then
  LINE1="${LINE1} ${ACCENT}${BOLD}🔌 ${MCP_STATUS} enabled${RESET}"
fi
# Add music info with better padding
if [ -n "$SPOTIFY_TRACK" ]; then
  LINE1="${LINE1}    ${ACCENT}${MUSIC_PHRASE}${RESET} ${SECONDARY}${SPOTIFY_TRACK}${RESET} ${MUSIC_EMOJI}"
fi

# Line 2: Current directory | Git branch | Uncommitted changes
LINE2="  ${SECONDARY}${BOLD}📁 ${CURRENT_DIR}${RESET} ${PRIMARY}${BOLD}⎇ ${GIT_BRANCH}${RESET}"
# Add uncommitted changes count if there are any
if [ $GIT_CHANGES_COUNT -gt 0 ]; then
  if [ $GIT_CHANGES_COUNT -eq 1 ]; then
    LINE2="${LINE2} ${ACCENT}${BOLD}📝 ${GIT_CHANGES_COUNT} uncommitted change${RESET}"
  else
    LINE2="${LINE2} ${ACCENT}${BOLD}📝 ${GIT_CHANGES_COUNT} uncommitted changes${RESET}"
  fi
fi

# Line 3: Weather | IST Time Day Date Month Year
LINE3="  ${WEATHER_ICON} ${SECONDARY}${WEATHER_TEMP}${RESET} ${PRIMARY}|${RESET} ${ACCENT}${BOLD}⏰ ${IST_TIME}${RESET} ${PRIMARY}${BOLD}📅 ${DAY_NAME}${RESET} ${GRAY}${DATE_DD}${RESET} ${GRAY}${MONTH_MON}${RESET} ${SECONDARY}${YEAR}${RESET}"

# Line 4: Month % | Quarter % | Year % | Life %
LINE4="  ${PRIMARY}${BOLD}📅 Month ${MONTH_PERCENTAGE}%${RESET} ${GRAY}|${RESET} ${ACCENT}${BOLD}📊 Quarter ${QUARTER_PERCENTAGE}%${RESET} ${GRAY}|${RESET} ${SECONDARY}${BOLD}🗓️ Year ${YEAR_PERCENTAGE}%${RESET} ${GRAY}|${RESET} ${ACCENT}${BOLD}❤️ Life ${LIFE_PERCENTAGE_REMAINING}%${RESET}"

# Cave Timer status line
CAVE_STATUS=""
# Use direct path instead of alias (aliases don't work in non-interactive shells)
CAVE_CMD=""
if [ -x "/Users/samarthgupta/Documents/GitHub/fork_exp/claude-code-cave/cave.js" ]; then
  CAVE_CMD="node /Users/samarthgupta/Documents/GitHub/fork_exp/claude-code-cave/cave.js"
elif command -v cave >/dev/null 2>&1; then
  CAVE_CMD="cave"
fi

if [ -n "$CAVE_CMD" ]; then
  cave_output=$($CAVE_CMD status 2>/dev/null)
  if [ $? -eq 0 ] && echo "$cave_output" | grep -q "Time remaining:"; then
    remaining=$(echo "$cave_output" | grep -o 'Time remaining: [0-9]* minutes' | sed 's/Time remaining: //')
    if [ -n "$remaining" ]; then
      CAVE_STATUS="  ${RED}${BOLD}🪨${RESET} ${RED}In the cave: ${remaining} remaining${RESET}"
    fi
  fi
fi

# Print all lines
echo -e "$LINE1"
echo -e "$LINE2"
echo -e "$LINE3"
echo -e "$LINE4"

# Print cave status if active
if [ -n "$CAVE_STATUS" ]; then
  echo -e "$CAVE_STATUS"
fi

echo

