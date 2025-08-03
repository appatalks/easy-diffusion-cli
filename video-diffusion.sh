#!/bin/bash

# Video Diffusion CLI - Optimized for modern hardware with parallel processing
# This script extracts frames from a video and processes each frame through Easy Diffusion in parallel

# Function to display usage instructions
usage() {
  echo "Usage: $0 --video \"/path/to/video.mp4\" --prompt \"Your prompt here\""
  echo ""
  echo "Required arguments:"
  echo "       --video \"/path/to/video.mp4\""
  echo "       --prompt \"Your prompt here\""
  echo ""
  echo "Optional arguments:"
  echo "       [--fps FPS] (frames per second to extract, default: auto-detect from source video)"
  echo "       [--model MODEL] (default: sd-v1-4)"
  echo "       [--seed SEED] (if not provided, random seed for each frame)"
  echo "       [--negative-prompt \"Negative prompt\"]"
  echo "       [--num-inference-steps STEPS] (default: 46)"
  echo "       [--guidance-scale SCALE] (default: 7.5)"
  echo "       [--prompt-strength STRENGTH] (default: 0.5)"
  echo "       [--width WIDTH] (default: 512)"
  echo "       [--height HEIGHT] (default: 512)"
  echo "       [--save-to-disk-path PATH] (default: ./output/)"
  echo "       [--session_id ID] (default: current date with minute timestamp)"
  echo "       [--temp-dir PATH] (temporary directory for frames, default: ./temp_frames)"
  echo "       [--keep-frames] (keep extracted frames after processing)"
  echo "       [--delay SECONDS] (delay between processing frames, default: 0.05 for parallel mode)"
  echo "       [--start-frame NUM] (start processing from frame number, default: 1)"
  echo "       [--end-frame NUM] (stop processing at frame number, default: all)"
  echo "       [--parallel-jobs NUM] (number of parallel jobs for frame extraction, default: 4)"
  echo "       [--max-concurrent NUM] (max concurrent API requests, default: 12)"
  echo "       [--sequential] (disable parallel processing, process frames one by one)"
  echo "       [--batch-size NUM] (number of frames to process in each batch, default: 24)"
  echo "       [--debug] (enable debug output for troubleshooting)"
  echo "       [--no-video] (skip video creation, keep only generated images)"
  echo ""
  echo "Output video will be named using first 3 words of prompt + timestamp (e.g., van_gogh_starry_2025-08-02_2046.mp4)"
  exit 1
}

# Function to generate video filename from first 3 prompt words and timestamp
generate_video_name() {
  local prompt="$1"
  local timestamp=$(date '+%Y-%m-%d_%H%M')
  
  # Extract first 3 words from prompt, convert to lowercase, replace spaces/special chars with underscores
  local first_three_words=$(echo "$prompt" | awk '{print tolower($1"_"$2"_"$3)}' | sed 's/[^a-z0-9_]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')
  
  # If prompt has less than 3 words, use what's available
  if [[ -z "$first_three_words" ]]; then
    first_three_words="generated"
  fi
  
  echo "${first_three_words}_${timestamp}.mp4"
}

