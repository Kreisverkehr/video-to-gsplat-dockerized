ARG CUDA_VERSION=11.8.0
ARG UBUNTU_VERSION=22.04
ARG COLMAP_VERSION=20260427.6785
ARG MINICONDA_VERSION=26.3.2

FROM colmap/colmap:${COLMAP_VERSION} AS colmap
FROM continuumio/miniconda3:${MINICONDA_VERSION} AS miniconda

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS base
ARG CUDA_VERSION

COPY --from=colmap /usr/local /usr/local
COPY --from=miniconda /opt/conda /opt/conda

VOLUME /input
VOLUME /output

ENV FPS=30 \
    CONDA_PLUGINS_AUTO_ACCEPT_TOS=true \
    CONDA_OVERRIDE_CUDA=${CUDA_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/conda/bin:$PATH \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST=5.2
    # TORCH_CUDA_ARCH_LIST=8.6;8.0;7.5;7.0;6.0;5.2;5.0
    # PATH=/opt/conda/bin:$CUDA_HOME/bin:$PATH \
    # LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

RUN conda install -n base conda-libmamba-solver && \
    conda config --set solver libmamba
    
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \        
        ffmpeg \
        git \
        libboost-program-options1.74.0 \
        libc6 \
        libomp5 \
        libopengl0 \
        libmetis5 \
        libceres2 \
        libopenimageio2.2 \
        libgcc-s1 \
        libgl1 \
        libglew2.2 \
        libgoogle-glog0v5 \
        libqt6core6 \
        libqt6gui6 \
        libqt6widgets6 \
        libqt6openglwidgets6 \
        libqt6svg6 \
        libcurl4 \
        libssl3 \
        libmkl-locale \
        libmkl-intel-lp64 \
        libmkl-intel-thread \
        libmkl-core \
        ninja-build \
        wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
    
COPY environment.yml environment.yml
RUN conda env create --file environment.yml

RUN git clone --recursive https://github.com/nannigalaxy/video-3d-reconstruction-gsplat.git /opt/video-3d-reconstruction-gsplat
WORKDIR /opt/video-3d-reconstruction-gsplat

# RUN conda run --no-capture-output -n gaussian_splatting pip install --no-build-isolation ./speedy-splat/submodules/diff-gaussian-rasterization ./speedy-splat/submodules/simple-knn
RUN export PYBIND11_INCLUDE_DIR="$(conda run -n gaussian_splatting python -c 'import pybind11; print(pybind11.get_include())')" && \
    export CPLUS_INCLUDE_PATH="$PYBIND11_INCLUDE_DIR:$CPLUS_INCLUDE_PATH" && \
    export CPATH="$PYBIND11_INCLUDE_DIR:$CPATH" && \
    conda run --no-capture-output -n gaussian_splatting pip install --no-build-isolation \
      ./speedy-splat/submodules/diff-gaussian-rasterization \
      ./speedy-splat/submodules/simple-knn

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "gaussian_splatting"]
CMD ./video_to_gsplat.sh ${FPS} /input /output/sfm_output /output/gsplat_output