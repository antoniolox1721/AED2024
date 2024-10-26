#!/bin/bash

# Define the program and samples directory
PROGRAM="./navigate"
SAMPLES_DIR="../AuxProg/Samples"

# Loop through each .maps file in the Samples directory
for mapfile in "$SAMPLES_DIR"/*.maps; do
    # Get the base name of the file (without the extension)
    base=$(basename "$mapfile" .maps)

    # Run the program and save the output to a .solmaps file
    echo "Running $mapfile"
    $PROGRAM "$mapfile" > "$SAMPLES_DIR/$base.solmaps"

    # Check if a corresponding .query file exists for comparison
    queryfile="$SAMPLES_DIR/$base.solmapsprofs"
    if [ -f "$queryfile" ]; then
        # Compare the output with the query file
        diff "$SAMPLES_DIR/$base.solmaps" "$queryfile" > "$SAMPLES_DIR/$base.diff"
        
        # If the diff file is empty, there are no differences
        if [ ! -s "$SAMPLES_DIR/$base.diff" ]; then
            echo "No differences found for $base."
            # Optionally, remove the diff file if there are no differences
            rm "$SAMPLES_DIR/$base.diff"
        else
            echo "Differences found for $base. Check $base.diff."
        fi
    else
        echo "Query file $queryfile not found, skipping comparison."
    fi
done