# Default values
FPS=1
MODEL="sd-v1-5.safetensors"
NEGATIVE_PROMPT=""
NUM_INFERENCE_STEPS=46
GUIDANCE_SCALE=7.5
PROMPT_STRENGTH=0.5
WIDTH=512
HEIGHT=512
SAVE_TO_DISK_PATH="./output/"
SESSION_ID=$(date '+%Y-%m-%d_%H%M')
TEMP_DIR="./temp_frames"
KEEP_FRAMES=false
DELAY=0.05
START_FRAME=1
END_FRAME=""
SEED=""
PARALLEL_JOBS=4
MAX_CONCURRENT_REQUESTS=12
SEQUENTIAL=false
BATCH_SIZE=24
DEBUG=false
NO_VIDEO=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --video) VIDEO_PATH="$2"; shift ;;
    --prompt) PROMPT="$2"; shift ;;
    --fps) FPS="$2"; shift ;;
    --model) MODEL="$2"; shift ;;
    --seed) SEED="$2"; shift ;;
    --negative-prompt) NEGATIVE_PROMPT="$2"; shift ;;
    --num-inference-steps) NUM_INFERENCE_STEPS="$2"; shift ;;
    --guidance-scale) GUIDANCE_SCALE="$2"; shift ;;
    --prompt-strength) PROMPT_STRENGTH="$2"; shift ;;
    --width) WIDTH="$2"; shift ;;
    --height) HEIGHT="$2"; shift ;;
    --save-to-disk-path) SAVE_TO_DISK_PATH="$2"; shift ;;
    --session_id) SESSION_ID="$2"; shift ;;
    --temp-dir) TEMP_DIR="$2"; shift ;;
    --keep-frames) KEEP_FRAMES=true ;;
    --delay) DELAY="$2"; shift ;;
    --start-frame) START_FRAME="$2"; shift ;;
    --end-frame) END_FRAME="$2"; shift ;;
    --parallel-jobs) PARALLEL_JOBS="$2"; shift ;;
    --max-concurrent) MAX_CONCURRENT_REQUESTS="$2"; shift ;;
    --sequential) SEQUENTIAL=true ;;
    --batch-size) BATCH_SIZE="$2"; shift ;;
    --debug) DEBUG=true ;;
    --no-video) NO_VIDEO=true ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

# Validate mandatory arguments
if [[ -z "$VIDEO_PATH" ]]; then
  echo "Error: --video is required."
  echo ""
  usage
fi

if [[ -z "$PROMPT" ]]; then
  echo "Error: --prompt is required."
  echo ""
  usage
fi

# Check if video file exists
if [[ ! -f "$VIDEO_PATH" ]]; then
  echo "Error: Video file not found at '$VIDEO_PATH'"
  exit 1
fi

# Auto-detect source video frame rate if FPS is still default
if [[ "$FPS" == "1" ]]; then
  echo "Detecting source video frame rate..."
  SOURCE_FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_PATH" 2>/dev/null)
  if [[ -n "$SOURCE_FPS" && "$SOURCE_FPS" != "0/0" ]]; then
    # Convert fraction to decimal (handle cases like "25/1" or "30000/1001")
    if [[ "$SOURCE_FPS" =~ ^([0-9]+)/([0-9]+)$ ]]; then
      NUMERATOR=${BASH_REMATCH[1]}
      DENOMINATOR=${BASH_REMATCH[2]}
      DETECTED_FPS=$(( (NUMERATOR + DENOMINATOR/2) / DENOMINATOR ))  # Round to nearest integer
      
      if [[ "$DETECTED_FPS" -gt 0 && "$DETECTED_FPS" -le 120 ]]; then
        FPS=$DETECTED_FPS
        echo "✓ Auto-detected source frame rate: $FPS fps (from $SOURCE_FPS)"
        
        # Calculate total frames that would be processed
        DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_PATH" 2>/dev/null)
        if [[ -n "$DURATION" ]]; then
          # Convert duration to integer seconds (round up)
          DURATION_INT=$(echo "$DURATION" | cut -d. -f1)
          TOTAL_FRAMES=$((DURATION_INT * FPS + FPS))  # Add one extra second worth for safety
          echo "  This will extract approximately $TOTAL_FRAMES frames from the video"
          
          # Provide recommendations based on frame count
          if [[ "$TOTAL_FRAMES" -gt 100 ]]; then
            echo ""
            echo "⚠️  PERFORMANCE RECOMMENDATION:"
            echo "   Processing $TOTAL_FRAMES frames will take a very long time!"
            echo "   Consider using --fps 1 (1 frame per second) for faster processing"
            echo "   Or use --end-frame parameter to limit processing (e.g., --end-frame 50)"
            echo ""
          fi
        fi
        
        echo "  Use --fps parameter to override (e.g., --fps 1 for 1 frame per second sampling)"
      else
        echo "⚠ Detected frame rate seems unusual ($DETECTED_FPS fps), using default FPS=1"
      fi
    else
      echo "⚠ Could not parse detected frame rate ($SOURCE_FPS), using default FPS=1"
    fi
  else
    echo "⚠ Could not detect source frame rate, using default FPS=1"
  fi
fi

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: 'ffmpeg' command is required but not found. Install it with:"
  echo "sudo apt-get install ffmpeg"
  exit 1
fi

