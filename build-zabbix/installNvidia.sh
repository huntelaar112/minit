#!/bin/bash

nvidia_version=${1}
nvidia_binary="NVIDIA-Linux-x86_64-${nvidia_version}.run"

if [[ -n "${nvidia_version}" ]]; then wget https://us.download.nvidia.com/XFree86/Linux-x86_64/"${nvidia_version}"/"${nvidia_binary}" && chmod +x "${nvidia_binary}" && \
    ./"${nvidia_binary}" --accept-license --ui=none --no-kernel-module --no-questions && \
    rm -rf "${nvidia_binary}"; fi