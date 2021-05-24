
# cross-armv6l

## Preview
This repo builds a docker image for an armv6l cross compiler based on [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng). The image comes prebuilt with cmake v3.20.1 as well as the most common dependencies like git. All you have to do after building is use it as a base image as follows:
```Dockerfile
FROM cross-armv6l as base

# The environment variable CROSS_SYSROOT exposes 
# the sysroot underwhich you need to install your dependencies.

# The environment variable CMAKE_TOOLCHAIN_FILE exposes 
# the location of the toolchain file (no need to worry about changing it).

# Example installing libmmal (a Raspberry Pi library for interfacing with broadcom VideoCore GPU)
RUN git clone https://github.com/raspberrypi/userland && \
    cd userland                                       && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DCMAKE_INSTALL_PREFIX=${CROSS_SYSROOT}/usr       && \
    make && make install 
    
COPY . ./src

RUN mkdir src/build && \
    cd src/build    && \
    cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} .. && \
    make
```
