# Automate Motion Detection in MJPEG Streams: A Complete Guide for Security Camera Analysis

Ever found yourself with gigabytes of security camera footage and wondered if anything actually happened? If you're working with MJPEG stream files from IP cameras or surveillance systems, manually reviewing hours of footage is tedious and time-consuming. In this guide, I'll show you how to automate motion detection using a powerful bash script that extracts only the moments that matter.

## The Problem with MJPEG Streams

MJPEG (Motion JPEG) streams are commonly used by security cameras and IP cameras. Unlike traditional video formats, MJPEG stores each frame as a separate JPEG image within a single file. While this format is simple and widely supported, it creates unique challenges:

- **Massive file sizes**: An hour of footage can easily exceed 1GB
- **Difficult to analyze**: Standard video tools may not recognize the format
- **Time-consuming review**: Scrubbing through hours of mostly static footage is impractical

The solution? Automated motion detection that extracts only the sequences where something actually happens.

## How the Motion Detection Script Works

The script I've developed performs three key operations:

1. **Frame Extraction**: Converts MJPEG streams into individual JPEG frames at your specified frame rate
2. **Motion Analysis**: Compares consecutive frames to detect pixel changes using FFmpeg's sophisticated difference algorithms
3. **Sequence Generation**: Bundles detected motion into separate video files and GIFs for easy review

## Prerequisites

Before getting started, ensure you have FFmpeg installed on your Ubuntu system:

```bash
sudo apt update
sudo apt install ffmpeg
```

That's it! The script is pure bash with FFmpeg doing the heavy lifting.

## Using the Script

### Basic Usage

The simplest way to run the script is by navigating to your directory containing MJPEG files (named in `HHMM-HHMM.jpeg` format like `1045-1100.jpeg`) and running:

```bash
./mjpeg_motion_detector.sh
```

This uses default settings:
- Motion threshold: 5% pixel change
- Minimum sequence length: 5 frames
- Extraction rate: 1 frame per second

### Custom Parameters

The script accepts five parameters for fine-tuned control:

```bash
./mjpeg_motion_detector.sh [input_dir] [output_dir] [threshold] [min_frames] [fps]
```

**Example 1**: Process files in the current directory with a higher motion threshold:

```bash
./mjpeg_motion_detector.sh . motion_results 10 3 1
```

This sets:
- Input: Current directory (`.`)
- Output: `motion_results` folder
- Threshold: 10% (less sensitive, catches bigger movements)
- Minimum sequence: 3 frames
- Extraction: 1 FPS

**Example 2**: High-sensitivity detection for subtle movements:

```bash
./mjpeg_motion_detector.sh /path/to/streams output 3 5 2
```

This configuration:
- Extracts 2 frames per second (more granular)
- Detects movements affecting just 3% of pixels
- Requires 5 consecutive frames to qualify as a sequence

## Understanding the Output

After processing, you'll find several items in your output directory:

### Directory Structure
```
motion_sequences/
├── extracted_frames/          # All individual frames
│   ├── frame_1004-1014_000001.jpg
│   ├── frame_1004-1014_000002.jpg
│   └── ...
├── sequence_1/                # Frames with motion detected
│   ├── frame_1004-1014_000023.jpg
│   └── ...
├── sequence_1.mp4             # Video compilation
├── sequence_1.gif             # Animated preview
└── sequence_2.mp4
```

### Video Files
Each detected motion sequence is compiled into an MP4 file playing at 2 FPS, making it easy to review what triggered the detection.

### GIF Previews
Preview GIFs (480px width) let you quickly scan through sequences without opening video files.

## Tuning Motion Detection

Getting optimal results depends on your specific use case:

### For Busy Streets
- **Threshold**: 10-20%
- **Min frames**: 5-10
- **FPS**: 1

This filters out minor movements like swaying trees and focuses on people or vehicles.

### For Indoor Monitoring
- **Threshold**: 3-8%
- **Min frames**: 3-5
- **FPS**: 2

More sensitive settings catch smaller movements in controlled environments.

### For Wildlife Cameras
- **Threshold**: 5-15%
- **Min frames**: 3-7
- **FPS**: 0.5

Lower extraction rate saves processing time while still capturing animal activity.

## Performance Considerations

Processing large MJPEG streams is resource-intensive. Here's what to expect:

- **1GB file**: Approximately 5-10 minutes on a modern CPU
- **Disk space**: Extracted frames require 2-3x the original file size temporarily
- **Memory**: Minimal impact, FFmpeg handles streaming efficiently

