# Video Diffusion Workflow (Optimized for Modern Hardware)

This document explains how to use the streamlined, high-performance video diffusion workflow that takes full advantage of modern multi-core CPUs and powerful GPUs.

## 🚀 Performance Optimizations

The optimized `video-diffusion.sh` script includes:

- **Parallel Frame Extraction**: Uses all CPU cores for faster ffmpeg processing
- **Concurrent API Requests**: Processes multiple frames simultaneously (default: 4 concurrent)
- **Batch Processing**: Groups frames for optimal memory usage
- **Hardware Auto-Detection**: Automatically adjusts settings based on your CPU cores
- **Reduced Delays**: Minimal 0.1s delays between requests (vs 2s in legacy mode)
- **Smart Concurrency Control**: Prevents server overload with semaphore-based limiting
- **Hardware-Accelerated Video Encoding**: Uses GPU encoding when available (NVENC, VAAPI)

## Quick Start

### High-Performance Mode (Default)
```bash
./video-diffusion.sh --video "/path/to/your/video.mp4" --prompt "Your transformation prompt"
```

### Maximum Performance (Powerful Hardware)
```bash
./video-diffusion.sh \
  --video "/path/to/video.mp4" \
  --prompt "A beautiful painting in the style of Van Gogh" \
  --max-concurrent 8 \
  --batch-size 16 \
  --parallel-jobs 8 \
  --fps 2
```

### Conservative Mode (Slower Hardware or Server Limitations)
```bash
./video-diffusion.sh \
  --video "/path/to/video.mp4" \
  --prompt "Your prompt" \
  --sequential \
  --delay 2
```

## Prerequisites

1. Have a running copy of [Easy-Diffusion](https://easydiffusion.github.io/)
2. Install ffmpeg:
   ```bash
   sudo apt-get install ffmpeg
   ```

## Parameters

### Required
- `--video`: Path to input video file
- `--prompt`: Text prompt for image transformation

### Performance Parameters (NEW!)
- `--max-concurrent`: Max simultaneous API requests (default: 4, try 6-8 for powerful hardware)
- `--parallel-jobs`: CPU cores for frame extraction (auto-detected, max 16)
- `--batch-size`: Frames per processing batch (default: 8, try 16-32 for more RAM)
- `--sequential`: Force single-threaded processing for compatibility
- `--delay`: Delay between requests (default: 0.1s, increase if server struggles)

### Optional
- `--fps`: Frames per second to extract (default: 1)
- `--model`: AI model to use (default: sd-v1-4)
- `--seed`: Seed for reproducible results (random if not specified)
- `--negative-prompt`: What to avoid in generation
- `--num-inference-steps`: Number of diffusion steps (default: 46)
- `--guidance-scale`: How closely to follow prompt (default: 7.5)
- `--prompt-strength`: Balance between original image and prompt (default: 0.5)
- `--width/--height`: Output dimensions (default: 512x512)
- `--save-to-disk-path`: Output directory (default: /home/easy-diffusion-out/)
- `--session_id`: Session identifier (default: current date)
- `--temp-dir`: Temporary directory for extracted frames (default: ./temp_frames)
- `--keep-frames`: Keep extracted frames after processing
- `--start-frame/--end-frame`: Process specific frame range

## Workflow

1. **Frame Extraction**: The script extracts frames from your video using ffmpeg
2. **Frame Processing**: Each frame is processed through Easy Diffusion using the original frame as an init image
3. **Output Generation**: Transformed images are saved to the specified directory
4. **Optional Video Creation**: The script can recreate a video from the generated images

## Examples

### 🚀 High-Performance Examples

#### Transform a video into Van Gogh style (Fast)
```bash
./video-diffusion.sh \
  --video "examples/raw/starsintro.mp4" \
  --prompt "A painting in the style of Van Gogh, swirling brushstrokes, vibrant colors" \
  --prompt-strength 0.6 \
  --fps 2 \
  --max-concurrent 6 \
  --batch-size 12
```

#### Create an anime version (Maximum Speed)
```bash
./video-diffusion.sh \
  --video "input.mp4" \
  --prompt "anime style, studio ghibli, beautiful animation" \
  --prompt-strength 0.5 \
  --guidance-scale 9 \
  --max-concurrent 8 \
  --parallel-jobs 8 \
  --fps 3
```

#### Process high-resolution video efficiently
```bash
./video-diffusion.sh \
  --video "4k_input.mp4" \
  --prompt "cyberpunk city, neon lights, futuristic" \
  --width 768 \
  --height 768 \
  --max-concurrent 4 \
  --batch-size 6 \
  --fps 1
```

### 🐌 Conservative Examples

#### For older hardware or unstable servers
```bash
./video-diffusion.sh \
  --video "input.mp4" \
  --prompt "watercolor painting style" \
  --sequential \
  --delay 3 \
  --fps 0.5
```

## 🔧 Performance Tuning Guide

### Hardware-Specific Recommendations

#### High-End Workstation (16+ cores, 32GB+ RAM, RTX 4090/A100)
```bash
--max-concurrent 8 --batch-size 16 --parallel-jobs 16 --fps 3 --delay 0.05
```

#### Gaming PC (8-12 cores, 16-32GB RAM, RTX 4070+)
```bash
--max-concurrent 6 --batch-size 12 --parallel-jobs 8 --fps 2 --delay 0.1
```

#### Mid-Range System (4-8 cores, 8-16GB RAM, GTX 1080+)
```bash
--max-concurrent 4 --batch-size 8 --parallel-jobs 4 --fps 1 --delay 0.2
```

#### Budget/Older System (2-4 cores, 4-8GB RAM)
```bash
--sequential --delay 3 --fps 0.5
```

### Easy Diffusion Server Tuning

If your Easy Diffusion server is on the same machine:
- Increase `--max-concurrent` to 6-8
- Reduce `--delay` to 0.05-0.1
- Monitor GPU memory usage

If your Easy Diffusion server is remote:
- Keep `--max-concurrent` at 2-4
- Increase `--delay` to 0.5-1.0
- Consider network latency

## Tips

1. **Max Concurrent**: Start with 4, increase if your GPU/server can handle it
2. **Batch Size**: Larger batches use more RAM but are more efficient
3. **Parallel Jobs**: Should match your CPU cores (auto-detected)
4. **FPS**: Higher FPS = more frames = longer processing but smoother final video
5. **Delay**: Reduce to speed up, increase if getting server errors
6. **Test First**: Use `--start-frame 1 --end-frame 10` to test settings
7. **Monitor Resources**: Watch GPU memory, CPU usage, and server response times

## Legacy Manual Process

If you prefer the manual process, you can still use the individual scripts:

1. Extract frames using the instructions in `create_frames.md`
2. Process frames individually with `easy-diffusion-cli.sh`
3. Combine results back into a video

## Troubleshooting

- **ffmpeg not found**: Install with `sudo apt-get install ffmpeg`
- **Easy Diffusion connection failed**: Ensure Easy Diffusion is running on localhost:9000
- **Out of memory**: Reduce `--fps` or add longer `--delay` between frames
- **Poor results**: Adjust `--prompt-strength` and `--guidance-scale` parameters
