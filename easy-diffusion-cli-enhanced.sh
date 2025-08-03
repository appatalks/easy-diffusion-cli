#!/bin/bash

# Enhanced Easy Diffusion CLI that properly handles async responses
# This version polls the stream endpoint to retrieve the generated image

# Function to display usage instructions
usage() {
  echo "Usage: $0 --prompt \"Your prompt here\"" 
  echo ""
  echo " Optional arguments:"
  echo "       [--model MODEL]"
  echo "       [--init-image \"/path/to/image\"]" 
  echo "       [--seed SEED]"
  echo "       [--negative-prompt \"Negative prompt\"]"
  echo "       [--num-inference-steps STEPS]" 
  echo "       [--guidance-scale SCALE] (Higher the number, more weight to prompt)"
  echo "       [--prompt-strength STRENGTH] (Lower the number, more weight to init image)" 
  echo "       [--width WIDTH]"
  echo "       [--height HEIGHT]" 
  echo "       [--save-to-disk-path PATH]"
  echo "       [--session_id ID]"
  echo "       [--port PORT] (Easy Diffusion server port, default: 9000)"
  echo "       [--timeout SECONDS] (max time to wait for generation, default: 120)"
  echo "       [--debug] (enable debug output)"
  exit 1
}

# Default values for optional parameters
MODEL="sd-v1-5.safetensors"
SEED=$(od -An -N4 -t u4 /dev/urandom)
NEGATIVE_PROMPT=""
NUM_INFERENCE_STEPS=46
GUIDANCE_SCALE=7.5
PROMPT_STRENGTH=0.5
WIDTH=512
HEIGHT=512
SAVE_TO_DISK_PATH="./output/"
SESSION_ID=$(date '+%Y-%m-%d')
PORT=9000
TIMEOUT=120
DEBUG=false

# Initialize optional variables
INIT_IMAGE=""
INIT_IMAGE_PATH=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --prompt) PROMPT="$2"; shift ;;
    --model) MODEL="$2"; shift ;;
    --init-image) INIT_IMAGE_PATH="$2"; shift ;;
    --seed) SEED="$2"; shift ;;
    --negative-prompt) NEGATIVE_PROMPT="$2"; shift ;;
    --num-inference-steps) NUM_INFERENCE_STEPS="$2"; shift ;;
    --guidance-scale) GUIDANCE_SCALE="$2"; shift ;;
    --prompt-strength) PROMPT_STRENGTH="$2"; shift ;;
    --width) WIDTH="$2"; shift ;;
    --height) HEIGHT="$2"; shift ;;
    --save-to-disk-path) SAVE_TO_DISK_PATH="$2"; shift ;;
    --session_id) SESSION_ID="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --timeout) TIMEOUT="$2"; shift ;;
    --debug) DEBUG=true ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

# Ensure the mandatory argument is provided
if [[ -z "$PROMPT" ]]; then
  echo "Error: --prompt is required."
  echo ""
  usage
fi

# Check if the base64 utility is available
if ! command -v base64 &> /dev/null; then
  echo "Error: 'base64' command is required but not found. Install it and try again."
  exit 1
fi

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' command is required but not found. Install it with: sudo apt-get install jq"
  exit 1
fi

# If init image is provided, check its existence and encode it
if [[ -n "$INIT_IMAGE_PATH" ]]; then
  if [[ ! -f "$INIT_IMAGE_PATH" ]]; then
    echo "Error: Init image file not found at '$INIT_IMAGE_PATH'"
    exit 1
  fi
  INIT_IMAGE=$(base64 -w 0 "$INIT_IMAGE_PATH")
fi

# Create output directory if it doesn't exist
mkdir -p "$SAVE_TO_DISK_PATH"

# Define the URL for the Easy Diffusion server
URL="http://localhost:$PORT/render"

