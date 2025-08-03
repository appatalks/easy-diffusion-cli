# easy-diffusion-cli
Advanced CLI for Easy-Diffusion with Hybrid GPU+CPU Processing & Temporal Smoothing

## 🚀 Video Workflow with Hybrid Processing & Temporal Smoothing

Transform videos using AI diffusion with intelligent GPU+CPU load balancing, automatic hardware optimization, and professional-grade temporal smoothing for flicker-free results.

### 🔥 Quick Start Examples

```bash
# Basic video transformation with auto-optimization
./video-diffusion.sh --video "input.mp4" --prompt "watercolor painting"

# Hybrid GPU+CPU processing for maximum speed
./video-diffusion.sh --video "input.mp4" --prompt "cyberpunk city neon lights" \
  --hybrid-processing

# Professional quality with temporal smoothing
./video-diffusion.sh --video "input.mp4" --prompt "Van Gogh starry night style" \
  --smoothing init --smoothing-strength 0.4

# High-end system with all optimizations
./video-diffusion.sh --video "input.mp4" --prompt "anime style artwork" \
  --hybrid-processing --smoothing temporal --smoothing-strength 0.3
```

### ⚡ Hybrid Processing Modes

#### **🎯 GPU+CPU Hybrid Processing** (Recommended for High Performance)
```bash
# Automatically balance load between GPU and CPU servers
./video-diffusion.sh --video "input.mp4" --prompt "digital art masterpiece" \
  --hybrid-processing --gpu-ports "9000" --cpu-ports "9010"

# Multiple server configuration
./video-diffusion.sh --video "input.mp4" --prompt "photorealistic rendering" \
  --hybrid-processing --gpu-ports "9000,9001" --cpu-ports "9010,9011"
```

#### **🛡️ CPU Fallback Mode** (Reliable Performance)
```bash
# GPU with automatic CPU fallback when overloaded
./video-diffusion.sh --video "input.mp4" --prompt "oil painting style" \
  --cpu-fallback --gpu-ports "9000" --cpu-ports "9010"
```

### 🎯 Temporal Smoothing for Professional Results

#### **⭐ Init Smoothing** (Recommended - Best Balance)
```bash
# Use previous frame as init image for consistency
./video-diffusion.sh --video "input.mp4" --prompt "dreamy landscape" \
  --smoothing init --smoothing-strength 0.4
```

#### **🌊 Optical Flow Smoothing** (Motion-Heavy Content)
```bash
# Optical flow-based frame blending for smooth motion
./video-diffusion.sh --video "input.mp4" --prompt "flowing water scene" \
  --smoothing optical --smoothing-strength 0.3
```

#### **🎬 Temporal Filtering** (Maximum Consistency)
```bash
# Multi-frame temporal filtering for film-like quality
./video-diffusion.sh --video "input.mp4" --prompt "cinematic sequence" \
  --smoothing temporal --smoothing-strength 0.5
```

## 🎯 Performance Features & Hardware Optimization

### **🚀 Hybrid Processing Architecture**
- **GPU+CPU Load Balancing**: Automatically distributes work between GPU and CPU servers
- **Intelligent Server Selection**: Real-time load monitoring and optimal server routing
- **Automatic Failover**: Seamless CPU fallback when GPU servers are overloaded
- **Multi-Instance Support**: Configure multiple GPU and CPU server ports
- **Hardware Auto-Detection**: Optimizes settings based on available CPU cores and RAM

### **🎬 Advanced Video Processing Features**
- **Auto Frame Rate Detection**: Matches source video FPS automatically or customize
- **Smart Video Naming**: Uses first 3 prompt words + options + timestamp
- **Parallel Frame Extraction**: Multi-threaded ffmpeg processing
- **Batch Processing**: Intelligent batching for optimal throughput
- **Hardware-Accelerated Encoding**: NVENC, VAAPI, or optimized software encoding

### **🎯 Temporal Smoothing Technology**
- **Init Smoothing**: Uses previous generated frame as initialization (best balance)
- **Optical Flow**: FFmpeg-based frame blending for motion consistency
- **Temporal Filtering**: Multi-frame weighted averaging for maximum smoothness
- **Configurable Strength**: Adjustable smoothing intensity (0.0-1.0)

### **🔧 Performance Optimizations**
- **Automatic Hardware Tuning**: Detects CPU cores and RAM for optimal settings
- **Concurrent Request Management**: Semaphore-based parallel processing
- **Minimal Request Delays**: Optimized timing (0.005-0.05s) based on hardware
- **Server Health Monitoring**: Real-time availability and load checking

## 🎨 Smoothing Methods