# Check if easy-diffusion-cli-enhanced.sh exists
EASY_DIFFUSION_CLI="./easy-diffusion-cli-enhanced.sh"
if [[ ! -f "$EASY_DIFFUSION_CLI" ]]; then
  echo "Error: easy-diffusion-cli-enhanced.sh not found in current directory"
  exit 1
fi

# Auto-detect optimal settings based on hardware for maximum performance
if command -v nproc &> /dev/null; then
  CPU_CORES=$(nproc)
  TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}' 2>/dev/null || echo 8)
  
  # Aggressive auto-tuning for modern hardware
  if [[ $PARALLEL_JOBS -eq 4 ]] && [[ $CPU_CORES -gt 4 ]]; then
    PARALLEL_JOBS=$((CPU_CORES > 20 ? 20 : CPU_CORES))
    echo "Auto-detected $CPU_CORES CPU cores, using $PARALLEL_JOBS parallel jobs for extraction"
  fi
  
  # Auto-adjust concurrent requests based on hardware
  if [[ $MAX_CONCURRENT_REQUESTS -eq 12 ]]; then
    if [[ $CPU_CORES -ge 16 ]] && [[ $TOTAL_RAM -ge 32 ]]; then
      MAX_CONCURRENT_REQUESTS=20
      BATCH_SIZE=40
      DELAY=0.01
      echo "High-end hardware detected: 20 concurrent requests, 40 batch size"
    elif [[ $CPU_CORES -ge 12 ]] && [[ $TOTAL_RAM -ge 16 ]]; then
      MAX_CONCURRENT_REQUESTS=16
      BATCH_SIZE=32
      DELAY=0.03
      echo "High-performance hardware detected: 16 concurrent requests, 32 batch size"
    elif [[ $CPU_CORES -ge 8 ]] && [[ $TOTAL_RAM -ge 8 ]]; then
      MAX_CONCURRENT_REQUESTS=12
      BATCH_SIZE=24
      DELAY=0.05
      echo "Good hardware detected: 12 concurrent requests, 24 batch size"
    fi
  fi
fi

# Adjust sequential mode defaults
if [[ "$SEQUENTIAL" == true ]]; then
  MAX_CONCURRENT_REQUESTS=1
  DELAY=2
  echo "Sequential mode enabled - processing one frame at a time"
else
  echo "Parallel mode enabled - max $MAX_CONCURRENT_REQUESTS concurrent requests"
fi

# Create temporary directory for frames
mkdir -p "$TEMP_DIR"
mkdir -p "$SAVE_TO_DISK_PATH"

echo "=== Video Diffusion Processing (Optimized) ==="
echo "Video: $VIDEO_PATH"
echo "Prompt: $PROMPT"
echo "FPS: $FPS"
echo "Parallel extraction jobs: $PARALLEL_JOBS"
echo "Max concurrent API requests: $MAX_CONCURRENT_REQUESTS"
echo "Batch size: $BATCH_SIZE"
echo "Temporary frames directory: $TEMP_DIR"
echo "Output directory: $SAVE_TO_DISK_PATH"
echo "==============================================="
echo ""

# Extract frames from video with parallel processing
echo "Extracting frames from video (using $PARALLEL_JOBS parallel jobs)..."
ffmpeg -i "$VIDEO_PATH" -vf "fps=$FPS" "$TEMP_DIR/frame_%04d.jpg" -threads $PARALLEL_JOBS -y

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to extract frames from video"
  exit 1
fi

# Count extracted frames
FRAME_COUNT=$(ls -1 "$TEMP_DIR"/frame_*.jpg 2>/dev/null | wc -l)
echo "Extracted $FRAME_COUNT frames"

if [[ $FRAME_COUNT -eq 0 ]]; then
  echo "Error: No frames were extracted"
  exit 1
fi

# Set end frame if not specified
if [[ -z "$END_FRAME" ]]; then
  END_FRAME=$FRAME_COUNT
fi

# Validate frame range
if [[ $START_FRAME -gt $FRAME_COUNT ]]; then
  echo "Error: Start frame ($START_FRAME) is greater than total frames ($FRAME_COUNT)"
  exit 1
fi

