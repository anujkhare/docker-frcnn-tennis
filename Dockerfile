# This version is meant to run on a GPU enabled machine, such as G2 instances on Amazon. 
# For running the models on:
# https://github.com/rbgirshick/py-faster-rcnn#requirements-software
FROM nvidia/cuda:7.5-cudnn5-devel-ubuntu14.04
MAINTAINER Anuj Khare <khareanuj18@gmail.com>

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

# more dependencies for faster-RCNN
RUN pip install --upgrade cython && \
    pip install --upgrade easydict && \
    pip install --upgrade numpy

# ENV PYCAFFE_ROOT $CAFFE_ROOT/python
# ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
# ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
# RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

ENV FRCN_ROOT=/opt/code/frcnn \
    NAME=Anuj\ Khare \
    EMAIL=khareanuj18@gmail.com \
    GPU_ARCH=Maxwell

# Downloading py-faster-rcnn
RUN mkdir -p $FRCN_ROOT && \
    cd $FRCN_ROOT && \
    git clone --recursive https://github.com/rbgirshick/py-faster-rcnn.git

# Build Cython modules
RUN cd $FRCN_ROOT/py-faster-rcnn/lib && \
    make

# Merge maser from BVLC/Caffe to support CuDNNv5 (#239 on py-faster-rcnn)
# fix bug: https://github.com/rbgirshick/py-faster-rcnn/issues/155
RUN cd $FRCN_ROOT/py-faster-rcnn/caffe-fast-rcnn && \
    git remote add caffe https://github.com/BVLC/caffe.git && \
    git fetch caffe && \
    git config user.name "$NAME" && git config user.email "$EMAIL" && \
    git merge caffe/master && \
    sed -i.bak '/self_.attr("phase") = static_cast<int>(this->phase_);/d' include/caffe/layers/python_layer.hpp && \
    sed -i.bak '/#include "caffe\/vision_layers.hpp"/d' ./src/caffe/test/test_smooth_L1_loss_layer.cpp

# Build Caffe and pycaffe - GPU config is auto-detected for the most part
#
# GPU is not detected when building as nvidia-docker build simlpy passes through
# docker build. So caffe_detect_insatlled_gpus fails.
# Set the architecture manually.
# https://github.com/NVIDIA/nvidia-docker/issues/236
RUN cd $FRCN_ROOT/py-faster-rcnn/caffe-fast-rcnn && \
    mkdir build && cd build && \
    cmake -DCUDA_ARCH_NAME="$GPU_ARCH" .. && \
    make -j8 all # && make runtest - GPU won't run during build!

# Adding folders a local stuff 
# RUN mkdir -p /data/model /data/images 

# data has been downloaded locally
RUN mv $FRCN_ROOT/py-faster-rcnn/data $FRCN_ROOT/py-faster-rcnn/data1 && \
    mkdir $FRCN_ROOT/py-faster-rcnn/data

VOLUME $FRCN_ROOT/py-faster-rcnn/data

# RUN pip install protobuf
# some missing packages
RUN apt-get update && apt-get install -y --no-install-recommends python-opencv \
      python-tk libyaml-dev && \
    pip install --upgrade sklearn && \
    pip install --upgrade scikit-image && \
    pip install --upgrade protobuf && \
    pip install --upgrade pyyaml

# Expose default port
# expose 8000

# ADD bin/$ARCH-install.sh /opt/neural-networks/install.sh
# ADD bin/$ARCH-run.sh /opt/neural-networks/run.sh
# ADD bin/train.sh /opt/neural-networks/train.sh
# ADD bin/prep.sh /opt/neural-networks/prep.sh
# ADD bin/prep.py /opt/neural-networks/prep.py

# RUN chmod +x /opt/neural-networks/*.sh && \
#     chown root:root /opt/neural-networks/*.sh


# Run GUI from Docker containers using VNC
# http://stackoverflow.com/questions/16296753/can-you-run-gui-apps-in-a-docker-container/16311264#16311264
RUN apt-get update && apt-get install -y x11vnc xvfb && \
    mkdir /.vnc && x11vnc -storepasswd 1234 /.vnc/passwd

# ADD bin/startgui.sh /startgui.sh
# RUN chmod +x /startgui.sh && \
#     chown root:root startgui.sh

# CMD [ "/opt/neural-networks/install.sh", "/data/model", "/data/images" ]
CMD ["/bin/bash"]
