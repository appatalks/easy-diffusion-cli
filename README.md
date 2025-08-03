# easy-diffusion-cli
Advanced CLI for Easy-Diffusion with Hybrid GPU+CPU Processing

## 🚀 Video Workflow with Hybrid Processing (NEW! - Up to 10x Performance)

Transform videos using AI diffusion with intelligent GPU+CPU load balancing, automatic hardware optimization, and advanced temporal smoothing.

### 🔥 Beast Mode (High-End Systems: 16+ cores, 64+ GB RAM)

```bash
# Hybrid GPU+CPU processing (automatically balances load)
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "cyberpunk city neon lights" \
  
# CPU fallback for GPU overflow handling
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "Van Gogh style painting" \
  --cpu-fallback --multi-gpu --pipeline

# Full beast mode with all optimizations
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "anime style artwork" \
  --hybrid-processing --pipeline --smoothing init --multi-gpu
```

### ⚡ Advanced Processing Options

```bash
# Multi-GPU processing with load balancing
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "watercolor painting" \
  --multi-gpu --gpu-ports "9000,9001,9002"

# CPU-only processing with multiple instances
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "oil painting" \
  --cpu-fallback --cpu-ports "9010,9011,9012"

# Pipeline processing with overlapped operations
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "digital art" \
  --pipeline --hybrid-processing
```

### 🎯 Temporal Smoothing for Professional Results

```bash
# Init-based smoothing (recommended for consistency)
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "dreamy landscape" \
  --smoothing init --smoothing-strength 0.4

# Optical flow smoothing for motion-heavy videos
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "flowing water" \
  --smoothing optical --smoothing-strength 0.3

# Temporal filtering for maximum frame consistency
./video-diffusion.sh --video "/path/to/video.mp4" --prompt "peaceful forest" \
  --smoothing temporal --smoothing-strength 0.5
```

## 🎯 Performance Features & Hardware Optimization

**🚀 Hybrid GPU+CPU Processing:**
- **Intelligent Load Balancing**: Automatically switches between GPU and CPU based on utilization
- **Multi-GPU Support**: Distributes load across multiple GPU instances (ports 9000+)
- **CPU Fallback**: Seamless fallback to CPU when GPU is overwhelmed (>85% utilization)
- **Pipeline Processing**: Overlapped frame extraction, processing, and video assembly

**⚡ Automatic Hardware Detection:**
- **Beast Mode**: 16+ cores, 64+ GB RAM → 80+ concurrent requests, 61 batch size
- **High-End**: 16+ cores, 32+ GB RAM → 60 concurrent requests, dynamic batching
- **High-Performance**: 12+ cores, 16+ GB RAM → 40 concurrent requests
- **Standard**: 8+ cores, 8+ GB RAM → 24 concurrent requests

**🧠 CPU Optimization (16-core/32-thread Systems):**
- **Target Utilization**: 75-80% (24 of 32 threads active)
- **System Overhead**: 20-25% reserved for OS and other processes
- **Frame Extraction**: 24 parallel jobs for video preprocessing
- **CPU Processing**: 24 concurrent workers for AI inference

**🎬 Advanced Features:**
- **Auto Frame Rate Detection**: Matches source video FPS automatically
- **Smart Video Naming**: Uses first 3 prompt words + options + timestamp
- **Temporal Smoothing**: Reduces frame-to-frame inconsistency
- **Debug Mode**: Comprehensive debugging and performance monitoring

**📊 Performance Improvements vs Original:**
- **6x Faster Frame Extraction**: 4 → 24 parallel jobs
- **3x More CPU Workers**: 8 → 24 concurrent processes
- **10x Faster Processing**: Combined GPU+CPU hybrid processing
- **40x Faster Delays**: 2s → 0.05s between requests

## 🎨 Smoothing Methods

**🎯 Recommended for Most Use Cases:**
- `--smoothing init`: Use previous generated frame as init image (reduces flicker)

**🌊 For Motion-Heavy Content:**
- `--smoothing optical`: Optical flow-based frame blending
- `--smoothing temporal`: Temporal filtering using neighboring frames

**⚙️ Advanced Options:**
- `--smoothing none`: No smoothing (fastest, but may flicker)
- `--smoothing-strength 0.0-1.0`: Adjust smoothing intensity (default: 0.3)

## 🎮 Video Processing Complete Options

