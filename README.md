# easy-diffusion-cli
CLI for Easy-Diffusion

## Video Workflow (NEW! - 3x Faster Performance 🚀)

For maximum-speed video processing with aggressive parallel optimization:

```bash
# Auto-optimized mode (detects your hardware and maximizes performance)
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your transformation prompt"

# Ultra-high-performance mode (powerful hardware)
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your prompt" \
  --max-concurrent 20 --batch-size 40 --delay 0.02 --fps 3

# Find optimal settings for your hardware
./performance-tuner.sh
```

**New Performance Features:**
- 🚀 **3x Faster Processing**: 20 concurrent requests vs 4 (default)
- 🎯 **Smart Hardware Detection**: Auto-configures for ultra/high/medium performance
- ⚡ **Minimal Delays**: 0.05s delays vs 2s (40x faster)
- 🔧 **Aggressive Concurrency**: Up to 20 simultaneous API requests
- 📦 **Large Batch Processing**: 40 frames per batch vs 8
- 🎬 **Local Output Directory**: Uses `./output/` instead of system paths
- 🔧 **Performance Tuner**: New tool to find optimal settings for your hardware

See [VIDEO_WORKFLOW.md](VIDEO_WORKFLOW.md) for detailed documentation.

## Single Image CLI

1. Have a running copy of [Easy-Diffusion](https://easydiffusion.github.io/)

2. Use of CLI

   ```bash
   Usage: easy-diffusion-cli.sh --prompt "Your prompt here"

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
    ```
3. Examples

### Syntax

```bash
for i in $(stat path/to/*jpg | awk '{print $2}' | grep jpg); \
do bash easy-diffusion-cli.sh --prompt "My awesome prompt" \
  --prompt-strength "0.4" --session_id 1 --num-inference-steps 56 --guidance-scale 8 \
  --save-to-disk-path /home/ubuntu/Pictures/easy-diffusion/ --init-image $i --seed 2555259 \
  --width 768 --height 512;
  sleep 10;
done
```
