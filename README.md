# Requirements
- CUDA compatible GPU
- [docker](https://docs.docker.com/engine/installation/)
- [nvidia-docker](https://github.com/NVIDIA/nvidia-docker)
- VNC viewer (I used [TigerVNC](https://wiki.archlinux.org/index.php/TigerVNC))

# Instructions to train
This build works for computers with a CUDA-enabled GPU. It is possible to build for CPU as well, but this Dockerfile currently does not support it.

1. Clone the repository and navigate to it.
2. Edit `Dockerfile`. `GPU_ARCH` needs to set manually as CUDA does not work during the build.
```
    GPU_ARCH=<GPU-Arch>
```

3. Build the docker image using:
```docker build -t anujkhare/rcnn:cudnn5 .```
*Note*: This step may take a while.

4. Download the data into `bin/data`.

5. (Optional) Verify the build by running a container:
```
nvidia-docker run -it -v /path/to/bin/data:/opt/code/frcnn/py-faster-rcnn/data anujkhare/rcnn:cudnn5
```

Inside the container:
```
cd /opt/code/frcnn/py-faster-rcnn/caffe-fast-rcnn/build
make runtest
```

6. Run the container with VNC server for GUI:
```
nvidia-docker run --name racket-train -e HOME=/ -p 5900 -v /path/to/bin/data:/opt/code/frcnn/py-faster-rcnn/data anujkhare/rcnn:cudnn5 x11vnc -forever -usepw -create
```

7. Connect to the VNC server
Find the host port on which VNC is running using:
```
docker ps
```

E.g., if `PORTS`, the host port 

*Note*: In TigerVNC viewer, pressing `F8` opens the context menu. Very
important to know if you go into full-screen in the VNC viewer, since all the
keys are captured by it!