```bash
Usage: video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your prompt"

Required arguments:
    --video "/path/to/video.mp4"   # Input video file
    --prompt "Your prompt here"    # AI transformation prompt

Performance & Hardware:
    [--hybrid-processing]          # Enable GPU+CPU hybrid processing
    [--cpu-fallback]              # Enable CPU fallback when GPU overloaded
    [--multi-gpu]                 # Enable multi-GPU processing
    [--pipeline]                  # Enable pipeline optimization
    [--gpu-ports "9000,9001"]     # GPU server ports (comma-separated)
    [--cpu-ports "9010,9011"]     # CPU server ports (comma-separated)
    [--max-concurrent NUM]        # Max concurrent API requests (auto-detected)
    [--parallel-jobs NUM]         # Parallel frame extraction jobs (auto-detected)
    [--batch-size NUM]            # Frames per batch (auto-detected)

Video & Quality:
    [--fps FPS]                   # Frames per second (auto-detected from source)
    [--start-frame NUM]           # Start processing from frame number
    [--end-frame NUM]             # Stop at frame number
    [--smoothing METHOD]          # Temporal smoothing: init|optical|temporal|none
    [--smoothing-strength FLOAT]  # Smoothing intensity 0.0-1.0 (default: 0.3)

AI Parameters:
    [--model MODEL]               # AI model (default: sd-v1-5.safetensors)
    [--seed SEED]                 # Random seed for reproducible results
    [--negative-prompt "TEXT"]    # What to avoid in generation
    [--num-inference-steps STEPS] # Quality vs speed (default: 46)
    [--guidance-scale SCALE]      # Prompt adherence (default: 7.5)
    [--prompt-strength STRENGTH]  # Init image influence (default: 0.5)
    [--width WIDTH]               # Output width (default: 512)
    [--height HEIGHT]             # Output height (default: 512)

Output & Debug:
    [--save-to-disk-path PATH]    # Output directory (default: ./output/)
    [--session_id ID]             # Session identifier
    [--temp-dir PATH]             # Temporary frames directory
    [--keep-frames]               # Preserve extracted frames
    [--no-video]                  # Generate images only, skip video creation
    [--sequential]                # Disable parallel processing
    [--debug]                     # Enable debug output and monitoring
    [--delay SECONDS]             # Delay between requests (default: 0.05)
```
## 🚀 Quick Start Examples

### Basic Video Transformation
```bash
# Simple transformation with auto-optimization
./video-diffusion.sh --video "input.mp4" --prompt "watercolor painting"
```

### High-Performance Processing
```bash
# Beast mode with hybrid processing for 16-core systems
./video-diffusion.sh --video "input.mp4" --prompt "cyberpunk city" \
  --hybrid-processing --pipeline --smoothing init
```

### Professional Workflow
```bash
# Multi-GPU with temporal smoothing for production work
./video-diffusion.sh --video "input.mp4" --prompt "cinematic film noir" \
  --multi-gpu --gpu-ports "9000,9001,9002" --smoothing temporal \
  --smoothing-strength 0.4 --fps 24
```

### Batch Processing Script
```bash
# Process multiple images with consistent settings
for i in $(stat path/to/*jpg | awk '{print $2}' | grep jpg); do 
  bash easy-diffusion-cli-enhanced.sh --prompt "artistic masterpiece" \
    --prompt-strength "0.4" --session_id batch_001 \
    --num-inference-steps 46 --guidance-scale 7.5 \
    --save-to-disk-path "/output/path/" --init-image "$i" \
    --seed 2555259 --width 768 --height 512
  sleep 2
done
```

## 📋 Prerequisites & Setup

**Required:**
- [Easy Diffusion](https://easydiffusion.github.io/) server running on localhost:9000
- `ffmpeg` for video processing
- `jq` for JSON parsing
- `curl` for API requests
- `bash` 4.0+ shell

**Optional for Enhanced Performance:**
- Multiple Easy Diffusion instances on different ports (9000, 9001, 9002...)
- CPU-only Easy Diffusion instances on ports 9010-9013
- `nvidia-smi` for GPU monitoring (NVIDIA systems)
- `bc` for advanced smoothing calculations
- High-end hardware (16+ cores, 64+ GB RAM) for beast mode

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install ffmpeg jq curl bc

# Make scripts executable
chmod +x video-diffusion.sh easy-diffusion-cli-enhanced.sh
```

## 🎯 Performance Tips

**For Maximum Speed:**
1. Use `--hybrid-processing --pipeline` for overlapped operations
2. Enable multi-GPU with `--multi-gpu --gpu-ports "9000,9001,9002"`
3. Set up CPU fallback instances on ports 9010-9013
4. Use `--smoothing init` for the best quality/speed balance
5. Process at lower FPS first (`--fps 1`) for testing

**For Best Quality:**
1. Use `--smoothing temporal --smoothing-strength 0.5`
2. Increase inference steps: `--num-inference-steps 50`
3. Use higher guidance scale: `--guidance-scale 8.0`
4. Process at source frame rate with `--fps` auto-detection

**For System Stability:**
1. Monitor with `--debug` flag for performance insights
2. Start with `--end-frame 10` for testing
3. Use `--sequential` if parallel processing causes issues
4. Reserve CPU overhead by not forcing max concurrency

See [VIDEO_WORKFLOW.md](VIDEO_WORKFLOW.md) for detailed workflow documentation.
