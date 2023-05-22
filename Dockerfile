FROM nvcr.io/nvidia/l4t-pytorch:r34.1.1-pth1.11-py3 AS pytorch_cuda
#FROM nvcr.io/nvidia/l4t-pytorch:r32.7.1-pth1.9-py3 AS pytorch_cuda
#FROM l4t-pytorch:r32.7.1-pth1.9-py3 AS pytorch_cuda

# updates and software from apt
RUN apt-get -y update && apt-get -y install wget libedit-dev autoconf bc build-essential g++-8 gcc-8 clang-8 lld-8 gettext-base gfortran-8 iputils-ping libbz2-dev libc++-dev libcgal-dev libffi-dev libfreetype6-dev libhdf5-dev libjpeg-dev liblzma-dev libncurses5-dev libncursesw5-dev libpng-dev libreadline-dev libssl-dev libsqlite3-dev libxml2-dev libxslt-dev locales moreutils openssl python-openssl rsync scons python3-pip libopenblas-dev;

#RUN pip install mmcv-full==1.3.8 -f https://download.openmmlab.com/mmcv/dist/cu102/torch1.8.0/index.html
#RUN pip install mmdet==2.14.0
#RUN pip install mmsegmentation==0.14.1

# whatever we can get from pip
RUN pip install mmcv-full==1.7.1
RUN pip install mmdet==3.0.0
RUN pip install mmsegmentation==1.0.0

# now download and, compile and install llvm and llvmlite. We can't use apt packages because wither llvm or llvmlite doesn't have aarch64 
# architecture packages, but they need to be for Jetson and versions need to match too, so it's best to compile- no big deal, just takes
# a long time
WORKDIR /llvm_src
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-11.1.0.src.tar.xz
RUN git clone https://github.com/archie1983/llvmlite
WORKDIR /llvm_src/llvmlite
RUN git checkout jetson_xavier_r34.1.1
WORKDIR /llvm_src
RUN tar -xvf llvm-11.1.0.src.tar.xz 
WORKDIR /llvm_src/llvm-11.1.0
RUN patch -p1 -i ../llvmlite/conda-recipes/llvm-lto-static.patch
RUN patch -p1 -i ../llvmlite/conda-recipes/partial-testing.patch
RUN patch -p1 -i ../llvmlite/conda-recipes/intel-D47188-svml-VF.patch
RUN patch -p1 -i ../llvmlite/conda-recipes/expect-fastmath-entrypoints-in-add-TLI-mappings.ll.patch
RUN patch -p1 -i ../llvmlite/conda-recipes/0001-Revert-Limit-size-of-non-GlobalValue-name.patch
RUN patch -p1 -i ../llvmlite/conda-recipes/llvm_11_consecutive_registers.patch
RUN export PREFIX=/usr CPU_COUNT=4
RUN ../llvmlite/conda-recipes/llvmdev/build.sh

# That should get us to the place where llvm and llvmlite is installed
