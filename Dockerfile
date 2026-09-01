FROM ubuntu:24.04 AS builder
# Disabling interactive requests tzdata in installing process 
ENV DEBIAN_FRONTEND=noninteractive

# build-essential - default tooling & compilers
# gettext-base - for envsubst tool(generating compile_flags.txt)
# nasm, uuid-dev, python3 - for edk2
# ca-certificates for git clone
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    make \
    git \
    bash \
    gettext-base \
    nasm \
    python3 \
    uuid-dev \
    clang \
    clang-tidy \
    clang-format \
    llvm-dev \
    libclang-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# && cd edk2 \
# && git submodule update --init --recursive --depth 1 \ - there's no need for this repo
# && make -C BaseTools -j$(nproc)
WORKDIR /workspace
RUN git clone --depth 1 -b edk2-stable202608 https://github.com/tianocore/edk2.git

# Переменные окружения для сборки
ENV WORKSPACE_DIR_V=/workspace

WORKDIR /workspace/src
CMD ["make", "clean", "generate-flags", "format-check-all"]