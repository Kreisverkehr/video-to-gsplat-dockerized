# Video to GSplat - Dockerized

This repository is a Docker containerization of [Nannigalaxy's video-3d-reconstruction-gsplat project](https://github.com/Nannigalaxy/video-3d-reconstruction-gsplat), packaged into an easy-to-use Docker container for convenient deployment and use.

## About

This project wraps the original video 3D reconstruction using Gaussian Splatting in a Docker container, making it simple to run the complex setup without having to manage dependencies manually.

The original project by Nannigalaxy converts video files into 3D models using Gaussian Splatting techniques. This Docker version streamlines the process by providing a pre-configured environment.

## Usage

To use this Docker container, run the following command:

```bash
docker run -v /path/to/input/file.mp4:/input -v /path/to/output:/output ghcr.io/kreisverkehr/video-to-gsplat:latest
```

### Example

```bash
docker run -v C:\Users\YourUsername\Videos\sample.mp4:/input -v C:\Users\YourUsername\output:/output ghcr.io/kreisverkehr/video-to-gsplat:latest
```

### Volumes

- **`/input`**: Mount your input video file here. The container will read the video from this file.
- **`/output`**: Mount an output directory here. The container will write all generated 3D reconstruction files to this location.

## Building the Docker Image

To build the Docker image locally:

```bash
docker build -t video-to-gsplat:latest .
```

## License & Attribution

This code is created for personal use but is freely available for anyone to use. Please refer to the original project by Nannigalaxy for detailed information about the underlying implementation and any licensing requirements.

- Original Project: [Nannigalaxy/video-3d-reconstruction-gsplat](https://github.com/Nannigalaxy/video-3d-reconstruction-gsplat)