**🎯 Recommended for Most Use Cases:**
- `--smoothing init`: Use previous generated frame as init image (reduces flicker)

**🌊 For Motion-Heavy Content:**
- `--smoothing optical`: Optical flow-based frame blending
- `--smoothing temporal`: Temporal filtering using neighboring frames

**⚙️ Advanced Options:**
- `--smoothing none`: No smoothing (fastest, but may flicker)
- `--smoothing-strength 0.0-1.0`: Adjust smoothing intensity (default: 0.3)

## 🎮 Complete Command Reference

```bash
Usage: video-diffusion.sh --video "/path/to/video.mp4" --prompt "Your prompt"

Required arguments:
    --video "/path/to/video.mp4"   # Input video file
    --prompt "Your prompt here"    # AI transformation prompt

🚀 Performance & Processing:
    [--hybrid-processing]          # Enable GPU+CPU hybrid processing
    [--cpu-fallback]              # Enable CPU fallback when GPU overloaded
    [--gpu-ports "9000,9001"]     # GPU server ports (comma-separated)
    [--cpu-ports "9010,9011"]     # CPU server ports (comma-separated)
    [--max-concurrent NUM]        # Max concurrent API requests (auto-detected)
    [--parallel-jobs NUM]         # Parallel frame extraction jobs (auto-detected)
    [--batch-size NUM]            # Frames per batch (auto-detected)
    [--sequential]                # Disable parallel processing
    [--delay SECONDS]             # Delay between requests (0.005-0.05)

🎯 Temporal Smoothing:
    [--smoothing METHOD]          # Smoothing: init|optical|temporal|none
    [--smoothing-strength FLOAT]  # Smoothing intensity 0.0-1.0 (default: 0.3)

🎬 Video & Frame Control:
    [--fps FPS]                   # Frames per second (auto-detected from source)
    [--start-frame NUM]           # Start processing from frame number
    [--end-frame NUM]             # Stop at frame number
    [--keep-frames]               # Preserve extracted frames
    [--no-video]                  # Generate images only, skip video creation

🎨 AI Generation Parameters:
    [--model MODEL]               # AI model (default: sd-v1-5.safetensors)
    [--seed SEED]                 # Random seed for reproducible results
    [--negative-prompt "TEXT"]    # What to avoid in generation
    [--num-inference-steps STEPS] # Quality vs speed (default: 46)
    [--guidance-scale SCALE]      # Prompt adherence (default: 7.5)
    [--prompt-strength STRENGTH]  # Init image influence (default: 0.5)
    [--width WIDTH]               # Output width (default: 512)
    [--height HEIGHT]             # Output height (default: 512)

📁 Output & Debug:
    [--save-to-disk-path PATH]    # Output directory (default: ./output/)
    [--session_id ID]             # Session identifier
    [--temp-dir PATH]             # Temporary frames directory
    [--debug]                     # Enable comprehensive debug output
```

### 🎯 Smoothing Methods Explained

| Method | Description | Best For | Performance |
|--------|-------------|----------|-------------|
| **init** | Uses previous generated frame as init image | General use, best balance | ⭐⭐⭐⭐⭐ |
| **optical** | Optical flow-based frame blending | Motion-heavy content | ⭐⭐⭐⭐ |
| **temporal** | Multi-frame temporal filtering | Maximum consistency | ⭐⭐⭐ |
| **none** | No smoothing (fastest) | Testing, speed priority | ⭐⭐⭐⭐⭐ |
## 🚀 Quick Start Examples

### **Basic Usage**
```bash
# Simple transformation with auto-optimization
./video-diffusion.sh --video "input.mp4" --prompt "watercolor painting"

# Test with limited frames (recommended for first run)
./video-diffusion.sh --video "input.mp4" --prompt "Van Gogh style" --end-frame 10
```

### **Hybrid Processing (Recommended)**
```bash
# GPU+CPU hybrid for maximum performance
./video-diffusion.sh --video "input.mp4" --prompt "cyberpunk city" \
  --hybrid-processing

# With temporal smoothing for professional quality
./video-diffusion.sh --video "input.mp4" --prompt "anime artwork" \
  --hybrid-processing --smoothing init --smoothing-strength 0.4
```

### **High-Quality Production**
```bash
# Maximum quality with temporal filtering
./video-diffusion.sh --video "input.mp4" --prompt "cinematic masterpiece" \
  --smoothing temporal --smoothing-strength 0.5 --num-inference-steps 50

# Professional workflow with custom settings
./video-diffusion.sh --video "input.mp4" --prompt "oil painting portrait" \
  --hybrid-processing --smoothing init --fps 24 --guidance-scale 8.0
```

