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
  echo "🚀 Performance & Processing:"
  echo "       [--hybrid-processing] (enable GPU+CPU hybrid processing for maximum speed)"
  echo "       [--cpu-fallback] (enable CPU fallback when GPU is overloaded)"
  echo "       [--gpu-ports 'PORT1,PORT2'] (GPU server ports, default: 9000)"
  echo "       [--cpu-ports 'PORT1,PORT2'] (CPU server ports, default: 9010)"
  echo "       [--max-concurrent NUM] (max concurrent API requests, default: auto-detected)"
  echo "       [--parallel-jobs NUM] (parallel frame extraction jobs, default: auto-detected)"
  echo "       [--batch-size NUM] (frames per batch, default: auto-detected)"
  echo "       [--sequential] (disable parallel processing, process one by one)"
  echo "       [--delay SECONDS] (delay between requests, default: 0.005-0.05)"
  echo ""
  echo "🎯 Temporal Smoothing:"
  echo "       [--smoothing METHOD] (temporal smoothing: 'init', 'optical', 'temporal', 'none')"
  echo "       [--smoothing-strength FLOAT] (smoothing intensity 0.0-1.0, default: 0.3)"
  echo ""
  echo "🎬 Video & Frame Control:"
  echo "       [--fps FPS] (frames per second, default: auto-detect from source video)"
  echo "       [--start-frame NUM] (start processing from frame number, default: 1)"
  echo "       [--end-frame NUM] (stop processing at frame number, default: all)"
  echo "       [--keep-frames] (preserve extracted frames after processing)"
  echo "       [--no-video] (generate images only, skip video creation)"
  echo ""
  echo "🎨 AI Generation Parameters:"
  echo "       [--model MODEL] (AI model, default: sd-v1-5.safetensors)"
  echo "       [--seed SEED] (random seed, default: random per frame)"
  echo "       [--negative-prompt \"TEXT\"] (what to avoid in generation)"
  echo "       [--num-inference-steps STEPS] (quality vs speed, default: 46)"
  echo "       [--guidance-scale SCALE] (prompt adherence, default: 7.5)"
  echo "       [--prompt-strength STRENGTH] (init image influence, default: 0.5)"
  echo "       [--width WIDTH] (output width, default: 512)"
  echo "       [--height HEIGHT] (output height, default: 512)"
  echo ""
  echo "📁 Output & Debug:"
  echo "       [--save-to-disk-path PATH] (output directory, default: ./output/)"
  echo "       [--session_id ID] (session identifier, default: auto-generated)"
  echo "       [--temp-dir PATH] (temporary frames directory, default: ./temp_frames)"
  echo "       [--debug] (enable comprehensive debug output)"
  echo ""
  echo "🎯 Smoothing Methods:"
  echo "  init     - Use previous generated frame as init image (best quality/speed)"
  echo "  optical  - Apply optical flow-based frame blending (motion-heavy content)"
  echo "  temporal - Apply temporal filtering using neighboring frames (maximum consistency)"
  echo "  none     - No smoothing (fastest, may flicker)"
  echo ""
  echo "📋 Examples:"
  echo "  # Basic usage with auto-optimization"
  echo "  $0 --video \"input.mp4\" --prompt \"watercolor painting\""
  echo ""
  echo "  # Hybrid GPU+CPU processing with smoothing"
  echo "  $0 --video \"input.mp4\" --prompt \"cyberpunk city\" --hybrid-processing --smoothing init"
  echo ""
  echo "  # High-quality with temporal smoothing"
  echo "  $0 --video \"input.mp4\" --prompt \"Van Gogh style\" --smoothing temporal --smoothing-strength 0.4"
  echo ""
  echo "Output video will be named using first 3 words of prompt + timestamp (e.g., van_gogh_starry_2025-08-03_0130.mp4)"
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

# Temporal smoothing functions for reducing frame-to-frame inconsistency