if [[ $END_FRAME -gt $FRAME_COUNT ]]; then
  echo "Warning: End frame ($END_FRAME) is greater than total frames ($FRAME_COUNT). Using $FRAME_COUNT"
  END_FRAME=$FRAME_COUNT
fi

echo "Processing frames $START_FRAME to $END_FRAME..."
echo ""

# Function to process a single frame
process_frame() {
  local frame_num=$1
  local frame_file=$(printf "$TEMP_DIR/frame_%04d.jpg" $frame_num)
  
  if [[ ! -f "$frame_file" ]]; then
    echo "Warning: Frame file $frame_file not found, skipping..."
    return 1
  fi
  
  # Generate unique seed for each frame if not provided
  local frame_seed
  if [[ -z "$SEED" ]]; then
    frame_seed=$(od -An -N4 -t u4 /dev/urandom)
  else
    frame_seed=$SEED
  fi
  
  # Create frame-specific session ID
  local frame_session_id="${SESSION_ID}_frame_$(printf "%04d" $frame_num)"
  
  echo "Processing frame $frame_num/$END_FRAME: $frame_file (PID: $$)"
  
  # Debug output if enabled
  if [[ "$DEBUG" == true ]]; then
    echo "DEBUG: Command: bash $EASY_DIFFUSION_CLI --prompt \"$PROMPT\" --model \"$MODEL\" --init-image \"$frame_file\" --seed \"$frame_seed\" --save-to-disk-path \"$SAVE_TO_DISK_PATH\" --session_id \"$frame_session_id\""
  fi
  
  # Run easy-diffusion-cli-enhanced.sh with the frame as init image and capture response
  local api_response
  if [[ "$DEBUG" == true ]]; then
    api_response=$(bash "$EASY_DIFFUSION_CLI" \
      --prompt "$PROMPT" \
      --model "$MODEL" \
      --init-image "$frame_file" \
      --seed "$frame_seed" \
      --negative-prompt "$NEGATIVE_PROMPT" \
      --num-inference-steps "$NUM_INFERENCE_STEPS" \
      --guidance-scale "$GUIDANCE_SCALE" \
      --prompt-strength "$PROMPT_STRENGTH" \
      --width "$WIDTH" \
      --height "$HEIGHT" \
      --save-to-disk-path "$SAVE_TO_DISK_PATH" \
      --session_id "$frame_session_id")
    echo "DEBUG: API Response: $api_response"
  else
    api_response=$(bash "$EASY_DIFFUSION_CLI" \
      --prompt "$PROMPT" \
      --model "$MODEL" \
      --init-image "$frame_file" \
      --seed "$frame_seed" \
      --negative-prompt "$NEGATIVE_PROMPT" \
      --num-inference-steps "$NUM_INFERENCE_STEPS" \
      --guidance-scale "$GUIDANCE_SCALE" \
      --prompt-strength "$PROMPT_STRENGTH" \
      --width "$WIDTH" \
      --height "$HEIGHT" \
      --save-to-disk-path "$SAVE_TO_DISK_PATH" \
      --session_id "$frame_session_id" 2>/dev/null)
  fi
  
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    # Check if output files were actually created
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: Checking for output files in $SAVE_TO_DISK_PATH with session $frame_session_id"
      ls -la "$SAVE_TO_DISK_PATH"*"$frame_session_id"* 2>/dev/null || echo "DEBUG: No files found for session $frame_session_id"
    fi
    echo "✓ Frame $frame_num processed successfully"
    return 0
  else
    echo "✗ Failed to process frame $frame_num (exit code: $exit_code)"
    return 1
  fi
}

# Export function and variables for parallel processing
export -f process_frame
export TEMP_DIR PROMPT MODEL SEED NEGATIVE_PROMPT NUM_INFERENCE_STEPS 
export GUIDANCE_SCALE PROMPT_STRENGTH WIDTH HEIGHT SAVE_TO_DISK_PATH 
export SESSION_ID EASY_DIFFUSION_CLI END_FRAME

# Process frames in parallel or sequential mode
if [[ "$SEQUENTIAL" == true ]]; then
  # Sequential processing
  PROCESSED_COUNT=0
  for ((i=START_FRAME; i<=END_FRAME; i++)); do
    if process_frame $i; then
      ((PROCESSED_COUNT++))
    fi
    
    # Add delay between requests
    if [[ $i -lt $END_FRAME ]]; then
      sleep $DELAY
    fi
  done
