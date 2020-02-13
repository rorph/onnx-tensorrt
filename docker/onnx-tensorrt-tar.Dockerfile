FROM nvcr.io/nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
ARG TENSORRT_VERSION=6.0.1.5
ARG PY3_VERSION=36

# Install package dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        ca-certificates \
        wget \
        git \
        python \
        python-dev \
        python-pip \
        python-setuptools \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        libprotobuf-dev \
        protobuf-compiler \
        cmake \
        swig \
        rsync \
    && rm -rf /var/lib/apt/lists/*

RUN cd /opt && wget http://www.cmake.org/files/v3.13/cmake-3.13.5.tar.gz && tar -xvzf cmake-3.13.5.tar.gz && cd cmake-3.13.5/ && ./configure && make -j32 && make install && update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 1 --force
RUN rm -f /opt/cmake-3.13.5.tar.gz

WORKDIR /opt/onnx-tensorrt
COPY . .

# Install TensorRT
# cp lib/lib* /usr/lib/x86_64-linux-gnu/ &&
# rm /usr/lib/x86_64-linux-gnu/libnv*.a &&
RUN tar -xvf TensorRT-${TENSORRT_VERSION}.*.tar.gz && \
    cd TensorRT-${TENSORRT_VERSION}/ && \
    rsync -a lib/ /usr/lib/x86_64-linux-gnu/ && \
    rsync -a include/ /usr/include/x86_64-linux-gnu/ && \
    rsync -a bin/ /usr/bin/ && \
    mkdir /usr/share/doc/tensorrt && \
    cp -r doc/* /usr/share/doc/tensorrt/ && \
    mkdir /usr/src/tensorrt && \
    cp -r samples /usr/src/tensorrt/  && \
    pip2 install python/tensorrt-${TENSORRT_VERSION}-cp27-none-linux_x86_64.whl && \
    pip3 install python/tensorrt-${TENSORRT_VERSION}-cp${PY3_VERSION}-none-linux_x86_64.whl && \
    pip2 install uff/uff-*-py2.py3-none-any.whl && \
    pip3 install uff/uff-*-py2.py3-none-any.whl && \
    cd ../ && \
    rm -rf TensorRT-${TENSORRT_VERSION}*

# Build and install onnx
RUN pip2 install onnx==1.5 pytest==4.6.5
RUN pip3 install onnx==1.5 pytest==5.1.2

# Build the library
ENV ONNX2TRT_VERSION 0.1.0

WORKDIR /opt/onnx-tensorrt

RUN ldconfig -v && \
    rm -rf build/ && \
    mkdir -p build && \
    cd build && \
    cmake -DCUDA_INCLUDE_DIRS=/usr/local/cuda/include/ .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && \
    # For python2.
    python2 setup.py build && \
    python2 setup.py install && \
    # For python3.
    python3 setup.py build && \
    python3 setup.py install && \
    rm -rf ./build/

WORKDIR /workspace

RUN cp /opt/onnx-tensorrt/onnx_backend_test.py .

RUN ["/bin/bash"]