# Function to apply temporal smoothing using optical flow
apply_optical_flow_smoothing() {
  local output_dir="$1"
  local smoothing_strength="$2"
  local temp_smooth_dir="${output_dir}/temp_smooth"
  
  echo "Applying optical flow smoothing (strength: $smoothing_strength)..."
  mkdir -p "$temp_smooth_dir"
  
  # Get list of generated images sorted by frame number
  local images=($(ls "$output_dir"/*.jpeg 2>/dev/null | sort -V))
  
  if [[ ${#images[@]} -lt 2 ]]; then
    echo "Warning: Not enough frames for optical flow smoothing"
    return 0
  fi
  
  # Copy first frame as-is
  cp "${images[0]}" "$temp_smooth_dir/$(basename "${images[0]}")"
  
  # Apply optical flow smoothing to subsequent frames
  for ((i=1; i<${#images[@]}; i++)); do
    local prev_frame="${images[$((i-1))]}"
    local curr_frame="${images[$i]}"
    local output_frame="$temp_smooth_dir/$(basename "$curr_frame")"
    
    # Use FFmpeg's minterpolate filter for optical flow-based frame blending
    ffmpeg -i "$prev_frame" -i "$curr_frame" \
      -filter_complex "[0:v][1:v]blend=all_expr='A*(1-${smoothing_strength})+B*${smoothing_strength}'" \
      -y "$output_frame" 2>/dev/null || {
        echo "Warning: Optical flow smoothing failed for frame $i, using original"
        cp "$curr_frame" "$output_frame"
      }
  done
  
  # Replace original images with smoothed versions
  cp "$temp_smooth_dir"/*.jpeg "$output_dir/"
  rm -rf "$temp_smooth_dir"
  
  echo "✓ Optical flow smoothing applied"
}

# Function to apply temporal filtering (post-processing approach)
apply_temporal_filtering() {
  local output_dir="$1"
  local smoothing_strength="$2"
  local temp_filter_dir="${output_dir}/temp_filter"
  
  echo "Applying temporal filtering (strength: $smoothing_strength)..."
  mkdir -p "$temp_filter_dir"
  
  # Get list of generated images sorted by frame number
  local images=($(ls "$output_dir"/*.jpeg 2>/dev/null | sort -V))
  
  if [[ ${#images[@]} -lt 3 ]]; then
    echo "Warning: Not enough frames for temporal filtering"
    return 0
  fi
  
  # Copy first frame as-is
  cp "${images[0]}" "$temp_filter_dir/$(basename "${images[0]}")"
  
  # Apply temporal filter using weighted average of previous, current, and next frames
  for ((i=1; i<${#images[@]}-1; i++)); do
    local prev_frame="${images[$((i-1))]}"
    local curr_frame="${images[$i]}"
    local next_frame="${images[$((i+1))]}"
    local output_frame="$temp_filter_dir/$(basename "$curr_frame")"
    
    local weight_curr=$(echo "1.0 - $smoothing_strength" | bc -l)
    local weight_neighbors=$(echo "$smoothing_strength / 2.0" | bc -l)
    
    # Use FFmpeg to blend three frames with temporal weights
    ffmpeg -i "$prev_frame" -i "$curr_frame" -i "$next_frame" \
      -filter_complex "[1:v]scale=512:512[curr];[0:v]scale=512:512[prev];[2:v]scale=512:512[next];[prev][curr][next]blend=all_expr='B*${weight_curr}+A*${weight_neighbors}+C*${weight_neighbors}'" \
      -y "$output_frame" 2>/dev/null || {
        echo "Warning: Temporal filtering failed for frame $i, using original"
        cp "$curr_frame" "$output_frame"
      }
  done
  
  # Copy last frame as-is
  cp "${images[-1]}" "$temp_filter_dir/$(basename "${images[-1]}")"
  
  # Replace original images with filtered versions
  cp "$temp_filter_dir"/*.jpeg "$output_dir/"
  rm -rf "$temp_filter_dir"
  
  echo "✓ Temporal filtering applied"
}

# Hybrid GPU+CPU Processing Functions

# Function to check server availability
check_server() {
  local port="$1"
  local timeout="${2:-5}"
  
  if timeout "$timeout" curl -s "http://localhost:$port/ping" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to get server load (enhanced implementation)
get_server_load() {
  local port="$1"
  
  # Simple load check - count active connections or use ping response time
  local response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:$port/ping" 2>/dev/null || echo "999")
  
  # Convert to load score (lower is better)
  if (( $(echo "$response_time < 0.1" | bc -l) )); then
    echo "1"  # Low load
  elif (( $(echo "$response_time < 0.5" | bc -l) )); then
    echo "2"  # Medium load
  else
    echo "3"  # High load
  fi
}

# Enhanced server tracking with file-based synchronization for parallel processing
SERVER_TRACKING_DIR="/tmp/video_diffusion_servers_$$"

# Function to initialize server tracking
init_server_tracking() {
  local gpu_ports_array=(${GPU_PORTS//,/ })
  local cpu_ports_array=(${CPU_PORTS//,/ })
  
  # Create tracking directory
  mkdir -p "$SERVER_TRACKING_DIR"
  
  # Initialize GPU servers
  for port in "${gpu_ports_array[@]}"; do
    echo "0" > "$SERVER_TRACKING_DIR/${port}_GPU_queue"
    echo "0" > "$SERVER_TRACKING_DIR/${port}_GPU_lastused"
  done
  
  # Initialize CPU servers if hybrid processing enabled
  if [[ "$HYBRID_PROCESSING" == true ]] || [[ "$CPU_FALLBACK" == true ]]; then
    for port in "${cpu_ports_array[@]}"; do
      echo "0" > "$SERVER_TRACKING_DIR/${port}_CPU_queue"
      echo "0" > "$SERVER_TRACKING_DIR/${port}_CPU_lastused"
    done
  fi
}

# Function to get server queue count
get_server_queue() {
  local port="$1"
  local server_type="$2"
  local queue_file="$SERVER_TRACKING_DIR/${port}_${server_type}_queue"
  
  if [[ -f "$queue_file" ]]; then
    cat "$queue_file"
  else
    echo "0"
  fi
}

# Function to get server last used time
get_server_last_used() {
  local port="$1"
  local server_type="$2"
  local lastused_file="$SERVER_TRACKING_DIR/${port}_${server_type}_lastused"
  
  if [[ -f "$lastused_file" ]]; then
    cat "$lastused_file"
  else
    echo "0"
  fi
}

# Function to increment server queue
increment_server_queue() {
  local port="$1"
  local server_type="$2"
  local queue_file="$SERVER_TRACKING_DIR/${port}_${server_type}_queue"
  local lastused_file="$SERVER_TRACKING_DIR/${port}_${server_type}_lastused"
  
  # Use flock for atomic operations
  (
    flock -x 200
    local current_queue=$(cat "$queue_file" 2>/dev/null || echo "0")
    echo $((current_queue + 1)) > "$queue_file"
    date +%s > "$lastused_file"
  ) 200>"$queue_file.lock"
}

# Function to decrement server queue
decrement_server_queue() {
  local port="$1"
  local server_type="$2"
  local queue_file="$SERVER_TRACKING_DIR/${port}_${server_type}_queue"
  
  # Use flock for atomic operations
  (
    flock -x 200
    local current_queue=$(cat "$queue_file" 2>/dev/null || echo "0")
    if [[ $current_queue -gt 0 ]]; then
      echo $((current_queue - 1)) > "$queue_file"
    fi
  ) 200>"$queue_file.lock"
}

# Function to select best available server with proper queue management
select_best_server() {
  local gpu_ports_array=(${GPU_PORTS//,/ })
  local cpu_ports_array=(${CPU_PORTS//,/ })
  local best_server=""
  local min_queue=999
  local current_time=$(date +%s)
  
  # Function to check if server is truly available
  server_is_available() {
    local port="$1"
    local server_type="$2"
    
    # Check basic connectivity
    if ! check_server "$port" 1; then
      return 1
    fi
    
    # Check queue count and recent usage
    local queue_count=$(get_server_queue "$port" "$server_type")
    local last_used=$(get_server_last_used "$port" "$server_type")
    local time_since_last=$((current_time - last_used))
    
    # Server-specific availability logic
    if [[ "$server_type" == "CPU" ]]; then
      # CPU servers are much more restrictive
      local max_cpu_queue=1  # Only 1 frame at a time for CPU
      if [[ $time_since_last -lt 60 ]]; then
        # CPU servers need more breathing room (60 seconds to match processing delay)
        return 1
      fi
      if [[ $queue_count -gt $max_cpu_queue ]]; then
        return 1
      fi
    else
      # GPU servers can handle more load
      local max_gpu_queue=15
      if [[ $time_since_last -lt 5 ]]; then
        # GPU servers need less breathing room (5 seconds)
        if [[ $queue_count -gt 8 ]]; then
          return 1
        fi
      fi
      if [[ $queue_count -gt $max_gpu_queue ]]; then
        return 1
      fi
    fi
    
    return 0
  }
  
  # Check GPU servers first (preferred for speed)
  for port in "${gpu_ports_array[@]}"; do
    if server_is_available "$port" "GPU"; then
      local queue_count=$(get_server_queue "$port" "GPU")
      if [[ $queue_count -lt $min_queue ]]; then
        min_queue=$queue_count
        best_server="$port:GPU"
      fi
    fi
  done
  
  # If hybrid processing enabled, also check CPU servers
  if [[ "$HYBRID_PROCESSING" == true ]] && [[ -z "$best_server" || $min_queue -gt 2 ]]; then
    for port in "${cpu_ports_array[@]}"; do
      if server_is_available "$port" "CPU"; then
        local queue_count=$(get_server_queue "$port" "CPU")
        # Prefer CPU if GPU is heavily loaded or for load balancing
        if [[ $queue_count -lt $min_queue ]] || [[ "$HYBRID_PROCESSING" == true && $queue_count -le 5 ]]; then
          min_queue=$queue_count
          best_server="$port:CPU"
        fi
      fi
    done
  fi
  
  # CPU fallback logic
  if [[ "$CPU_FALLBACK" == true ]] && [[ -z "$best_server" || $min_queue -gt 12 ]]; then
    for port in "${cpu_ports_array[@]}"; do
      if server_is_available "$port" "CPU"; then
        local queue_count=$(get_server_queue "$port" "CPU")
        if [[ $queue_count -lt $min_queue ]]; then
          min_queue=$queue_count
          best_server="$port:CPU"
        fi
      fi
    done
  fi
  
  # If we found a server, update tracking
  if [[ -n "$best_server" ]]; then
    local selected_port="${best_server%%:*}"
    local server_type="${best_server##*:}"
    increment_server_queue "$selected_port" "$server_type"
    echo "$best_server"
  else
    # Fallback to default GPU
    increment_server_queue "9000" "GPU"
    echo "9000:GPU"
  fi
}

# Function to release server when job completes
release_server() {
  local server="$1"
  if [[ -n "$server" ]]; then
    local port="${server%%:*}"
    local server_type="${server##*:}"
    decrement_server_queue "$port" "$server_type"
  fi
}

# Cleanup function for server tracking
cleanup_server_tracking() {
  if [[ -d "$SERVER_TRACKING_DIR" ]]; then
    rm -rf "$SERVER_TRACKING_DIR"
  fi
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
SMOOTHING="none"
SMOOTHING_STRENGTH=0.3
HYBRID_PROCESSING=false
CPU_FALLBACK=false
GPU_PORTS="9000"
CPU_PORTS="9010"
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
    --hybrid-processing) HYBRID_PROCESSING=true ;;
    --cpu-fallback) CPU_FALLBACK=true ;;
    --gpu-ports) GPU_PORTS="$2"; shift ;;
    --cpu-ports) CPU_PORTS="$2"; shift ;;
    --smoothing) SMOOTHING="$2"; shift ;;
    --smoothing-strength) SMOOTHING_STRENGTH="$2"; shift ;;
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

# Validate smoothing parameters
case "$SMOOTHING" in
  "none"|"init"|"optical"|"temporal")
    ;;
  *)
    echo "Error: Invalid smoothing method '$SMOOTHING'. Valid options: none, init, optical, temporal"
    exit 1
    ;;
esac

# Validate smoothing strength
if ! [[ "$SMOOTHING_STRENGTH" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$SMOOTHING_STRENGTH < 0.0" | bc -l) )) || (( $(echo "$SMOOTHING_STRENGTH > 1.0" | bc -l) )); then
  echo "Error: Smoothing strength must be between 0.0 and 1.0, got: $SMOOTHING_STRENGTH"
  exit 1
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

# Check if bc (basic calculator) is available for smoothing calculations
if [[ "$SMOOTHING" != "none" ]] && ! command -v bc &> /dev/null; then
  echo "Error: 'bc' command is required for smoothing calculations but not found. Install it with:"
  echo "sudo apt-get install bc"
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
      DELAY=0.005
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

echo "=== Video Diffusion Processing (Hybrid GPU+CPU) ==="
echo "Video: $VIDEO_PATH"
echo "Prompt: $PROMPT"
echo "FPS: $FPS"
echo "Parallel extraction jobs: $PARALLEL_JOBS"
echo "Max concurrent API requests: $MAX_CONCURRENT_REQUESTS"
echo "Batch size: $BATCH_SIZE"
if [[ "$HYBRID_PROCESSING" == true ]]; then
  echo "Processing mode: Hybrid GPU+CPU (GPU: $GPU_PORTS, CPU: $CPU_PORTS)"
elif [[ "$CPU_FALLBACK" == true ]]; then
  echo "Processing mode: GPU with CPU fallback (GPU: $GPU_PORTS, CPU: $CPU_PORTS)"
else
  echo "Processing mode: GPU only (Port: $GPU_PORTS)"
fi
if [[ "$SMOOTHING" != "none" ]]; then
  echo "Temporal smoothing: $SMOOTHING (strength: $SMOOTHING_STRENGTH)"
fi
echo "Temporary frames directory: $TEMP_DIR"
echo "Output directory: $SAVE_TO_DISK_PATH"
echo "==============================================="
echo ""

# Check server availability before processing
echo "Checking server availability..."
gpu_ports_array=(${GPU_PORTS//,/ })
cpu_ports_array=(${CPU_PORTS//,/ })

available_gpu_servers=0
available_cpu_servers=0

for port in "${gpu_ports_array[@]}"; do
  if check_server "$port" 3; then
    echo "✓ GPU server available on port $port"
    ((available_gpu_servers++))
  else
    echo "✗ GPU server unavailable on port $port"
  fi
done

if [[ "$HYBRID_PROCESSING" == true ]] || [[ "$CPU_FALLBACK" == true ]]; then
  for port in "${cpu_ports_array[@]}"; do
    if check_server "$port" 3; then
      echo "✓ CPU server available on port $port"
      ((available_cpu_servers++))
    else
      echo "✗ CPU server unavailable on port $port"
    fi
  done
fi

total_servers=$((available_gpu_servers + available_cpu_servers))
if [[ $total_servers -eq 0 ]]; then
  echo "Error: No Easy Diffusion servers are available!"
  echo "Please start at least one Easy Diffusion server before proceeding."
  exit 1
fi

echo "Total available servers: $total_servers (GPU: $available_gpu_servers, CPU: $available_cpu_servers)"
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

  # Determine init image based on smoothing method
  local init_image="$frame_file"
  local prompt_strength_adjusted="$PROMPT_STRENGTH"
  
  if [[ "$SMOOTHING" == "init" ]] && [[ $frame_num -gt $START_FRAME ]]; then
    # For init smoothing, use the previously generated frame as init image
    local prev_frame_num=$((frame_num - 1))
    local prev_generated_pattern="${SAVE_TO_DISK_PATH}/*frame_$(printf "%04d" $prev_frame_num)*.jpeg"
    local prev_generated_file=$(ls $prev_generated_pattern 2>/dev/null | head -1)
    
    if [[ -f "$prev_generated_file" ]]; then
      init_image="$prev_generated_file"
      # Adjust prompt strength for smoother transitions
      prompt_strength_adjusted=$(echo "$PROMPT_STRENGTH * (1.0 - $SMOOTHING_STRENGTH)" | bc -l)
      echo "Using init smoothing: previous frame -> current (strength: $prompt_strength_adjusted)"
    else
      echo "Warning: Previous generated frame not found, using original frame"
    fi
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
  
  # Select best available server for hybrid processing
  local server_info
  if [[ "$HYBRID_PROCESSING" == true ]] || [[ "$CPU_FALLBACK" == true ]]; then
    server_info=$(select_best_server)
    local selected_port="${server_info%%:*}"
    local server_type="${server_info##*:}"
    local current_queue=$(get_server_queue "$selected_port" "$server_type")
    echo "Using $server_type server on port $selected_port for frame $frame_num (queue: $current_queue)"
  else
    selected_port="9000"
    server_type="GPU"
    server_info="9000:GPU"
    increment_server_queue "9000" "GPU"
  fi
  
  # Set timeout based on server type - CPU needs much longer
  local timeout_value
  if [[ "$server_type" == "CPU" ]]; then
    timeout_value=600  # 10 minutes for CPU processing
    echo "Using extended timeout for CPU processing: ${timeout_value}s"
  else
    timeout_value=120  # 2 minutes for GPU processing
  fi
  
  # Debug output if enabled
  if [[ "$DEBUG" == true ]]; then
    echo "DEBUG: Command: bash $EASY_DIFFUSION_CLI --prompt \"$PROMPT\" --model \"$MODEL\" --init-image \"$init_image\" --seed \"$frame_seed\" --port \"$selected_port\" --timeout \"$timeout_value\" --save-to-disk-path \"$SAVE_TO_DISK_PATH\" --session_id \"$frame_session_id\""
  fi
  
  # Run easy-diffusion-cli-enhanced.sh with the init image and capture response
  local api_response
  if [[ "$DEBUG" == true ]]; then
    api_response=$(bash "$EASY_DIFFUSION_CLI" \
      --prompt "$PROMPT" \
      --model "$MODEL" \
      --init-image "$init_image" \
      --seed "$frame_seed" \
      --negative-prompt "$NEGATIVE_PROMPT" \
      --num-inference-steps "$NUM_INFERENCE_STEPS" \
      --guidance-scale "$GUIDANCE_SCALE" \
      --prompt-strength "$prompt_strength_adjusted" \
      --width "$WIDTH" \
      --height "$HEIGHT" \
      --port "$selected_port" \
      --timeout "$timeout_value" \
      --save-to-disk-path "$SAVE_TO_DISK_PATH" \
      --session_id "$frame_session_id")
    echo "DEBUG: API Response: $api_response"
  else
    api_response=$(bash "$EASY_DIFFUSION_CLI" \
      --prompt "$PROMPT" \
      --model "$MODEL" \
      --init-image "$init_image" \
      --seed "$frame_seed" \
      --negative-prompt "$NEGATIVE_PROMPT" \
      --num-inference-steps "$NUM_INFERENCE_STEPS" \
      --guidance-scale "$GUIDANCE_SCALE" \
      --prompt-strength "$prompt_strength_adjusted" \
      --width "$WIDTH" \
      --height "$HEIGHT" \
      --port "$selected_port" \
      --timeout "$timeout_value" \
      --save-to-disk-path "$SAVE_TO_DISK_PATH" \
      --session_id "$frame_session_id" 2>/dev/null)
  fi
  
  local exit_code=$?
  
  # Release server from queue tracking
  release_server "$server_info"
  
  if [[ $exit_code -eq 0 ]]; then
    # Verify that output files were actually created
    local output_files=()
    
    # Check for files with different extensions separately to avoid bash expansion issues
    for ext in jpeg jpg png; do
      while IFS= read -r -d '' file; do
        output_files+=("$file")
      done < <(find "$SAVE_TO_DISK_PATH" -name "*${frame_session_id}*.${ext}" -print0 2>/dev/null)
    done
    
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: Searching for files matching: $SAVE_TO_DISK_PATH*$frame_session_id*.{jpeg,jpg,png}"
      echo "DEBUG: Found ${#output_files[@]} files: ${output_files[*]}"
    fi
    
    if [[ ${#output_files[@]} -gt 0 ]]; then
      # Additional verification: check file size
      local largest_file=""
      local largest_size=0
      for file in "${output_files[@]}"; do
        if [[ -f "$file" ]]; then
          # Use stat command that works on Linux
          local file_size=$(stat -c%s "$file" 2>/dev/null || wc -c < "$file" 2>/dev/null || echo 0)
          if [[ $file_size -gt $largest_size ]]; then
            largest_size=$file_size
            largest_file="$file"
          fi
        fi
      done
      
      if [[ $largest_size -gt 1000 ]]; then  # File should be at least 1KB
        if [[ "$DEBUG" == true ]]; then
          echo "DEBUG: Output verified: $largest_file ($largest_size bytes)"
        fi
        echo "✓ Frame $frame_num processed successfully ($server_type server)"
        # Write success to results file for batch tracking
        echo "PROCESSED:$frame_num:$server_type" >> "/tmp/video_diffusion_results_$$"
        return 0
      else
        echo "✗ Frame $frame_num: Output file too small ($largest_size bytes) - likely corrupted"
        if [[ "$DEBUG" == true ]]; then
          echo "DEBUG: Files found but all too small: ${output_files[*]}"
        fi
        # Write failure to failures file for batch tracking
        echo "FAILED:$frame_num:$server_type" >> "/tmp/video_diffusion_failures_$$"
        return 1
      fi
    else
      echo "✗ Frame $frame_num: No output files created (API success but no files)"
      if [[ "$DEBUG" == true ]]; then
        echo "DEBUG: Expected pattern: $SAVE_TO_DISK_PATH*$frame_session_id*.{jpeg,jpg,png}"
        echo "DEBUG: Files in output directory:"
        ls -la "$SAVE_TO_DISK_PATH" | head -10
        echo "DEBUG: Session ID: $frame_session_id"
        echo "DEBUG: Save path: $SAVE_TO_DISK_PATH"
      fi
      # Write failure to failures file for batch tracking
      echo "FAILED:$frame_num:$server_type" >> "/tmp/video_diffusion_failures_$$"
      return 1
    fi
  else
    echo "✗ Failed to process frame $frame_num (exit code: $exit_code, $server_type server)"
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: API call failed for frame $frame_num on $server_type server port $selected_port"
    fi
    # Write failure to failures file for batch tracking
    echo "FAILED:$frame_num:$server_type" >> "/tmp/video_diffusion_failures_$$"
    return 1
  fi
}

# Export function and variables for parallel processing
export -f process_frame select_best_server check_server get_server_load release_server
export -f get_server_queue get_server_last_used increment_server_queue decrement_server_queue
export TEMP_DIR PROMPT MODEL SEED NEGATIVE_PROMPT NUM_INFERENCE_STEPS 
export GUIDANCE_SCALE PROMPT_STRENGTH WIDTH HEIGHT SAVE_TO_DISK_PATH 
export SESSION_ID EASY_DIFFUSION_CLI END_FRAME SMOOTHING SMOOTHING_STRENGTH
export HYBRID_PROCESSING CPU_FALLBACK GPU_PORTS CPU_PORTS DEBUG SERVER_TRACKING_DIR

# Initialize server tracking before processing starts
echo "Initializing server queue management..."
init_server_tracking

if [[ "$DEBUG" == true ]]; then
  echo "DEBUG: Server tracking initialized in $SERVER_TRACKING_DIR"
  ls -la "$SERVER_TRACKING_DIR/"
fi

# Ensure cleanup on exit
trap cleanup_server_tracking EXIT

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
  # Enhanced parallel processing with CPU-specific batching and frame requeuing
  PROCESSED_COUNT=0
  TOTAL_TO_PROCESS=$((END_FRAME - START_FRAME + 1))
  
  # Create array of frame numbers to process
  FRAMES_TO_PROCESS=()
  for ((i=START_FRAME; i<=END_FRAME; i++)); do
    FRAMES_TO_PROCESS+=($i)
  done
  
  # Track failed frames for requeuing
  FAILED_FRAMES=()
  RETRY_ATTEMPTS="/tmp/video_diffusion_retries_$$"
  > "$RETRY_ATTEMPTS"  # Initialize retry tracking file
  
  # Function to process frames with CPU-aware batching
  process_frames_batch() {
    local frames_list=("$@")
    local batch_results=()
    
    # Determine if this batch should use CPU-specific handling
    local use_cpu_batching=false
    if [[ "$HYBRID_PROCESSING" == true ]] || [[ "$CPU_FALLBACK" == true ]]; then
      # Check if we're likely to use CPU servers (GPU overloaded)
      local gpu_load=0
      local gpu_ports_array=(${GPU_PORTS//,/ })
      for port in "${gpu_ports_array[@]}"; do
        if check_server "$port" 1; then
          local gpu_queue=$(get_server_queue "$port" "GPU")
          gpu_load=$((gpu_load + gpu_queue))
        fi
      done
      
      # If GPU servers are heavily loaded, use CPU-specific batching
      if [[ $gpu_load -gt 10 ]]; then
        use_cpu_batching=true
        echo "GPU servers heavily loaded (queue: $gpu_load), using CPU-optimized batching"
      fi
    fi
    
    if [[ "$use_cpu_batching" == true ]]; then
      # CPU-optimized processing: one frame at a time with higher timeout
      echo "Processing ${#frames_list[@]} frames with CPU-optimized batching (1 frame at a time)"
      
      for frame_num in "${frames_list[@]}"; do
        echo "Processing CPU batch: frame $frame_num"
        
        # Process single frame with extended timeout for CPU - NO PARALLEL PROCESSING
        local start_time=$(date +%s)
        if process_frame "$frame_num"; then
          local end_time=$(date +%s)
          local duration=$((end_time - start_time))
          echo "✓ CPU frame $frame_num completed in ${duration}s"
        else
          echo "✗ CPU frame $frame_num failed - will retry"
        fi
        
        # Add delay between CPU frames to prevent overload
        echo "CPU processing delay (60 seconds)..."
        sleep 60
      done
    else
      # GPU-optimized processing: standard batching
      echo "Processing ${#frames_list[@]} frames with GPU-optimized batching"
      
      # Create semaphore for concurrency control
      local gpu_semaphore="/tmp/video_diffusion_gpu_sem_$$"
      mkfifo "$gpu_semaphore"
      exec 3<>"$gpu_semaphore"
      rm "$gpu_semaphore"
      
      # Initialize semaphore with tokens
      for ((i=0; i<MAX_CONCURRENT_REQUESTS; i++)); do
        echo >&3
      done
      
      # Process frames in parallel
      for frame_num in "${frames_list[@]}"; do
        # Wait for semaphore token
        read <&3
        
        # Process frame in background
        {
          local start_time=$(date +%s)
          if process_frame "$frame_num"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            echo "✓ GPU frame $frame_num completed in ${duration}s"
          else
            echo "✗ GPU frame $frame_num failed - will retry"
          fi
          
          # Add small delay to prevent overwhelming the server
          sleep $DELAY
          
          # Release semaphore token
          echo >&3
        } &
      done
      
      # Wait for all background jobs to complete
      wait
      
      # Clean up semaphore
      exec 3>&-
    fi
  }
  
  # Main processing loop with retry logic
  retry_count=0
  max_retries=3
  
  while [[ ${#FRAMES_TO_PROCESS[@]} -gt 0 ]] && [[ $retry_count -lt $max_retries ]]; do
    echo "Processing ${#FRAMES_TO_PROCESS[@]} frames (attempt $((retry_count + 1))/$max_retries)"
    
    # Clear previous results
    > "/tmp/video_diffusion_results_$$"
    > "/tmp/video_diffusion_failures_$$"
    
    # Process current batch of frames
    process_frames_batch "${FRAMES_TO_PROCESS[@]}"
    
    # Count processed and failed frames
    processed_this_round=0
    failed_this_round=0
    
    if [[ -f "/tmp/video_diffusion_results_$$" ]]; then
      processed_this_round=$(wc -l < "/tmp/video_diffusion_results_$$" 2>/dev/null || echo 0)
      PROCESSED_COUNT=$((PROCESSED_COUNT + processed_this_round))
    fi
    
    if [[ -f "/tmp/video_diffusion_failures_$$" ]]; then
      failed_this_round=$(wc -l < "/tmp/video_diffusion_failures_$$" 2>/dev/null || echo 0)
      
      # Extract failed frame numbers for retry
      FAILED_FRAMES=()
      while read -r line; do
        if [[ "$line" =~ FAILED:([0-9]+):(CPU|GPU) ]]; then
          failed_frame="${BASH_REMATCH[1]}"
          server_type="${BASH_REMATCH[2]}"
          FAILED_FRAMES+=("$failed_frame")
          echo "$failed_frame:$((retry_count + 1)):$server_type" >> "$RETRY_ATTEMPTS"
          echo "  → Frame $failed_frame failed on $server_type server, queued for retry"
        fi
      done < "/tmp/video_diffusion_failures_$$"
    fi
    
    echo "Round $((retry_count + 1)) completed: $processed_this_round processed, $failed_this_round failed"
    
    # Prepare for next retry if needed
    if [[ ${#FAILED_FRAMES[@]} -gt 0 ]] && [[ $retry_count -lt $((max_retries - 1)) ]]; then
      echo "Requeuing ${#FAILED_FRAMES[@]} failed frames for retry..."
      
      # Check what types of servers failed to adjust retry strategy
      local cpu_failures=0
      local gpu_failures=0
      while read -r line; do
        if [[ "$line" =~ FAILED:([0-9]+):CPU ]]; then
          ((cpu_failures++))
        elif [[ "$line" =~ FAILED:([0-9]+):GPU ]]; then
          ((gpu_failures++))
        fi
      done < "/tmp/video_diffusion_failures_$$"
      
      if [[ $cpu_failures -gt 0 ]]; then
        echo "  → $cpu_failures CPU failures detected - increasing retry delay"
      fi
      if [[ $gpu_failures -gt 0 ]]; then
        echo "  → $gpu_failures GPU failures detected"
      fi
      
      FRAMES_TO_PROCESS=("${FAILED_FRAMES[@]}")
      ((retry_count++))
      
      # Add longer delay for CPU failures, shorter for GPU
      local retry_delay=10
      if [[ $cpu_failures -gt 0 ]]; then
        retry_delay=120  # CPU servers need much more recovery time
        echo "Waiting $retry_delay seconds before retry (CPU failures detected)..."
      else
        echo "Waiting $retry_delay seconds before retry..."
      fi
      sleep $retry_delay
    else
      break
    fi
  done
  
  # Final failed frames handling
  if [[ ${#FAILED_FRAMES[@]} -gt 0 ]]; then
    echo "⚠️  Warning: ${#FAILED_FRAMES[@]} frames failed after $max_retries attempts:"
    printf "   Frame %s\n" "${FAILED_FRAMES[@]}"
    echo "These frames may need manual reprocessing or server troubleshooting."
  fi
  
  # Clean up temporary files
  rm -f "/tmp/video_diffusion_results_$$" "/tmp/video_diffusion_failures_$$" "$RETRY_ATTEMPTS"
fi

echo "=== Processing Complete ==="
echo "Total frames processed: $PROCESSED_COUNT out of $TOTAL_TO_PROCESS"
if [[ ${#FAILED_FRAMES[@]} -gt 0 ]]; then
  echo "Failed frames: ${#FAILED_FRAMES[@]} (see warnings above)"
fi
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
  # Apply temporal smoothing if enabled
  if [[ "$SMOOTHING" != "none" ]] && [[ "$SMOOTHING" != "init" ]]; then
    echo ""
    echo "Applying temporal smoothing ($SMOOTHING method)..."
    case "$SMOOTHING" in
      "optical")
        apply_optical_flow_smoothing "$SAVE_TO_DISK_PATH" "$SMOOTHING_STRENGTH"
        ;;
      "temporal")
        apply_temporal_filtering "$SAVE_TO_DISK_PATH" "$SMOOTHING_STRENGTH"
        ;;
      *)
        echo "Warning: Unknown smoothing method '$SMOOTHING', skipping"
        ;;
    esac
  elif [[ "$SMOOTHING" == "init" ]]; then
    echo "✓ Init-based smoothing applied during generation"
  fi

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
