#!/bin/bash

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
  exit 1
}

# Default values for optional parameters
MODEL="sd-v1-4"
SEED=$(od -An -N4 -t u4 /dev/urandom)
NEGATIVE_PROMPT=""
NUM_INFERENCE_STEPS=46
GUIDANCE_SCALE=7.5
PROMPT_STRENGTH=0.5
WIDTH=512
HEIGHT=512
SAVE_TO_DISK_PATH="/home/easy-diffusion-out/"
SESSION_ID=$(date '+%Y-%m-%d')

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

# If init image is provided, check its existence and encode it
if [[ -n "$INIT_IMAGE_PATH" ]]; then
  if [[ ! -f "$INIT_IMAGE_PATH" ]]; then
    echo "Error: Init image file not found at '$INIT_IMAGE_PATH'"
    exit 1
  fi
  INIT_IMAGE=$(base64 -w 0 "$INIT_IMAGE_PATH")
fi

# Define the URL for the Easy Diffusion server
URL="http://localhost:9000/render"

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

# Send the payload via a POST request
curl -X POST "$URL" \
  -H "Content-Type: application/json" \
  --data-binary "@$TEMP_PAYLOAD_FILE" || {
    echo "Error: Failed to send the request to Easy Diffusion server."
    exit 1
}
