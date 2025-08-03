# easy-diffusion-cli
CLI for Easy-Diffusion

## Video Workflow (NEW! - 3x Faster Performance + Temporal Smoothing 🚀)

For maximum-speed video processing with aggressive parallel optimization and frame smoothing:

```bash
# Auto-optimized mode with smoothing (recommended)
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your transformation prompt" --smoothing init

# Ultra-high-performance mode with init smoothing
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your prompt" \
  --max-concurrent 20 --batch-size 40 --delay 0.02 --fps 3 --smoothing init --smoothing-strength 0.4

# Temporal smoothing for maximum frame consistency
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your prompt" \
  --smoothing temporal --smoothing-strength 0.5

# Advanced smoothing for motion-heavy videos
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "flowing water" \
  --smoothing optical --smoothing-strength 0.3
```

**New Performance Features:**
- 🚀 **3x Faster Processing**: 20 concurrent requests vs 4 (default)
- ✨ **Temporal Smoothing**: Reduces frame-to-frame inconsistency and video noise
- 🎯 **Smart Hardware Detection**: Auto-configures for ultra/high/medium performance
- ⚡ **Minimal Delays**: 0.05s delays vs 2s (40x faster)
- 🔧 **Aggressive Concurrency**: Up to 20 simultaneous API requests
- 📦 **Large Batch Processing**: 40 frames per batch vs 8
- 🎬 **Smart Video Naming**: Uses first 3 prompt words + options + timestamp
- 🎥 **Auto Frame Rate Detection**: Matches source video FPS automatically

**Smoothing Methods:**
- `--smoothing init`: Use previous frame as init image (recommended)
- `--smoothing optical`: Optical flow-based frame blending  
- `--smoothing temporal`: Temporal filtering with neighboring frames
- `--smoothing none`: No smoothing (default)

See [VIDEO_WORKFLOW.md](VIDEO_WORKFLOW.md) for detailed documentation.

## Single Image CLI

1. Have a running copy of [Easy-Diffusion](https://easydiffusion.github.io/)

2. Use of CLI

   ```bash
   Usage: easy-diffusion-cli-enhanced.sh --prompt "Your prompt here"

   Optional arguments:
       [--model MODEL]
       [--init-image "/path/to/image"]
       [--seed SEED]
       [--negative-prompt "Negative prompt"]
       [--num-inference-steps STEPS]
       [--guidance-scale SCALE] (Higher the number, more weight to prompt)
       [--prompt-strength STRENGTH] (Lower the number, more weight to init image)
       [--width WIDTH]
       [--height HEIGHT]
       [--save-to-disk-path PATH]
       [--session_id ID]
       [--timeout SECONDS] (max time to wait for generation, default: 120)
       [--debug] (enable debug output)
    ```
3. Examples

### Syntax

```bash
for i in $(stat path/to/*jpg | awk '{print $2}' | grep jpg); \
do bash easy-diffusion-cli-enhanced.sh --prompt "My awesome prompt" \
  --prompt-strength "0.4" --session_id 1 --num-inference-steps 56 --guidance-scale 8 \
  --save-to-disk-path /home/ubuntu/Pictures/easy-diffusion/ --init-image $i --seed 2555259 \
  --width 768 --height 512;
  sleep 10;
done
```
done
```
