 **Install ffmpeg** (if you haven't already):
   ```bash
   sudo apt-get install ffmpeg
   ```

2. **Extract frames from the video**:
   Use the following command, replacing `input_video.mp4` with the name of your video file:
   ```bash
   ffmpeg -i input_video.mp4 -vf "fps=1" frame_%04d.jpg
   ```

   - `-i input_video.mp4`: Specifies the input video file.
   - `-vf "fps=1"`: Sets the frame rate for extraction (1 frame per second in this case). You can adjust this value if you want more or fewer frames.
   - `frame_%04d.jpg`: The output filename format where `%04d` will be replaced by the frame number (e.g., frame_0001.jpg, frame_0002.jpg, etc.).

This command will create JPEG files for each frame of the video in the current directory. Adjust the `fps` value as needed to extract more or fewer frames.

----


You can use `ffmpeg` to combine a series of images back into a video file. Here's how to do it:

1. **Make sure your images are named in a sequential order** (e.g., `frame_0001.jpg`, `frame_0002.jpg`, etc.).

2. **Use the following `ffmpeg` command** to create a video from the images:

```bash
ls -1U frame_*.jpg | awk '{print "file \x27" $0 "\x27"}' > filelist.txt
ffmpeg -f concat -safe 0 -i filelist.txt -c:v libx264 -pix_fmt yuv420p output_video.mp4
```

   - `-c:v libx264`: Uses the H.264 codec for video encoding.
   - `-pix_fmt yuv420p`: Sets the pixel format for better compatibility with players.
   - `output_video.mp4`: The name of the output video file.

Run this command in your terminal, and it will create a video file from the specified images. Adjust the frame rate as required for your video.
