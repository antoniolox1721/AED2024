#!/bin/bash

# Define the program and samples directory
PROGRAM="./navigate"
SAMPLES_DIR="../AuxProg/Samples"
TIME_LOG="time_usage_log.txt"
PERFORMANCE_FILE="time_performance.txt"

# Initialize time tracking variables
longest_time=0
longest_time_file=""

# Clear or create the log file
> "$TIME_LOG"
echo "Execution Time Log" > "$TIME_LOG"
echo "=================" >> "$TIME_LOG"

# Loop through each .maps file in the Samples directory
for mapfile in "$SAMPLES_DIR"/*.maps; do
    # Get the base name of the file (without the extension)
    base=$(basename "$mapfile" .maps)


    echo -e "\nProcessing $base..." >> "$TIME_LOG"

    # Create temporary file for time output
    temp_time_file=$(mktemp)

    # Run program with time command

    { time $PROGRAM "$mapfile" ; } 2> "$temp_time_file"

    # Extract real time in seconds (converting minutes if present)
    real_time=$(grep "real" "$temp_time_file" | awk '{print $2}' | sed 's/0m//' | sed 's/s//')
    
    # Handle cases where time is in minutes
    if [[ $real_time == *"m"* ]]; then
        minutes=$(echo $real_time | cut -d'm' -f1)
        seconds=$(echo $real_time | cut -d'm' -f2 | sed 's/s//')
        real_time=$(echo "$minutes * 60 + $seconds" | bc)
    fi

    # Log the time usage
    echo "$base: ${real_time}s" >> "$TIME_LOG"

    # Update longest time if current is higher
    if (( $(echo "$real_time > $longest_time" | bc -l) )); then
        longest_time=$real_time
        longest_time_file=$base
    fi

    # Clean up temporary file
    rm "$temp_time_file"
done

# Save performance metrics information
echo -e "\nPerformance Summary:" >> "$TIME_LOG"
echo "Longest Execution Time:" >> "$TIME_LOG"
echo "File: $longest_time_file" >> "$TIME_LOG"
echo "Time: ${longest_time}s" >> "$TIME_LOG"

# Also save to separate file for easy access
echo "Time Performance Summary" > "$PERFORMANCE_FILE"
echo "======================" >> "$PERFORMANCE_FILE"
echo "Longest Execution Time:" >> "$PERFORMANCE_FILE"
echo "File: $longest_time_file" >> "$PERFORMANCE_FILE"
echo "Time: ${longest_time}s" >> "$PERFORMANCE_FILE"

echo "Time analysis complete."
echo "Longest execution time was ${longest_time}s by $longest_time_file"
echo "See $TIME_LOG for detailed log"