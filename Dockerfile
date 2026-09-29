# Container layout
#/workspace/
#├── edk2/                      <-- Base UEFI library (MdePkg, ShellPkg, BaseTools)
#│   ├── MdePkg/Include/        <-- Clang-tidy needs these headers
#│   └── ...
#│
#└── src/                       <-- Your project code (Active working directory)
#    ├── compile_flags.txt      <-- Points to /workspace/edk2/...
#    └── ...

FROM debian:12 AS builder
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
    clang-22 \
    clang-tidy-22 \
    clang-format-22 \
    llvm-22-dev \
    libclang-22-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
RUN ln -sf /usr/bin/clang-tidy-22 /usr/bin/clang-tidy && ln -sf /usr/bin/clang-format-22 /usr/bin/clang-format

ENV WORKSPACE_DIR_V=/workspace
WORKDIR /workspace/src
CMD ["bash", "-c", "cp -r /host_code/. /workspace/src && make clean init format-check-all"]