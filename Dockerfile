FROM ubuntu:14.04

RUN apt-get --no-install-recommends -y install software-properties-common && add-apt-repository ppa:ubuntu-toolchain-r/test && apt-get update && apt-get --no-install-recommends -y install linux-headers-`uname -r` linux-image-`uname -r` pkg-config libatlas-base-dev libprotobuf-dev libleveldb-dev libsnappy-dev libboost-all-dev libhdf5-serial-dev libgflags-dev libgoogle-glog-dev liblmdb-dev protobuf-compiler python-dev python-pip git python-yaml wget curl unzip make cmake gfortran bc libfreetype6-dev libpng12-dev vim g++-4.9 ssh libeigen3-dev && ln -s /usr/bin/g++-4.9 /usr/bin/g++ && ln -s /usr/bin/g++-4.9 /usr/bin/c++ && rm -rf /var/lib/apt/lists/*

# Install CUDA
RUN cd tmp/ && wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run && chmod +x cuda_7.0.28_linux.run && ./cuda_7.0.28_linux.run --silent --toolkit && rm cuda_7.0.28_linux.run

# Install cuDNN
RUN cd tmp/ && wget https://s3-eu-west-1.amazonaws.com/deepomatic-ressources/cudnn-6.5-linux-x64-v2.tgz && tar -xvf cudnn-6.5-linux-x64-v2.tgz && cd cudnn-6.5-linux-x64-v2 && cp libcudnn.so* /usr/lib && cp libcudnn_static.a /usr/lib && cp cudnn.h /usr/include && cd .. && rm -rf cudnn-6.5-linux-x64-v2*

RUN cd /tmp && wget -O opencv.zip https://github.com/Itseez/opencv/archive/2.4.11.zip && unzip opencv.zip && rm opencv.zip && d=`ls -d opencv-*` && cd $d && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCUDA_GENERATION=Kepler -DWITH_CUBLAS=ON . && make all -j 8 && make install && cd .. && rm -rf opencv*

# Install Torch
#RUN curl -sk https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash && git clone https://github.com/torch/distro.git /opt/torch --recursive && cd /opt/torch && ./install.sh

# Install Glog
RUN cd /opt && wget https://google-glog.googlecode.com/files/glog-0.3.3.tar.gz && tar zxvf glog-0.3.3.tar.gz && rm glog-0.3.3.tar.gz && cd /opt/glog-0.3.3 && ./configure && make -j 8 && make install && cd .. && rm -r glog-0.3.3 && ldconfig

# Gflags
RUN cd /opt && wget https://github.com/schuhschuh/gflags/archive/master.zip && unzip master.zip && rm master.zip && mkdir gflags-master/build && cd gflags-master/build && export CXXFLAGS="-fPIC" && cmake .. && make VERBOSE=1 -j 8 && make install && cd ../.. && rm -r gflags-master

# Install Python libs
# APT-GET: pkg-config
# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
RUN pip install numpy scipy pillow networkx matplotlib && export NUMPY_EGG=`ls /usr/local/lib/python2.7/dist-packages | grep -i numpy-` && ln -s /usr/local/lib/python2.7/dist-packages/$NUMPY_EGG/numpy/core/include/numpy /usr/include/python2.7/numpy

# "Mount caffe"
ADD . /opt/caffe

# Build Caffe core (both CPU and GPU, the wrapper takes care of linking the right one)
# APT-GET: libeigen3-dev
# add fix for #include <numpy/arrayobject.h>
RUN cd /opt/caffe && pip install -r python/requirements.txt && sed 's:/usr/lib/python2.7/dist-packages/numpy/core/include:/usr/local/lib/python2.7/dist-packages/numpy/core/include:' Makefile.config.example > Makefile.config && make distribute -j 8 && mv distribute distribute_gpu && sed -i "s/# CPU_ONLY := 1/CPU_ONLY := 1/" Makefile.config && sed -i "s/USE_CUDNN := 1/USE_CUDNN := 0/" Makefile.config && make clean && make distribute -j 8 && mv distribute distribute_cpu && rm -rf CMakeLists.txt caffe.cloc Makefile* cmake build include python src .git*

# Export Library path
ENV PATH="$PATH:/opt/caffe/distribute/bin" \
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/opt/caffe/distribute/lib" \
	PYTHONPATH="$PYTHONPATH:"/opt/caffe/distribute/python"

ENTRYPOINT ["/opt/caffe/wrapper_docker.sh"]
CMD ["/bin/bash"]

