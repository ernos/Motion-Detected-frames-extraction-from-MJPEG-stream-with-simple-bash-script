#!/bin/bash
# Written By Maximilain Cornett
# 2025 max@yourdev.net
# https://www.yourdev.net for lots of interesting articles and tutorials on everything from android appication development to cracking stuff with #  # assembly and machine code. Just for fun though. Kotlin is my major focus right now.
# Motion Detection Script for MJPEG Stream Files
# Extracts frames from MJPEG streams and detects motion sequences
# Requires: ffmpeg

set -e

# Configuration
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-motion_sequences}"
MOTION_THRESHOLD="${3:-5}"  # Percentage threshold for motion
MIN_SEQUENCE_LENGTH="${4:-5}"  # Minimum frames for a sequence
FPS="${5:-1}"  # Frame rate for extraction (1 = 1 frame per second)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== MJPEG Motion Detection Script ===${NC}"
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Motion threshold: ${MOTION_THRESHOLD}%"
echo "Min sequence length: $MIN_SEQUENCE_LENGTH frames"
echo "Extraction FPS: $FPS"
echo ""

# Check dependencies
command -v ffmpeg >/dev/null 2>&1 || { echo -e "${RED}Error: ffmpeg required${NC}"; exit 1; }

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/extracted_frames"
mkdir -p "$OUTPUT_DIR/temp"

# Find all MJPEG stream files
FILES=($(find "$INPUT_DIR" -maxdepth 1 -name "[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9].jpeg" | sort))

