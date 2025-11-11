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

# Parse JSONL session files directly for accurate token usage
get_context_percentage() {
  local session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
  local current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""' 2>/dev/null)
  local model_id=$(echo "$input" | jq -r '.model.id // ""' 2>/dev/null)

  # Determine context window size based on model - using more conservative estimates
  local context_limit=200000
  if [[ "$model_id" == *"sonnet-4"* ]]; then
    context_limit=200000 # Conservative estimate for Sonnet 4
  elif [[ "$model_id" == *"claude-3-5-sonnet"* ]]; then
    context_limit=200000
  elif [[ "$model_id" == *"opus"* ]]; then
    context_limit=200000 # More conservative for Opus 4.1
  fi

  # Find the correct project directory based on current working directory
  local jsonl_file=""
  local projects_base="$HOME/.claude/projects"
  local projects_dir=""

  # Get current directory from Claude Code input or fallback to PWD
  local cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' 2>/dev/null)
  if [ -z "$cwd" ]; then
    cwd="$PWD"
  fi

  # Convert current directory path to Claude's project directory format
  # Replace / with - and remove leading /
  local project_suffix=$(echo "$cwd" | sed 's/\//-/g' | sed 's/^-//')
  projects_dir="$projects_base/-$project_suffix"

  # Debug project directory detection
  if [ "$DEBUG" = "1" ]; then
    echo "DEBUG: CWD: $cwd" >&2
    echo "DEBUG: Project suffix: $project_suffix" >&2
    echo "DEBUG: Looking in projects dir: $projects_dir" >&2
  fi

  if [ -d "$projects_dir" ]; then
    # ONLY use the exact session_id provided by this Claude Code instance
    if [ -n "$session_id" ] && [ "$session_id" != "test" ]; then
      jsonl_file=$(find "$projects_dir" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
    fi
  else
    # Fallback: search all project directories if the computed path doesn't exist
    if [ -n "$session_id" ] && [ "$session_id" != "test" ]; then
      jsonl_file=$(find "$projects_base" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
      if [ "$DEBUG" = "1" ] && [ -n "$jsonl_file" ]; then
        echo "DEBUG: Fallback found session file: $jsonl_file" >&2
      fi
    fi
  fi

  # If still no file found, this means context is 0% (new session, cleared, or different folder)

  if [ -n "$jsonl_file" ] && [ -f "$jsonl_file" ]; then
    # SIMPLIFIED: Find the most recent cache_read_tokens + its associated input/output
    # This represents the current effective context for THIS specific session
    local effective_tokens=0
    local session_cache_read=0
    local session_input=0
    local session_output=0

    # Get the most recent non-zero usage entry from THIS session file
    local most_recent_usage=$(grep '"usage"' "$jsonl_file" | tail -20 | while IFS= read -r line; do
      local cache_read=$(echo "$line" | jq -r '.message.usage.cache_read_input_tokens // .usage.cache_read_input_tokens // 0' 2>/dev/null)
      local input_tokens=$(echo "$line" | jq -r '.message.usage.input_tokens // .usage.input_tokens // 0' 2>/dev/null)
      local output_tokens=$(echo "$line" | jq -r '.message.usage.output_tokens // .usage.output_tokens // 0' 2>/dev/null)

      # Print the entry with the highest cache_read value
      if [ -n "$cache_read" ] && [ "$cache_read" != "null" ] && [ "$cache_read" -gt 0 ]; then
        echo "$cache_read $input_tokens $output_tokens"
      elif [ -n "$input_tokens" ] && [ "$input_tokens" != "null" ] && [ "$input_tokens" -gt 0 ]; then
        echo "0 $input_tokens $output_tokens"
      fi
    done | sort -nr | head -1)

    if [ -n "$most_recent_usage" ]; then
      read session_cache_read session_input session_output <<<"$most_recent_usage"
    fi

    # Calculate effective context for THIS session only
    effective_tokens=$((session_cache_read + session_input + session_output))

    # Debug output for token counts
    if [ "$DEBUG" = "1" ]; then
      echo "DEBUG: Using session file: $jsonl_file" >&2
      echo "DEBUG: Session ID: $session_id" >&2
      echo "DEBUG: Session context - Cache: $session_cache_read, Input: $session_input, Output: $session_output, Total: $effective_tokens" >&2
    fi

    if [ "$effective_tokens" -gt 0 ]; then
      local percentage=$((effective_tokens * 100 / context_limit))
      if [ $percentage -gt 100 ]; then percentage=100; fi
      echo "$percentage"
      return
    fi
  fi

  # Fallback: try transcript path if JSONL parsing fails
  local transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
  if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # FIXED: Parse ENTIRE transcript file and sum ALL usage entries including ALL token types
    local total_input_tokens=0
    local total_output_tokens=0
    local total_cache_read_tokens=0
    local total_cache_creation_tokens=0

    # Process each line of the transcript file to extract usage data
    while IFS= read -r line; do
      if [ -n "$line" ] && echo "$line" | grep -q '"usage"'; then
        # Use jq for robust JSON parsing if available, otherwise use grep
        if command -v jq >/dev/null 2>&1; then
          # Try both .usage and .message.usage paths
          local input_tokens=$(echo "$line" | jq -r '.message.usage.input_tokens // .usage.input_tokens // 0' 2>/dev/null)
          local output_tokens=$(echo "$line" | jq -r '.message.usage.output_tokens // .usage.output_tokens // 0' 2>/dev/null)
          local cache_read_tokens=$(echo "$line" | jq -r '.message.usage.cache_read_input_tokens // .usage.cache_read_input_tokens // 0' 2>/dev/null)
          local cache_creation_tokens=$(echo "$line" | jq -r '.message.usage.cache_creation_input_tokens // .usage.cache_creation_input_tokens // 0' 2>/dev/null)
        else
          # Fallback to grep pattern matching
          local input_tokens=$(echo "$line" | grep -o '"input_tokens":[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
          local output_tokens=$(echo "$line" | grep -o '"output_tokens":[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
          local cache_read_tokens=$(echo "$line" | grep -o '"cache_read_input_tokens":[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
          local cache_creation_tokens=$(echo "$line" | grep -o '"cache_creation_input_tokens":[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
        fi

        # Add to totals (ensure we have valid numbers)
        if [ -n "$input_tokens" ] && [ "$input_tokens" != "null" ] && [ "$input_tokens" != "0" ]; then
          total_input_tokens=$((total_input_tokens + input_tokens))
        fi
        if [ -n "$output_tokens" ] && [ "$output_tokens" != "null" ] && [ "$output_tokens" != "0" ]; then
          total_output_tokens=$((total_output_tokens + output_tokens))
        fi
        if [ -n "$cache_read_tokens" ] && [ "$cache_read_tokens" != "null" ] && [ "$cache_read_tokens" != "0" ]; then
          total_cache_read_tokens=$((total_cache_read_tokens + cache_read_tokens))
        fi
        if [ -n "$cache_creation_tokens" ] && [ "$cache_creation_tokens" != "null" ] && [ "$cache_creation_tokens" != "0" ]; then
          total_cache_creation_tokens=$((total_cache_creation_tokens + cache_creation_tokens))
        fi
      fi
    done <"$transcript_path"

    local total_tokens=$((total_input_tokens + total_output_tokens + total_cache_read_tokens + total_cache_creation_tokens))

    # Debug output for token counts
    if [ "$DEBUG" = "1" ] && [ "$total_tokens" -gt 0 ]; then
      echo "DEBUG: Token counts from transcript - Input: $total_input_tokens, Output: $total_output_tokens, Cache Read: $total_cache_read_tokens, Cache Creation: $total_cache_creation_tokens, Total: $total_tokens" >&2
    fi

    if [ "$total_tokens" -gt 0 ]; then
      local percentage=$((total_tokens * 100 / context_limit))
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
CURRENT_DIR=$(basename "$PWD")

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

# Calculate percentage remaining
if [ $DAYS_REMAINING -lt 0 ]; then
  LIFE_PERCENTAGE_REMAINING=0
else
  LIFE_PERCENTAGE_REMAINING=$((DAYS_REMAINING * 100 / TOTAL_LIFE_DAYS))
fi

if [ $LIFE_PERCENTAGE_REMAINING -gt 100 ]; then LIFE_PERCENTAGE_REMAINING=100; fi
if [ $LIFE_PERCENTAGE_REMAINING -lt 0 ]; then LIFE_PERCENTAGE_REMAINING=0; fi

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