The script automatically cleans up temporary files after processing.

## Advanced Tips

### Batch Processing Multiple Days
Create a simple loop to process multiple directories:

```bash
for dir in /media/recordings/2024-*/; do
    ./mjpeg_motion_detector.sh "$dir" "${dir}/motion_detected" 8 5 1
done
```

### Skip Frame Extraction (Reprocessing)
If you've already extracted frames and want to adjust detection parameters, modify the script to skip Step 1 and reuse existing frames.

### Custom FFmpeg Filters
For specialized scenarios (night vision, specific areas of interest), you can modify the FFmpeg filter chain around line 98 to add:
- Brightness normalization
- Region-of-interest masking
- Noise reduction

## Troubleshooting

**"Not a JPEG file" error**: Your files are MJPEG streams, which is correct. The script handles this automatically.

**No motion detected**: Try lowering the threshold or check if your camera is capturing significant pixel changes.

**Out of disk space**: The script needs temporary space equal to 2-3x your input file size.

## Conclusion

Automated motion detection transforms how you work with surveillance footage. Instead of reviewing hours of static images, you get condensed clips of actual events. Whether you're monitoring a storefront, tracking wildlife, or analyzing traffic patterns, this script saves time and storage space.

The best part? It's completely free, open-source, and runs on any Linux system with FFmpeg. No cloud services, no subscription fees, just efficient local processing.

Download the script, adjust the parameters to your needs, and let automation handle the tedious work of finding what matters in your MJPEG streams.

---

## SEO Blog Post Metadata

**Title**: Automate Motion Detection in MJPEG Streams: A Complete Guide for Security Camera Analysis

**Excerpt**: Learn how to automatically detect and extract motion sequences from gigabyte-sized MJPEG security camera streams using a powerful bash script. Save hours of manual review and get straight to the footage that matters.

**Tags**: bash, motion-detection, security-cameras, mjpeg, ffmpeg, automation, surveillance, video-processing, linux, ubuntu

**Description** (500 words):

Security cameras and IP surveillance systems generate enormous amounts of data, often in MJPEG stream format where a single hour of footage can exceed one gigabyte. The challenge facing system administrators, security professionals, and homeowners alike is simple yet frustrating: how do you efficiently review all this footage to find the moments that actually matter? Manually scrubbing through hours of static images is impractical, time-consuming, and error-prone. This comprehensive guide introduces a sophisticated bash-based solution that automates motion detection in MJPEG streams, extracting only the sequences where actual movement occurs. Using FFmpeg's powerful video processing capabilities, the script performs frame-by-frame analysis to identify pixel changes that indicate motion, whether it's a person walking past your storefront, a vehicle entering your driveway, or wildlife passing through your backyard camera's field of view. The beauty of this approach lies in its flexibility and efficiency. Unlike cloud-based solutions that require uploading sensitive footage to third-party servers or expensive commercial software with ongoing subscription fees, this open-source script runs entirely on your local Linux system. You maintain complete control over your data while achieving professional-grade results. The script works through a three-stage process: first extracting individual frames from the MJPEG stream at your specified frame rate, then comparing consecutive frames to detect motion using configurable sensitivity thresholds, and finally bundling detected sequences into convenient MP4 videos and GIF previews for rapid review. What makes this tool particularly valuable is its configurability. You can adjust the motion detection threshold from 3% for subtle indoor movements to 20% for busy outdoor scenes, set minimum sequence lengths to filter out false positives, and control the frame extraction rate to balance processing time against detection granularity. Whether you're monitoring a retail space where you need to catch every customer interaction, analyzing traffic patterns on a busy street, running a wildlife camera trap, or simply keeping an eye on your home while traveling, this script adapts to your specific requirements. The guide walks you through every aspect of using the tool effectively, from basic installation and simple usage patterns to advanced parameter tuning for different scenarios. You'll learn how to optimize detection settings for various environments, understand the performance implications of processing large files, implement batch processing for multiple days of footage, and troubleshoot common issues. Real-world examples demonstrate configurations for busy streets versus quiet indoor spaces, and performance metrics help you plan disk space and processing time requirements. By the end of this guide, you'll have a complete understanding of automated motion detection for MJPEG streams and the ability to process surveillance footage efficiently, saving countless hours while ensuring you never miss important events captured by your cameras. This is surveillance analysis done right: automated, efficient, private, and completely under your control.