if [ ${#FILES[@]} -eq 0 ]; then
    echo -e "${RED}No HHMM-HHMM.jpeg files found${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#FILES[@]} MJPEG stream files${NC}"
echo ""

# Step 1: Extract frames from each MJPEG stream
echo -e "${BLUE}=== Step 1: Extracting Frames ===${NC}"
frame_counter=0

for stream_file in "${FILES[@]}"; do
    filename=$(basename "$stream_file" .jpeg)
    echo -e "${YELLOW}Processing stream:${NC} $filename"
    
    # Extract frames at specified FPS
    # Output format: frameNNNNNN.jpg
    ffmpeg -i "$stream_file" -vf fps=$FPS \
        "$OUTPUT_DIR/extracted_frames/frame_${filename}_%06d.jpg" \
        -loglevel error -stats
    
    # Count extracted frames
    extracted=$(ls "$OUTPUT_DIR/extracted_frames/frame_${filename}_"*.jpg 2>/dev/null | wc -l)
    frame_counter=$((frame_counter + extracted))
    echo -e "  ${GREEN}✓${NC} Extracted $extracted frames"
done

echo -e "\n${GREEN}Total frames extracted: $frame_counter${NC}\n"

# Step 2: Motion detection
echo -e "${BLUE}=== Step 2: Detecting Motion ===${NC}"

# Get all extracted frames in order
ALL_FRAMES=($(ls -1 "$OUTPUT_DIR/extracted_frames/"*.jpg | sort))
total_frames=${#ALL_FRAMES[@]}

if [ $total_frames -lt 2 ]; then
    echo -e "${RED}Not enough frames for motion detection${NC}"
    exit 1
fi

declare -a motion_detected

# Compare consecutive frames
for i in $(seq 1 $((total_frames - 1))); do
    prev_frame="${ALL_FRAMES[$((i-1))]}"
    curr_frame="${ALL_FRAMES[$i]}"
    
    echo -ne "Analyzing frame $i/$((total_frames-1))... "
    
    # Use ffmpeg to calculate difference
    ffmpeg -i "$prev_frame" -i "$curr_frame" \
        -filter_complex "[0:v][1:v]blend=all_mode=difference,format=gray,tblend=all_mode=average" \
        -frames:v 1 "$OUTPUT_DIR/temp/diff_$i.jpg" \
        -loglevel error 2>/dev/null
    
    # Calculate average pixel intensity (motion indicator)
    avg_diff=$(ffmpeg -i "$OUTPUT_DIR/temp/diff_$i.jpg" \
        -vf "format=gray,geq='lum(X,Y)':scale_eval=frame,metadata=print:file=-" \
        -f null - 2>&1 | grep "lavfi.signalstats.YAVG" | tail -1 | awk -F= '{print $2}')
    
    # Convert to percentage (0-100 scale)
    if [ -n "$avg_diff" ]; then
        motion_pct=$(awk "BEGIN {printf \"%.2f\", ($avg_diff / 255) * 100}")
        
        if (( $(echo "$motion_pct >= $MOTION_THRESHOLD" | bc -l) )); then
            echo -e "${GREEN}[MOTION: ${motion_pct}%]${NC}"
            motion_detected[$i]=1
        else
            echo "[${motion_pct}%]"
            motion_detected[$i]=0
        fi
    else
        echo -e "${RED}[ERROR]${NC}"
        motion_detected[$i]=0
    fi
done

# Step 3: Extract motion sequences
echo -e "\n${BLUE}=== Step 3: Extracting Motion Sequences ===${NC}"

sequence_count=0
in_sequence=0
sequence_start=0
sequence_frames=()

for i in $(seq 1 $((total_frames - 1))); do
    if [ "${motion_detected[$i]}" == "1" ]; then
        if [ $in_sequence -eq 0 ]; then
            # Start new sequence
            in_sequence=1
            sequence_start=$i
            sequence_frames=("${ALL_FRAMES[$((i-1))]}" "${ALL_FRAMES[$i]}")
        else
            # Continue sequence
            sequence_frames+=("${ALL_FRAMES[$i]}")
        fi
    else
        if [ $in_sequence -eq 1 ]; then
            # End sequence
            in_sequence=0
            seq_length=${#sequence_frames[@]}
            
            if [ $seq_length -ge $MIN_SEQUENCE_LENGTH ]; then
                sequence_count=$((sequence_count + 1))
                seq_dir="$OUTPUT_DIR/sequence_$sequence_count"
                mkdir -p "$seq_dir"
                
                echo -e "${GREEN}Sequence $sequence_count:${NC} $seq_length frames"
                
                # Copy frames
                for frame in "${sequence_frames[@]}"; do
                    cp "$frame" "$seq_dir/"
                done
                
                # Create video (2 fps for viewing)
                ffmpeg -framerate 2 -pattern_type glob -i "$seq_dir/*.jpg" \
                    -c:v libx264 -pix_fmt yuv420p -y \
                    "$OUTPUT_DIR/sequence_${sequence_count}.mp4" \
                    -loglevel error 2>/dev/null
                
                echo "  → Video: sequence_${sequence_count}.mp4"
                
                # Create preview GIF
                ffmpeg -i "$OUTPUT_DIR/sequence_${sequence_count}.mp4" \
                    -vf "fps=2,scale=480:-1:flags=lanczos" \
                    -y "$OUTPUT_DIR/sequence_${sequence_count}.gif" \
                    -loglevel error 2>/dev/null
                
                echo "  → GIF: sequence_${sequence_count}.gif"
            fi
            
            sequence_frames=()
        fi
    fi
done

# Handle sequence at end
if [ $in_sequence -eq 1 ]; then
    seq_length=${#sequence_frames[@]}
    if [ $seq_length -ge $MIN_SEQUENCE_LENGTH ]; then
        sequence_count=$((sequence_count + 1))
        seq_dir="$OUTPUT_DIR/sequence_$sequence_count"
        mkdir -p "$seq_dir"
        
        echo -e "${GREEN}Sequence $sequence_count:${NC} $seq_length frames"
        
        for frame in "${sequence_frames[@]}"; do
            cp "$frame" "$seq_dir/"
        done
        
        ffmpeg -framerate 2 -pattern_type glob -i "$seq_dir/*.jpg" \
            -c:v libx264 -pix_fmt yuv420p -y \
            "$OUTPUT_DIR/sequence_${sequence_count}.mp4" \
            -loglevel error 2>/dev/null
        
        ffmpeg -i "$OUTPUT_DIR/sequence_${sequence_count}.mp4" \
            -vf "fps=2,scale=480:-1:flags=lanczos" \
            -y "$OUTPUT_DIR/sequence_${sequence_count}.gif" \
            -loglevel error 2>/dev/null
    fi
fi

# Cleanup
rm -rf "$OUTPUT_DIR/temp"

# Summary
echo -e "\n${GREEN}=== Summary ===${NC}"
echo "MJPEG streams processed: ${#FILES[@]}"
echo "Total frames extracted: $total_frames"
echo "Motion sequences found: $sequence_count"
echo "Output directory: $OUTPUT_DIR"
echo ""
echo -e "${GREEN}Done!${NC}"