else
  # Parallel processing with batching and concurrency control
  PROCESSED_COUNT=0
  TOTAL_TO_PROCESS=$((END_FRAME - START_FRAME + 1))
  
  # Create array of frame numbers to process
  FRAMES_TO_PROCESS=()
  for ((i=START_FRAME; i<=END_FRAME; i++)); do
    FRAMES_TO_PROCESS+=($i)
  done
  
  # Process frames in batches
  for ((batch_start=0; batch_start<${#FRAMES_TO_PROCESS[@]}; batch_start+=BATCH_SIZE)); do
    batch_end=$((batch_start + BATCH_SIZE - 1))
    if [[ $batch_end -ge ${#FRAMES_TO_PROCESS[@]} ]]; then
      batch_end=$((${#FRAMES_TO_PROCESS[@]} - 1))
    fi
    
    echo "Processing batch: frames ${FRAMES_TO_PROCESS[$batch_start]} to ${FRAMES_TO_PROCESS[$batch_end]}"
    
    # Create semaphore for concurrency control
    SEMAPHORE="/tmp/video_diffusion_sem_$$"
    mkfifo "$SEMAPHORE"
    exec 3<>"$SEMAPHORE"
    rm "$SEMAPHORE"
    
    # Initialize semaphore with tokens
    for ((i=0; i<MAX_CONCURRENT_REQUESTS; i++)); do
      echo >&3
    done
    
    # Process frames in current batch
    for ((i=batch_start; i<=batch_end; i++)); do
      frame_num=${FRAMES_TO_PROCESS[$i]}
      
      # Wait for semaphore token
      read <&3
      
      # Process frame in background
      {
        if process_frame $frame_num; then
          echo "PROCESSED:$frame_num" >> "/tmp/video_diffusion_results_$$"
        fi
        
        # Add small delay to prevent overwhelming the server
        sleep $DELAY
        
        # Release semaphore token
        echo >&3
      } &
    done
    
    # Wait for all background jobs in this batch to complete
    wait
    
    # Clean up semaphore
    exec 3>&-
    
    # Count processed frames
    if [[ -f "/tmp/video_diffusion_results_$$" ]]; then
      BATCH_PROCESSED=$(wc -l < "/tmp/video_diffusion_results_$$" 2>/dev/null || echo 0)
      PROCESSED_COUNT=$BATCH_PROCESSED
    fi
    
    echo "Batch completed. Processed: $PROCESSED_COUNT/$TOTAL_TO_PROCESS frames so far"
    echo ""
  done
  
  # Clean up results file
  rm -f "/tmp/video_diffusion_results_$$"
fi

echo "=== Processing Complete ==="
echo "Total frames processed: $PROCESSED_COUNT"
echo "Output directory: $SAVE_TO_DISK_PATH"

# Clean up temporary frames unless user wants to keep them
if [[ "$KEEP_FRAMES" == false ]]; then
  echo "Cleaning up temporary frames..."
  rm -rf "$TEMP_DIR"
else
  echo "Temporary frames kept in: $TEMP_DIR"
fi

echo "Video diffusion processing completed!"

# Automatically create video from generated images unless --no-video flag is used
if [[ "$NO_VIDEO" == false ]]; then
  # Create output video filename using first 3 prompt words and timestamp
  OUTPUT_VIDEO=$(generate_video_name "$PROMPT")
  echo "Creating video from generated images..."
  
  # Ensure output directory exists and navigate to it
  if [[ ! -d "$SAVE_TO_DISK_PATH" ]]; then
    echo "Error: Output directory '$SAVE_TO_DISK_PATH' does not exist!"
    exit 1
  fi
  
  cd "$SAVE_TO_DISK_PATH" || {
    echo "Error: Cannot navigate to output directory '$SAVE_TO_DISK_PATH'"
    exit 1
  }
  
  # Rename files to sequential format if needed
  echo "Organizing generated images..."
  
  # Check what image files we have for this session
  echo "Checking for generated images from session: $SESSION_ID..."
  
  # Get the most recent files for each frame (in case of multiple runs)
  UNIQUE_FRAMES=()
  for ((i=1; i<=END_FRAME; i++)); do
    frame_pattern="${SESSION_ID}_frame_$(printf "%04d" $i)_*"
    # Get the most recent file for this frame (by modification time)
    latest_file=$(ls -1t ${frame_pattern}.jpeg ${frame_pattern}.jpg ${frame_pattern}.png 2>/dev/null | head -1)
    if [[ -n "$latest_file" && -f "$latest_file" ]]; then
      UNIQUE_FRAMES+=("$latest_file")
    fi
  done
  
  if [[ ${#UNIQUE_FRAMES[@]} -eq 0 ]]; then
    echo "Error: No image files found for session '$SESSION_ID' frames 1-$END_FRAME!"
    echo "Looking for files in: $(pwd)"
    echo "All session files found:"
    ls -la "${SESSION_ID}"* 2>/dev/null || echo "No session files found"
    echo "Expected pattern: ${SESSION_ID}_frame_XXXX_*.{jpeg,jpg,png}"
    exit 1
  fi
  
  echo "Found ${#UNIQUE_FRAMES[@]} unique frame files for session $SESSION_ID"
  echo "Files: ${UNIQUE_FRAMES[@]}"
  
  # Rename files to sequential format
  COUNTER=1
  FINAL_EXTENSION="jpeg"  # Default extension
  RENAMED_FILES=()
  for file in "${UNIQUE_FRAMES[@]}"; do
    if [[ -f "$file" ]]; then
      # Get file extension
      EXTENSION="${file##*.}"
      NEW_NAME="generated_frame_$(printf "%04d" $COUNTER).$EXTENSION"
      if mv "$file" "$NEW_NAME" 2>/dev/null; then
        echo "Renamed $file to $NEW_NAME"
        FINAL_EXTENSION="$EXTENSION"
        RENAMED_FILES+=("$NEW_NAME")
        ((COUNTER++))
      else
        echo "Warning: Failed to rename $file"
      fi
    fi
  done
  
  # Use the extension from the first file
  PATTERN="generated_frame_%04d.$FINAL_EXTENSION"
  echo "Using pattern: $PATTERN"
  
  # Verify renamed files exist
  RENAMED_COUNT=${#RENAMED_FILES[@]}
  echo "Successfully renamed $RENAMED_COUNT files"
  
  if [[ $RENAMED_COUNT -eq 0 ]]; then
    echo "Error: No files were successfully renamed!"
    echo "Available files in directory:"
    ls -la "${SESSION_ID}"* 2>/dev/null || echo "No session files found"
    exit 1
  fi
  
  # Create video with hardware acceleration if available
  echo "Encoding video with optimal settings..."
  
  # Try hardware-accelerated encoding first
  if ffmpeg -encoders 2>/dev/null | grep -q "nvenc\|vaapi\|videotoolbox"; then
    echo "Using hardware-accelerated encoding..."
    ffmpeg -framerate 30 -i "$PATTERN" \
           -c:v h264_nvenc -preset fast -crf 18 -pix_fmt yuv420p \
           "$OUTPUT_VIDEO" -y 2>/dev/null || \
    ffmpeg -framerate 30 -i "$PATTERN" \
           -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
           "$OUTPUT_VIDEO" -y
  else
    echo "Using software encoding with optimized settings..."
    ffmpeg -framerate 30 -i "$PATTERN" \
           -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
           -threads $PARALLEL_JOBS "$OUTPUT_VIDEO" -y
  fi
  
  if [[ $? -eq 0 ]]; then
    echo "✓ Video created: $OUTPUT_VIDEO"
    
    # Clean up generated images after successful video creation
    echo "Cleaning up generated images..."
    for file in "${UNIQUE_FRAMES[@]}"; do
      if [[ -f "$file" ]]; then
        rm -f "$file" 2>/dev/null
      fi
    done
    # Also clean up the renamed files
    rm -f generated_frame_*.$FINAL_EXTENSION 2>/dev/null
    echo "✓ Generated images cleaned up"
  else
    echo "✗ Failed to create video"
    echo "Generated images preserved in: $SAVE_TO_DISK_PATH"
  fi
else
  echo "Video creation skipped (--no-video flag used)"
  echo "Generated images preserved in: $SAVE_TO_DISK_PATH"
fi
