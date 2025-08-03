# Copilot Instructions for Easy Diffusion CLI

## Project Overview
This is an automated video diffusion pipeline that transforms videos through AI image generation using Easy Diffusion. The pipeline extracts frames from video, processes each frame through AI diffusion, and reassembles them into a final video.

## Core Architecture

### Main Components
1. **`video-diffusion.sh`** - Main automated pipeline script
2. **`easy-diffusion-cli-enhanced.sh`** - CLI for Easy Diffusion API with async handling
3. **Easy Diffusion Server** - External AI service running on localhost:9000

### Key Features
- **Dynamic frame rate detection** - Auto-detects source video FPS and matches output
- **Hardware auto-detection** - Automatically optimizes parallel processing based on CPU cores
- **Parallel processing** - Processes multiple frames concurrently (default: 20 jobs)
- **Smart video naming** - Uses first 3 prompt words + timestamp
- **Automatic cleanup** - Removes temporary frames after video creation
- **Error handling** - Robust error recovery and debugging options

## Technology Stack
- **Bash scripting** - Core pipeline logic
- **ffmpeg** - Video processing and frame extraction
- **Easy Diffusion API** - AI image generation (localhost:9000/render)
- **jq** - JSON parsing for API responses
- **curl** - HTTP requests to API
- **Parallel processing** - Semaphore-based concurrency control

## File Structure
```
easy-diffusion-cli/
├── video-diffusion.sh          # Main pipeline script
├── easy-diffusion-cli-enhanced.sh  # Enhanced CLI with async handling
├── VIDEO_WORKFLOW.md           # Complete usage documentation
├── README.md                   # Project overview and setup
├── LICENSE                     # MIT license
├── .gitignore                  # Excludes output/ and temp files
└── examples/                   # Sample input videos
    └── raw/
        └── starsintro.mp4     # Test video file
```

## API Integration Details

### Easy Diffusion API Flow
1. **POST** to `localhost:9000/render` with JSON payload
2. **Response** contains `stream` URL and `task` ID
3. **Poll** stream endpoint until completion
4. **Extract** base64 image data from response
5. **Decode** and save image file

### Key API Parameters
- **Model**: `sd-v1-5.safetensors` (default)
- **Inference Steps**: 46 (balanced quality/speed)
- **Guidance Scale**: 7.5 (prompt adherence)
- **Resolution**: 512x512 (default, adjustable)
- **Output Format**: JPEG with 95% quality

## Performance Optimization

### Hardware Auto-Detection
```bash
CPU_CORES=$(nproc)
PARALLEL_JOBS=$((CPU_CORES * 2 / 3))  # 2/3 of available cores
MAX_CONCURRENT=20  # API request limit
BATCH_SIZE=40      # Frames per batch
```

### Concurrency Control
- **Semaphore-based** - Limits concurrent API requests
- **Batch processing** - Groups frames for efficient processing
- **Minimal delays** - 0.01s between requests (vs original 2s)

### Video Processing
- **Dynamic FPS detection** - Uses ffprobe to detect source frame rate
- **Parallel frame extraction** - Uses ffmpeg with multiple jobs
- **Automatic video creation** - Reassembles frames with original timing

## Error Handling Patterns

### Common Issues
1. **Easy Diffusion server not running** - Check localhost:9000
2. **API timeout** - Increase timeout or reduce concurrent requests
3. **Frame extraction failures** - Check video file format and permissions
4. **Memory issues** - Reduce parallel jobs or batch size

### Debugging
- Use `--debug` flag for verbose output
- Check API responses with `--debug` on CLI
- Monitor system resources during processing
- Verify temp directory permissions

## Development Guidelines

### Code Style
- Use descriptive variable names
- Include error checking for all external commands
- Provide helpful error messages with debugging context
- Use functions for reusable logic
- Comment complex operations

### Testing Approach
- Test with short videos (5-10 seconds) during development
- Use `--start-frame` and `--end-frame` for partial testing
- Verify with different prompt types and lengths
- Test edge cases (empty prompts, special characters)

### Performance Considerations
- Monitor API response times
- Watch for memory usage spikes
- Consider disk space for temp frames
- Test with different hardware configurations

## Video Naming Convention
Output videos use this pattern:
`{first_3_prompt_words}_{YYYY-MM-DD_HHMM}.mp4`

Examples:
- Prompt: "Van Gogh Starry Night" → `van_gogh_starry_2025-08-02_2046.mp4`
- Prompt: "cyberpunk city" → `cyberpunk_city_2025-08-02_2046.mp4`

## Configuration Options

### Environment Variables
- `EASY_DIFFUSION_CLI` - Path to enhanced CLI script
- Custom server URL (if not localhost:9000)

### Command Line Flags
- `--fps` - Override auto-detected frame rate
- `--no-video` - Generate images only, skip video creation
- `--keep-frames` - Preserve temporary frames
- `--sequential` - Disable parallel processing
- `--debug` - Enable verbose debugging output

## Troubleshooting Guide

### Setup Issues
1. Ensure Easy Diffusion server is running on localhost:9000
2. Verify required tools: ffmpeg, jq, curl, base64
3. Check file permissions on scripts (executable)
4. Ensure sufficient disk space for temp files

### Processing Issues
1. Start with small test videos
2. Use `--debug` flag to see detailed progress
3. Check server logs for API errors
4. Monitor system resources (CPU, memory, disk)

### Quality Issues
1. Adjust `--num-inference-steps` for quality/speed balance
2. Modify `--guidance-scale` for prompt adherence
3. Use appropriate resolution for your content
4. Consider model selection for different art styles

## Future Enhancement Areas
- Support for different AI models
- Batch processing multiple videos
- Advanced video effects and transitions
- Integration with other AI services
- GUI interface for non-technical users
- Cloud deployment options

## Dependencies
- **bash** (4.0+)
- **ffmpeg** (recent version with parallel support)
- **jq** (JSON parser)
- **curl** (HTTP client)
- **base64** (encoding/decoding)
- **Easy Diffusion** (running on localhost:9000)

## Security Considerations
- Validate all user inputs
- Sanitize file paths and names
- Limit temp directory access
- Clean up temporary files
- Avoid logging sensitive data
