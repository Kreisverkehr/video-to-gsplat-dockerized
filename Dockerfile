ARG CUDA_VERSION=11.8.0
ARG UBUNTU_VERSION=22.04
ARG COLMAP_VERSION=3.8
ARG MINICONDA_VERSION=26.3.2
ARG CUDA_ARCH_LIST="8.6;8.0;7.5;7.0;6.0;5.2;5.0"

FROM continuumio/miniconda3:${MINICONDA_VERSION} AS miniconda


FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS colmap
ARG COLMAP_VERSION
ARG CUDA_ARCH_LIST

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
        git \
        cmake \
        ninja-build \
        build-essential \
        libboost-program-options-dev \
        libboost-filesystem-dev \
        libboost-graph-dev \
        libboost-system-dev \
        libboost-test-dev \
        libeigen3-dev \
        libflann-dev \
        libfreeimage-dev \
        libmetis-dev \
        libgoogle-glog-dev \
        libgflags-dev \
        libsqlite3-dev \
        libglew-dev \
        qtbase5-dev \
        libqt5opengl5-dev \
        libcgal-dev \
        libceres-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${COLMAP_VERSION} https://github.com/colmap/colmap.git && \
    mkdir -p colmap/build && \
    cd colmap/build && \
    CMAKE_CUDA_ARCHITECTURES="$(echo ${CUDA_ARCH_LIST} | tr -d '.')" && \
    cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES="$CMAKE_CUDA_ARCHITECTURES" -DCMAKE_INSTALL_PREFIX=/colmap-install && \
    ninja && \
    ninja install


FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS pip-builder
ARG CUDA_VERSION
ARG CUDA_ARCH_LIST

COPY --from=miniconda /opt/conda /opt/conda

ENV CONDA_PLUGINS_AUTO_ACCEPT_TOS=true \
    CONDA_OVERRIDE_CUDA=${CUDA_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/conda/bin:$PATH \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST=${CUDA_ARCH_LIST}

RUN conda install -n base conda-libmamba-solver && \
    conda config --set solver libmamba

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        ninja-build \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY build-environment.yml environment.yml
RUN conda env create --file environment.yml

RUN mkdir -p /opt/build-artifacts && \
    git clone --recursive https://github.com/nannigalaxy/video-3d-reconstruction-gsplat.git /tmp/video-3d-reconstruction-gsplat

FROM pip-builder AS diff-gaussian-rasterization-builder
RUN export PYBIND11_INCLUDE_DIR="$(conda run -n gaussian_splatting python -c 'import pybind11; print(pybind11.get_include())')" && \
    export CPLUS_INCLUDE_PATH="$PYBIND11_INCLUDE_DIR:$CPLUS_INCLUDE_PATH" && \
    export CPATH="$PYBIND11_INCLUDE_DIR:$CPATH" && \
    conda run --no-capture-output -n gaussian_splatting pip wheel --no-build-isolation --wheel-dir /opt/build-artifacts \
      /tmp/video-3d-reconstruction-gsplat/speedy-splat/submodules/diff-gaussian-rasterization


FROM pip-builder AS simple-knn-builder
RUN export PYBIND11_INCLUDE_DIR="$(conda run -n gaussian_splatting python -c 'import pybind11; print(pybind11.get_include())')" && \
    export CPLUS_INCLUDE_PATH="$PYBIND11_INCLUDE_DIR:$CPLUS_INCLUDE_PATH" && \
    export CPATH="$PYBIND11_INCLUDE_DIR:$CPATH" && \
    conda run --no-capture-output -n gaussian_splatting pip wheel --no-build-isolation --wheel-dir /opt/build-artifacts \
      /tmp/video-3d-reconstruction-gsplat/speedy-splat/submodules/simple-knn


FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS base
ARG CUDA_VERSION
ARG CUDA_ARCH_LIST

COPY --from=miniconda /opt/conda /opt/conda

ENV FPS=30 \
    INPUT_FILE=/workspace/input/video \
    OUTPUT_DIR=/workspace/output \
    CONDA_PLUGINS_AUTO_ACCEPT_TOS=true \
    CONDA_NO_PROGRESS_BARS=1 \
    CONDA_OVERRIDE_CUDA=${CUDA_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/conda/bin:$PATH \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST=${CUDA_ARCH_LIST}
    
RUN conda install -n base conda-libmamba-solver && \
conda config --set solver libmamba
    
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        git \
        libboost-program-options1.74.0 \
        libc6 \
        libomp5 \
        libopengl0 \
        libmetis5 \
        libceres2 \
        libfreeimage3 \
        libgl1 \
        libglew2.2 \
        libgoogle-glog0v5 \
        libqt5core5a \
        libqt5gui5 \
        libqt5widgets5 \
        libqt5svg5 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


COPY runtime-environment.yml environment.yml
RUN conda env create --file environment.yml

RUN git clone --depth 1 https://github.com/nannigalaxy/video-3d-reconstruction-gsplat.git /opt/video-3d-reconstruction-gsplat
WORKDIR /opt/video-3d-reconstruction-gsplat
RUN git submodule update --depth 1 speedy-splat/

COPY --from=diff-gaussian-rasterization-builder /opt/build-artifacts /opt/build-artifacts
COPY --from=simple-knn-builder /opt/build-artifacts /opt/build-artifacts
RUN conda run --no-capture-output -n gaussian_splatting pip install --no-index --no-deps /opt/build-artifacts/*.whl

COPY --from=colmap /colmap-install /usr/local

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "gaussian_splatting"]
CMD ./video_to_gsplat.sh ${FPS} ${INPUT_FILE} ${OUTPUT_DIR}/sfm_output ${OUTPUT_DIR}/gsplat_output