# Generate the JSON payload dynamically
if [[ -n "$INIT_IMAGE" ]]; then
  PAYLOAD=$(cat <<EOF
{
  "prompt": "$PROMPT",
  "seed": $SEED,
  "negative_prompt": "$NEGATIVE_PROMPT",
  "num_outputs": 1,
  "num_inference_steps": $NUM_INFERENCE_STEPS,
  "guidance_scale": $GUIDANCE_SCALE,
  "prompt_strength": $PROMPT_STRENGTH,
  "width": $WIDTH,
  "height": $HEIGHT,
  "vram_usage_level": "balanced",
  "sampler_name": "euler_a",
  "use_stable_diffusion_model": "$MODEL",
  "clip_skip": false,
  "use_vae_model": "vae-ft-mse-840000-ema-pruned",
  "stream_progress_updates": true,
  "stream_image_progress": false,
  "show_only_filtered_image": true,
  "block_nsfw": false,
  "output_format": "jpeg",
  "output_quality": 95,
  "output_lossless": false,
  "metadata_output_format": "none",
  "save_to_disk_path": "$SAVE_TO_DISK_PATH",
  "original_prompt": "$PROMPT",
  "active_tags": [],
  "inactive_tags": [],
  "init_image": "data:image/png;base64,$INIT_IMAGE",
  "upscale_amount": "4",
  "use_face_correction": "GFPGANv1.4",
  "use_upscale": "RealESRGAN_x4plus",
  "session_id": "$SESSION_ID"
}
EOF
)
else
  PAYLOAD=$(cat <<EOF
{
  "prompt": "$PROMPT",
  "seed": $SEED,
  "negative_prompt": "$NEGATIVE_PROMPT",
  "num_outputs": 1,
  "num_inference_steps": $NUM_INFERENCE_STEPS,
  "guidance_scale": $GUIDANCE_SCALE,
  "prompt_strength": $PROMPT_STRENGTH,
  "width": $WIDTH,
  "height": $HEIGHT,
  "vram_usage_level": "balanced",
  "sampler_name": "euler_a",
  "use_stable_diffusion_model": "$MODEL",
  "clip_skip": false,
  "use_vae_model": "vae-ft-mse-840000-ema-pruned",
  "stream_progress_updates": true,
  "stream_image_progress": false,
  "show_only_filtered_image": true,
  "block_nsfw": false,
  "output_format": "jpeg",
  "output_quality": 95,
  "output_lossless": false,
  "metadata_output_format": "none",
  "save_to_disk_path": "$SAVE_TO_DISK_PATH",
  "original_prompt": "$PROMPT",
  "active_tags": [],
  "inactive_tags": [],
  "upscale_amount": "4",
  "use_face_correction": "GFPGANv1.4",
  "use_upscale": "RealESRGAN_x4plus",
  "session_id": "$SESSION_ID"
}
EOF
)
fi

# Write the payload to a temporary file
TEMP_PAYLOAD_FILE=$(mktemp)

cleanup() {
  rm -f "$TEMP_PAYLOAD_FILE"
}
trap cleanup EXIT

echo "$PAYLOAD" > "$TEMP_PAYLOAD_FILE"

if [[ "$DEBUG" == true ]]; then
  echo "DEBUG: Sending request to $URL"
  echo "DEBUG: Payload: $(cat $TEMP_PAYLOAD_FILE | jq -c .)"
fi

# Send the payload via a POST request and capture response
RESPONSE=$(curl -s -X POST "$URL" \
  -H "Content-Type: application/json" \
  --data-binary "@$TEMP_PAYLOAD_FILE")

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to send the request to Easy Diffusion server."
  exit 1
fi

if [[ "$DEBUG" == true ]]; then
  echo "DEBUG: Initial response: $RESPONSE"
fi

# Parse the response to get stream URL and task ID
STREAM_URL=$(echo "$RESPONSE" | jq -r '.stream // empty')
TASK_ID=$(echo "$RESPONSE" | jq -r '.task // empty')

if [[ -z "$STREAM_URL" ]] || [[ -z "$TASK_ID" ]]; then
  echo "Error: Invalid response from Easy Diffusion server: $RESPONSE"
  exit 1
fi

if [[ "$DEBUG" == true ]]; then
  echo "DEBUG: Stream URL: $STREAM_URL"
  echo "DEBUG: Task ID: $TASK_ID"
fi

