#!/usr/bin/bash

# Flavor: nvidia-open (nvidia open kernel modules)

set -eoux pipefail

NVIDIA_DRIVER_FLAVOR=nvidia-open bash /ctx/flavors/nvidia.sh
