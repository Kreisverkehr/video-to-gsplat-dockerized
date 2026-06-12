# Video to GSplat - Dockerized

This repository is a Docker containerization of [Nannigalaxy's video-3d-reconstruction-gsplat project](https://github.com/Nannigalaxy/video-3d-reconstruction-gsplat), packaged into an easy-to-use Docker container for convenient deployment and use.

## About

This project wraps the original video 3D reconstruction using Gaussian Splatting in a Docker container, making it simple to run the complex setup without having to manage dependencies manually.

The original project by Nannigalaxy converts video files into 3D models using Gaussian Splatting techniques. This Docker version streamlines the process by providing a pre-configured environment.

## Usage

This image runs the `video_to_gsplat.sh` script inside a Conda environment by default.

Key defaults set in the container:

- `FPS=30`
- `INPUT_FILE=/workspace/input/video`
- `OUTPUT_DIR=/workspace/output`

The container expects the input file and output directory to be mounted under `/workspace` in the container. A typical `docker run` invocation looks like this:

```bash
docker run --gpus all \
	-v /path/to/myvideo.mp4:/workspace/input/video \
	-v /path/to/output:/workspace/output \
	ghcr.io/kreisverkehr/video-to-gsplat:latest
```

Windows example (PowerShell):

```powershell
docker run --gpus all `
	-v C:\Users\YourUsername\Videos\sample.mp4:/workspace/input/video `
	-v C:\Users\YourUsername\output:/workspace/output `
	ghcr.io/kreisverkehr/video-to-gsplat:latest
```

Override defaults with environment variables. Examples:

```bash
# change FPS
docker run --gpus all -e FPS=24 -v /video.mp4:/workspace/input/video -v /out:/workspace/output ghcr.io/kreisverkehr/video-to-gsplat:latest

# use a different input filename inside the mounted folder
docker run --gpus all -e INPUT_FILE=/workspace/input/myclip.mp4 -v /path/to:/workspace ghcr.io/kreisverkehr/video-to-gsplat:latest
```

## Volumes

- Mount the input video file into the container at `/workspace/input/video`.
- Mount an output directory at `/workspace/output` where the container will write `sfm_output` and `gsplat_output` subdirectories.

## Building the Docker Image

To build the Docker image locally:

```bash
docker build -t video-to-gsplat:latest .
```

## License & Attribution

This code is created for personal use but is freely available for anyone to use. Please refer to the original project by Nannigalaxy for detailed information about the underlying implementation and any licensing requirements.

- Original Project: [Nannigalaxy/video-3d-reconstruction-gsplat](https://github.com/Nannigalaxy/video-3d-reconstruction-gsplat)
