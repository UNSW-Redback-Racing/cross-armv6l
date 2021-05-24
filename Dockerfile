
FROM ubuntu:18.04 as base

# Important dependencies
RUN apt-get update && \
	apt-get install -y sudo git gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync

# Code from https://dev.to/emmanuelnk/using-sudo-without-password-prompt-as-non-root-docker-user-52bg
# Adding a user docker for building crosstool-ng
#RUN adduser --disabled-password \
#--gecos '' docker

# Add a user called `develop` and add him to the sudo group
RUN useradd -m docker && echo "docker:docker" | chpasswd && \
    usermod -aG sudo docker


# Add to sudoers group
#RUN adduser docker sudo

# Make sure they are not asked for password
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
#/etc/sudoers

# Logging in as user docker
USER docker


# Getting crosstool-ng
RUN cd /home/docker																&& \
	git clone -b crosstool-ng-1.24.0 https://github.com/crosstool-ng/crosstool-ng 	&& \
	cd crosstool-ng 									   						&& \
	./bootstrap --parallel=$(nproc) 											&& \ 
	./configure --prefix=/home/docker/.local									&& \
	make -j$(($(nproc) * 2)) && make install 											&& \ 	
	cd && rm -rf crosstool-ng 

ENV PATH=/home/docker/.local/bin:$PATH


FROM base as toolchain

WORKDIR /home/docker

# Creating the directory where it will be buit
RUN mkdir /home/docker/src && mkdir /home/docker/RPi
WORKDIR /home/docker/RPi

# toolchain config file
COPY ./armv6l.config .config

RUN ct-ng build.$(($(nproc) * 2))

# Copying the toolchain file
COPY ./toolchain.cmake /home/docker/toolchain.cmake

# Setting up environment variables
ENV CMAKE_TOOLCHAIN_FILE=/home/docker/toolchain.cmake
ENV CROSS_DIR=/home/docker/x-tools/armv6-rpi-linux-gnueabihf
ENV CROSS_BIN_PATH=$CROSS_DIR/bin
ENV CROSS_SYSROOT=$CROSS_DIR/armv6-rpi-linux-gnueabihf/sysroot

# Delete build cache for cross compiler
RUN rm -rf /home/docker/src && rm -rf /home/docker/RPi

# Building other dependencies, such as cmake
USER root

# Building cmake 
WORKDIR /tmp
ADD https://github.com/Kitware/CMake/releases/download/v3.20.2/cmake-3.20.2.tar.gz cmake.tar.gz
RUN tar -zxvf ./cmake.tar.gz > /dev/null						&& \
	cd cmake-3.20.2/											&& \
	./bootstrap --parallel=$(nproc) -- -DCMAKE_USE_OPENSSL=OFF 	&& \
	make -j$(nproc)												&& \
	make install

# Other important dependencies

ADD https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz ./boost.tar.gz
RUN tar -zxvf ./boost.tar.gz > /dev/null;	    				\
    mv ./boost_1_76_0/boost/ ${CROSS_SYSROOT}/include/
