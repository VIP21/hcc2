DEVICE_TARGET=${DEVICE_TARGET:-nvptx64-nvidia-cuda}
#DEVICE_TARGET=${DEVICE_TARGET:-amdgcn-amd-amdhsa}

DEVICE_ARCH=${DEVICE_ARCH:-sm_35}
#DEVICE_ARCH=${DEVICE_ARCH:-gfx803}

env TARGET="-fopenmp-targets=$DEVUCE_TARGET -Xopenmp-target=$DEVICE_TARGET -march=$DEVICE_ARCH" HOSTRTL=$ATMI/lib/libdevice TARGETRTL=$OMPRT/lib GLOMPRTL=$OMPRT/lib LLVMBIN=$HCC2/bin make 2>&1 | tee omptests_run_`date --rfc-3339=date`.log