### **Performance Optimization**
```bash
# Speed priority (testing/previews)
./video-diffusion.sh --video "input.mp4" --prompt "sketch style" \
  --fps 1 --num-inference-steps 25 --end-frame 20

# Multi-server configuration for maximum throughput
./video-diffusion.sh --video "input.mp4" --prompt "digital art" \
  --hybrid-processing --gpu-ports "9000,9001" --cpu-ports "9010,9011"
```


## 📋 Prerequisites & Setup

### **Required Dependencies**
- [Easy Diffusion](https://easydiffusion.github.io/) server running on localhost:9000
- `ffmpeg` for video processing and encoding
- `jq` for JSON parsing and API responses
- `curl` for HTTP requests to Easy Diffusion API
- `bash` 4.0+ shell

### **Optional for Enhanced Performance**
- **CPU Server**: Easy Diffusion instance on port 9010 for hybrid processing
- **Multiple GPUs**: Additional GPU servers on ports 9001, 9002, etc.
- **System Tools**: `bc` for smoothing calculations, `nvidia-smi` for GPU monitoring
- **High-end Hardware**: 16+ cores, 32+ GB RAM for maximum concurrent processing

### **Installation**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ffmpeg jq curl bc

# Make scripts executable
chmod +x video-diffusion.sh easy-diffusion-cli-enhanced.sh

# Verify Easy Diffusion server is running
curl http://localhost:9000/ping
```

### **Server Setup for Hybrid Processing**
```bash
# GPU server (default): localhost:9000
# CPU server (recommended): localhost:9010
# Additional servers: localhost:9001, 9011, etc.

# Test server connectivity
./video-diffusion.sh --video "test.mp4" --prompt "test" --end-frame 1 --debug
```

## 🎯 Performance Tips & Best Practices

### **🚀 For Maximum Speed**
1. **Use hybrid processing**: `--hybrid-processing` with GPU+CPU servers
2. **Start with low FPS**: `--fps 1` for testing, then increase
3. **Limit frames for testing**: `--end-frame 20` before full processing
4. **Enable debug mode**: `--debug` to monitor performance bottlenecks
5. **Use init smoothing**: `--smoothing init` for best speed/quality balance

### **🎬 For Best Quality**
1. **Use temporal smoothing**: `--smoothing temporal --smoothing-strength 0.4`
2. **Increase inference steps**: `--num-inference-steps 50-75`
3. **Higher guidance scale**: `--guidance-scale 8.0` for better prompt adherence
4. **Match source frame rate**: Let auto-detection set FPS or use `--fps 24/30`
5. **Process at full resolution**: Use source video resolution or higher

### **🛡️ For System Stability**
1. **Monitor with debug**: `--debug` flag shows real-time processing status
2. **Start small**: Use `--end-frame 10` for initial tests
3. **Check server health**: Verify all servers respond before large jobs
4. **Use CPU fallback**: `--cpu-fallback` for automatic error recovery
5. **Reserve CPU overhead**: Don't max out concurrent requests on lower-end systems

### **⚡ Hardware-Specific Recommendations**

| System Type | Recommended Settings | Example Command |
|-------------|---------------------|-----------------|
| **Entry Level** (4-8 cores) | Single GPU, conservative settings | `--max-concurrent 4 --batch-size 8` |
| **Mid Range** (8-16 cores) | GPU + CPU fallback | `--cpu-fallback --max-concurrent 8` |
| **High End** (16+ cores) | Full hybrid processing | `--hybrid-processing --max-concurrent 20` |
| **Workstation** (32+ cores) | Multi-server setup | `--hybrid-processing --gpu-ports "9000,9001" --cpu-ports "9010,9011"` |

See [VIDEO_WORKFLOW.md](VIDEO_WORKFLOW.md) for detailed workflow documentation.

---

## 🔄 Recent Updates

**v2.0 - Hybrid Processing & Temporal Smoothing**
- ✨ Added GPU+CPU hybrid processing with intelligent load balancing
- 🎯 Implemented temporal smoothing (init, optical, temporal methods)
- 🚀 Enhanced server management with automatic failover
- ⚡ Optimized performance with hardware auto-detection
- 📊 Added comprehensive debugging and monitoring
- 🎬 Improved video encoding with hardware acceleration

**Features Added:**
- `--hybrid-processing` and `--cpu-fallback` modes
- `--smoothing` with configurable strength
- Real-time server health monitoring
- Multi-server port configuration
- Enhanced error handling and recovery
- Professional-grade temporal consistency

For legacy documentation, see previous commits or the `main` branch.
