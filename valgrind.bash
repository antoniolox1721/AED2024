#!/bin/bash

# Define the program and samples directory
PROGRAM="./navigate"
SAMPLES_DIR="../AuxProg/Samples"
LOG_FILE="memory_usage_log.txt"
LEADERBOARD_FILE="leaderboard.txt"

# Initialize arrays for memory and time usage
declare -a mem_usages
declare -a time_usages
declare -a files

# Clear or create the log and leaderboard files
> "$LOG_FILE"
echo "Memory and Time Usage Log" > "$LOG_FILE"
echo "=========================" >> "$LOG_FILE"
> "$LEADERBOARD_FILE"

# Loop through each .maps file in the Samples directory
for mapfile in "$SAMPLES_DIR"/*.maps; do
    # Get the base name of the file (without the extension)
    base=$(basename "$mapfile" .maps)

    echo -e "\nProcessing $base..." >> "$LOG_FILE"

    # Run Valgrind with leak check and time command
    ulimit -n 4096
    /usr/bin/time -v valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes $PROGRAM "$mapfile" &> "$SAMPLES_DIR/$base.valgrind"

    # Extract maximum memory usage from valgrind output (in KB)
    mem_usage=$(grep "Maximum resident set size" "$SAMPLES_DIR/$base.valgrind" | grep -o '[0-9]*')

    # Extract wall clock time (in seconds)
    time_usage=$(grep "Elapsed (wall clock) time" "$SAMPLES_DIR/$base.valgrind" | grep -o '[0-9]*:[0-9]*\.[0-9]*' | awk -F':' '{print $1 * 60 + $2}')

    # Convert memory to MB for easier reading
    mem_usage_mb=$(echo "scale=2; $mem_usage/1024" | bc)

    # Log the memory and time usage
    echo "$base: ${mem_usage_mb}MB, ${time_usage}s" >> "$LOG_FILE"

    # Store the results in arrays
    mem_usages+=("$mem_usage_mb $base")
    time_usages+=("$time_usage $base")
done

# Function to print top 10 leaderboard
print_top_10() {
    local -n array=$1
    local label=$2
    echo "Top 10 $label:" >> "$LEADERBOARD_FILE"
    for entry in "${array[@]:0:10}"; do
        echo "$entry" >> "$LEADERBOARD_FILE"
    done
    echo "" >> "$LEADERBOARD_FILE"
}

# Sort arrays by memory and time usage, in descending order
IFS=$'\n'
sorted_mem=($(sort -nr <<<"${mem_usages[*]}"))
sorted_time=($(sort -nr <<<"${time_usages[*]}"))
unset IFS

# Print top 10 leaderboard for memory and time usage
print_top_10 sorted_mem "Memory Usage (MB)"
print_top_10 sorted_time "Execution Time (s)"

# Print summary to the console
echo "Performance analysis complete."
echo "Top 10 memory and time usage can be found in $LEADERBOARD_FILE"
echo "See $LOG_FILE for detailed log"
