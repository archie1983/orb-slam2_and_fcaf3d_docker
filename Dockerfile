FROM nvcr.io/nvidia/l4t-pytorch:r34.1.1-pth1.11-py3 AS pytorch_cuda
#FROM nvcr.io/nvidia/l4t-pytorch:r32.7.1-pth1.9-py3 AS pytorch_cuda
#FROM l4t-pytorch:r32.7.1-pth1.9-py3 AS pytorch_cuda

# Make apt-get and apt try more than one time
#RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries
#RUN echo '\
#Acquire::Retries "100";\
#Acquire::https::Timeout "240";\
#Acquire::http::Timeout "240";\
#APT::Get::Assume-Yes "true";\
#APT::Install-Recommends "false";\
#APT::Install-Suggests "false";\
#Debug::Acquire::https "true";\
#' > /etc/apt/apt.conf.d/99custom

# updates and software from apt
RUN apt-get -y update && apt-get -y install wget libedit-dev autoconf bc build-essential g++-8 gcc-8 clang-8 lld-8 gettext-base gfortran-8 iputils-ping libbz2-dev libc++-dev libcgal-dev libffi-dev libfreetype6-dev libhdf5-dev libjpeg-dev liblzma-dev libncurses5-dev libncursesw5-dev libpng-dev libreadline-dev libssl-dev libsqlite3-dev libxml2-dev libxslt-dev locales moreutils openssl python-openssl rsync scons python3-pip libopenblas-dev libeigen3-dev curl nano xorg openbox;

# Now ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt-get -y update && apt-get -y -o Dpkg::Options::="--force-overwrite" install ros-noetic-desktop-full ros-noetic-pcl-conversions ros-noetic-pcl-ros ros-noetic-perception ros-noetic-jsk-recognition-msgs ros-noetic-jsk-footstep-msgs ros-noetic-octomap-server

#RUN pip install mmcv-full==1.3.8 -f https://download.openmmlab.com/mmcv/dist/cu102/torch1.8.0/index.html
#RUN pip install mmdet==2.14.0
#RUN pip install mmsegmentation==0.14.1

# whatever we can get from pip
#RUN pip install mmcv-full==1.7.1
#RUN pip install mmdet==3.0.0
#RUN pip install mmdet==2.28.0
#RUN pip install mmsegmentation==1.0.0
#RUN pip install mmsegmentation==0.30.0

## now download and, compile and install llvm and llvmlite. We can't use apt packages because wither llvm or llvmlite doesn't have aarch64 
## architecture packages, but they need to be for Jetson and versions need to match too, so it's best to compile- no big deal, just takes
## a long time
#WORKDIR /llvm_src
#RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-11.1.0.src.tar.xz
#RUN git clone https://github.com/archie1983/llvmlite
#WORKDIR /llvm_src/llvmlite
#RUN git checkout jetson_xavier_r34.1.1
#WORKDIR /llvm_src
#RUN tar -xvf llvm-11.1.0.src.tar.xz 
#WORKDIR /llvm_src/llvm-11.1.0
#RUN patch -p1 -i ../llvmlite/conda-recipes/llvm-lto-static.patch
#RUN patch -p1 -i ../llvmlite/conda-recipes/partial-testing.patch
#RUN patch -p1 -i ../llvmlite/conda-recipes/intel-D47188-svml-VF.patch
#RUN patch -p1 -i ../llvmlite/conda-recipes/expect-fastmath-entrypoints-in-add-TLI-mappings.ll.patch
#RUN patch -p1 -i ../llvmlite/conda-recipes/0001-Revert-Limit-size-of-non-GlobalValue-name.patch
#RUN patch -p1 -i ../llvmlite/conda-recipes/llvm_11_consecutive_registers.patch
#RUN export PREFIX=/usr CPU_COUNT=4
#RUN ../llvmlite/conda-recipes/llvmdev/build.sh

# That should get us to the place where llvm and llvmlite is installed

# Instead of patching and building llvmlite here, we can just clone from my repository already patched llvm and llvmlite
# and build that.
WORKDIR /ae_src
# First clone and checkout all required source
RUN git clone https://github.com/archie1983/llvmlite
RUN git clone https://github.com/archie1983/llvm-project
RUN git clone https://github.com/archie1983/fcaf3d
RUN git clone https://github.com/archie1983/MinkowskiEngine
RUN git clone https://github.com/archie1983/mmcv
RUN git clone https://github.com/archie1983/cocoapi

# MultiMap3D has to go in a special directory where we will initiate a catkin workspace
WORKDIR /ae_src/ros/src
RUN git clone https://github.com/archie1983/MultiMap3D

WORKDIR /ae_src/fcaf3d
RUN git checkout for_jetson_xavier_r34_ptc1.11
WORKDIR /ae_src/llvmlite
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
WORKDIR /ae_src/llvm-project
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
WORKDIR /ae_src/MinkowskiEngine
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
WORKDIR /ae_src/ros/src/MultiMap3D
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
WORKDIR /ae_src/mmcv
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
WORKDIR /ae_src/cocoapi
RUN git checkout for_fcaf3d_on_jetson_xavier_r34