# Poll the stream endpoint to get the result
STREAM_ENDPOINT="http://localhost:$PORT$STREAM_URL"
START_TIME=$(date +%s)
RESULT=""

echo "Waiting for image generation to complete..."

while [[ -z "$RESULT" ]] && [[ $(($(date +%s) - START_TIME)) -lt $TIMEOUT ]]; do
  sleep 2
  
  # Get the stream response
  STREAM_RESPONSE=$(curl -s "$STREAM_ENDPOINT" 2>/dev/null)
  
  if [[ $? -eq 0 ]] && [[ -n "$STREAM_RESPONSE" ]]; then
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: Stream response: $STREAM_RESPONSE"
    fi
    
    # Check if the response contains base64 image data directly
    if echo "$STREAM_RESPONSE" | grep -q "data:image"; then
      RESULT="$STREAM_RESPONSE"
      break
    fi
    
    # Check if there's an error or completion status
    if echo "$STREAM_RESPONSE" | jq -e '.status == "succeeded"' >/dev/null 2>&1; then
      RESULT="$STREAM_RESPONSE"
      break
    fi
    
    if echo "$STREAM_RESPONSE" | jq -e '.status == "failed"' >/dev/null 2>&1; then
      echo "Error: Image generation failed"
      echo "$STREAM_RESPONSE" | jq -r '.error // "Unknown error"'
      exit 1
    fi
    
    # Check for output field with images
    if echo "$STREAM_RESPONSE" | jq -e '.output' >/dev/null 2>&1; then
      RESULT="$STREAM_RESPONSE"
      break
    fi
    
    # Show progress if available
    if echo "$STREAM_RESPONSE" | jq -e '.step' >/dev/null 2>&1; then
      STEP=$(echo "$STREAM_RESPONSE" | jq -r '.step // 0')
      TOTAL_STEPS=$(echo "$STREAM_RESPONSE" | jq -r '.total_steps // 46')
      echo "Progress: $STEP/$TOTAL_STEPS steps"
    fi
  else
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: No response or error from stream endpoint"
    fi
  fi
done

if [[ -z "$RESULT" ]]; then
  echo "Error: Timeout waiting for image generation (${TIMEOUT}s)"
  exit 1
fi

if [[ "$DEBUG" == true ]]; then
  echo "DEBUG: Final result received"
fi

# Extract and save the generated image
if echo "$RESULT" | grep -q "data:image"; then
  # Extract base64 image data from the output array
  IMAGE_DATA_FULL=$(echo "$RESULT" | jq -r '.output[0].data // empty')
  
  if [[ -n "$IMAGE_DATA_FULL" ]]; then
    # Remove data:image/jpeg;base64, prefix
    IMAGE_DATA=$(echo "$IMAGE_DATA_FULL" | sed 's/^data:image\/[^;]*;base64,//')
    
    # Generate output filename
    OUTPUT_FILE="${SAVE_TO_DISK_PATH}/${SESSION_ID}_${SEED}.jpeg"
    
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: Saving image to: $OUTPUT_FILE"
      echo "DEBUG: Base64 data length: ${#IMAGE_DATA}"
    fi
    
    # Create a temporary file for the base64 data to handle large content
    TEMP_B64_FILE=$(mktemp)
    echo "$IMAGE_DATA" > "$TEMP_B64_FILE"
    
    # Decode and save the image
    if base64 -d "$TEMP_B64_FILE" > "$OUTPUT_FILE" 2>/dev/null; then
      rm -f "$TEMP_B64_FILE"
      if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
        echo "✓ Image saved to: $OUTPUT_FILE"
        exit 0
      else
        echo "Error: Image file is empty"
        exit 1
      fi
    else
      rm -f "$TEMP_B64_FILE"
      echo "Error: Failed to decode base64 image data"
      exit 1
    fi
  else
    echo "Error: No image data found in response"
    if [[ "$DEBUG" == true ]]; then
      echo "DEBUG: Response: $RESULT"
    fi
    exit 1
  fi
else
  echo "Error: No image data in final response"
  if [[ "$DEBUG" == true ]]; then
    echo "DEBUG: Response: $RESULT"
  fi
  exit 1
fi
