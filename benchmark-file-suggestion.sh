#!/bin/bash
# Benchmark file suggestion methods for Claude Code
# Tests: find, fd, rg, and combinations with fzf

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
ITERATIONS=5
QUERIES=("test" "config" "main.ts" "README" "package.json" ".env")

# Results file
RESULTS_FILE="/tmp/benchmark-results-$(date +%s).csv"
echo "method,directory,query,iteration,time_ms,result_count" > "$RESULTS_FILE"

benchmark() {
    local name="$1"
    local dir="$2"
    local query="$3"
    local cmd="$4"
    local iteration="$5"

    # Time the command, capture results
    local start=$(python3 -c "import time; print(int(time.time() * 1000))")
    local count=$(eval "$cmd" 2>/dev/null | wc -l | tr -d ' ')
    local end=$(python3 -c "import time; print(int(time.time() * 1000))")
    local elapsed=$((end - start))

    echo "$name,$dir,$query,$iteration,$elapsed,$count" >> "$RESULTS_FILE"
    echo -e "  ${BLUE}$name${NC}: ${elapsed}ms (${count} results)"
}

run_benchmarks() {
    local dir="$1"
    local dir_name=$(basename "$dir")
    local file_count=$(find "$dir" -type f 2>/dev/null | head -10000 | wc -l | tr -d ' ')

    echo -e "\n${GREEN}=== Benchmarking: $dir ===${NC}"
    echo -e "${YELLOW}(~${file_count}+ files, $ITERATIONS iterations per method)${NC}\n"

    for query in "${QUERIES[@]}"; do
        echo -e "${YELLOW}Query: '$query'${NC}"

        for i in $(seq 1 $ITERATIONS); do
            echo -e "  Iteration $i:"

            # Method 1: find + grep (baseline)
            benchmark "find+grep" "$dir_name" "$query" \
                "find '$dir' -type f -name '*' 2>/dev/null | grep -i '$query' | head -15" "$i"

            # Method 2: fd (fast find alternative)
            benchmark "fd" "$dir_name" "$query" \
                "fd --type f --hidden --follow '$query' '$dir' 2>/dev/null | head -15" "$i"

            # Method 3: rg --files + grep
            benchmark "rg+grep" "$dir_name" "$query" \
                "rg --files --hidden --follow '$dir' 2>/dev/null | grep -i '$query' | head -15" "$i"

            # Method 4: rg --files + fzf (the proposed method)
            benchmark "rg+fzf" "$dir_name" "$query" \
                "rg --files --hidden --follow '$dir' 2>/dev/null | fzf --filter '$query' | head -15" "$i"

            # Method 5: fd + fzf
            benchmark "fd+fzf" "$dir_name" "$query" \
                "fd --type f --hidden --follow . '$dir' 2>/dev/null | fzf --filter '$query' | head -15" "$i"

            # Method 6: git ls-files (if git repo) + fzf
            if [ -d "$dir/.git" ]; then
                benchmark "git-ls+fzf" "$dir_name" "$query" \
                    "git -C '$dir' ls-files 2>/dev/null | fzf --filter '$query' | head -15" "$i"
            fi

            echo ""
        done
    done
}

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  File Suggestion Benchmark for Claude Code  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Methods being tested:"
echo "  1. find + grep (baseline)"
echo "  2. fd (rust-based find)"
echo "  3. rg --files + grep"
echo "  4. rg --files + fzf (proposed method)"
echo "  5. fd + fzf"
echo "  6. git ls-files + fzf (git repos only)"
echo ""
echo "Queries: ${QUERIES[*]}"
echo "Iterations per method: $ITERATIONS"
echo ""

# Run benchmarks on different directory sizes
# Small
run_benchmarks "$HOME/.claude"

# Medium (single repo)
run_benchmarks "$HOME/repos/forks/bird"

# Large
run_benchmarks "$HOME/repos/forks"

# Summary
echo -e "\n${GREEN}=== SUMMARY ===${NC}"
echo "Results saved to: $RESULTS_FILE"
echo ""

# Calculate averages using awk
echo -e "${YELLOW}Average times by method (across all tests):${NC}"
awk -F',' 'NR>1 {
    sum[$1] += $5
    count[$1]++
}
END {
    for (method in sum) {
        avg = sum[method] / count[method]
        printf "  %-12s: %6.1f ms avg\n", method, avg
    }
}' "$RESULTS_FILE" | sort -t':' -k2 -n

echo ""
echo -e "${YELLOW}Average times by directory:${NC}"
awk -F',' 'NR>1 {
    key = $1 ":" $2
    sum[key] += $5
    count[key]++
}
END {
    for (key in sum) {
        avg = sum[key] / count[key]
        printf "  %-25s: %6.1f ms avg\n", key, avg
    }
}' "$RESULTS_FILE" | sort -t':' -k2 -n

echo ""
echo -e "${GREEN}Benchmark complete!${NC}"
echo "Full results: $RESULTS_FILE"