# whatever we can get from pip
RUN pip3 install mmdet==2.28.2 mmsegmentation==0.30.0 numpy==1.19.5 pandas==1.4.4 opencv-python==4.5.1.48 matplotlib==3.5.2 shapely==1.8.5

pip3 install mmengine

# Now cocoapi
WORKDIR /ae_src/cocoapi/PythonAPI
# Just in case uninstall pycocotools if they've been pulled in from apt repos
RUN pip3 uninstall pycocotools
RUN python3 setup.py build_ext install

# Now mmcv
WORKDIR /ae_src/mmcv
#RUN export MMCV_WITH_OPS=1
#RUN export FORCE_CUDA=1
ENV MMCV_WITH_OPS=1
ENV FORCE_CUDA=1
RUN MMCV_WITH_OPS=1 pip3 install -e .

# Now build and install llvmlite
WORKDIR /ae_src/llvm-project/llvm
ENV PREFIX=/usr/local 
ENV CPU_COUNT=4
RUN ../../llvmlite/conda-recipes/llvmdev/build.sh
WORKDIR /ae_src/llvmlite
#RUN export LLVM_CONFIG=/usr/local/bin/llvm-config
ENV LLVM_CONFIG=/usr/local/bin/llvm-config
#RUN python setup.py install
RUN pip3 install .

# Now MinkowskiEngine
WORKDIR /ae_src/MinkowskiEngine
#RUN export MAX_JOBS=4
ENV MAX_JOBS=4
RUN pip3 install -U --install-option="--blas=openblas" --install-option="--force_cuda" -v --no-deps .

# Now build and install fcaf3d
WORKDIR /ae_src/fcaf3d
ENV FORCE_CUDA="1"
RUN pip3 install -r requirements/build.txt
#RUN pip3 install --no-cache-dir -e .
RUN pip3 install -v -e .

# Now rotated_iou
WORKDIR /ae_src
RUN git clone https://github.com/archie1983/Rotated_IoU
WORKDIR /ae_src/Rotated_IoU
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
RUN cp -r cuda_op ../fcaf3d/mmdet3d/ops/rotated_iou
WORKDIR /ae_src/fcaf3d/mmdet3d/ops/rotated_iou/cuda_op
RUN python3 setup.py install

#python3 setup.py install
#RUN pip install .

# Now Pangolin
WORKDIR /ae_src
RUN git clone --recursive https://github.com/archie1983/Pangolin
WORKDIR /ae_src/Pangolin
RUN git checkout for_fcaf3d_on_jetson_xavier_r34
RUN ./scripts/install_prerequisites.sh recommended
RUN ./scripts/install_prerequisites.sh -m apt all
RUN cmake -B build
RUN cmake --build build

## Now ROS
#RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
#RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
#RUN apt-get -y update && apt-get -y install ros-noetic-desktop-full ros-noetic-pcl-conversions ros-noetic-pcl-ros ros-noetic-perception ros-noetic-jsk-recognition-msgs ros-noetic-jsk-footstep-msgs

# Now ORB-SLAM2 within MultiMap3D
WORKDIR /ae_src/ros/src/MultiMap3D/ORB-SLAM2_DENSE-master/Vocabulary
RUN gunzip ORBvoc.txt.tar.gz 
RUN tar -xvf ORBvoc.txt.tar
RUN source /opt/ros/noetic/setup.bash
#RUN export LD_LIBRARY_PATH=/usr/include/eigen3:$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/include/eigen3:$LD_LIBRARY_PATH
WORKDIR /ae_src/ros/src/MultiMap3D/ORB-SLAM2_DENSE-master
RUN ./build.sh

WORKDIR /ae_src/ros/src/MultiMap3D/ORB-SLAM2_DENSE-master/Examples/ROS/ORB_SLAM2_DENSE/build
RUN cmake ..
RUN make -j4

WORKDIR /ae_src/ros/src
RUN catkin_init_workspace
WORKDIR /ae_src/ros
RUN catkin_make

# Now download model and configuration for our sparse network
WORKDIR /ae_src/ros/src/MultiMap3D/configs/fcaf3d
wget https://raw.githubusercontent.com/SamsungLabs/fcaf3d/master/configs/fcaf3d/fcaf3d_scannet-3d-18class.py
wget https://raw.githubusercontent.com/archie1983/fcaf3d/master/configs/fcaf3d/fcaf3d_3scales_scannet-3d-18class.py
wget https://raw.githubusercontent.com/archie1983/fcaf3d/master/configs/fcaf3d/fcaf3d_2scales_scannet-3d-18class.py
WORKDIR /ae_src/ros/src/MultiMap3D/checkpoints/
wget https://github.com/samsunglabs/fcaf3d/releases/download/v1.0/20211007_144747.pth
wget https://github.com/samsunglabs/fcaf3d/releases/download/v1.0/20211008_191702.pth
wget https://github.com/samsunglabs/fcaf3d/releases/download/v1.0/20211008_151041.pth
mv 20211008_151041.pth fcaf3d_2scales_scannet-3d-18class_20211008_151041.pth
mv 20211008_191702.pth fcaf3d_3scales_scannet-3d-18class_20211008_191702.pth
mv 20211007_144747.pth fcaf3d_scannet-3d-18class_20211007_144747.pth

# Or we can even just try to install the pre-built wheels.
