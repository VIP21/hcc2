#!/bin/bash
#
#  build_rt.sh:  Script to build the HCC2 runtime libraries and debug libraries.  
#                This script will install in location defined by HCC2 env variable
#
# Do not change these values. If you set the environment variables these defaults will changed to 
# your environment variables
HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2RT_REPOS=${HCC2RT_REPOS:-/home/$USER/git/hcc2}
BUILD_RT=${BUILD_RT:-$HCC2RT_REPOS}
RT_REPO_NAME=${RT_REPO_NAME:-hcc2-rt}

NVPTXGPU_DEFAULT=${NVPTXGPU_DEFAULT:-30}
SUDO=${SUDO:-set}

if [ "$SUDO" == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

BUILD_DIR=$BUILD_RT
if [ "$BUILD_DIR" != "$HCC2RT_REPOS" ] ; then 
   COPYSOURCE=true
fi

# Get the HCC2_VERSION_STRING from a file in this directory 
function getdname(){
   local __DIRN=`dirname "$1"`
   if [ "$__DIRN" = "." ] ; then
      __DIRN=$PWD;
   else
      if [ ${__DIRN:0:1} != "/" ] ; then
         if [ ${__DIRN:0:2} == ".." ] ; then
               __DIRN=`dirname $PWD`/${__DIRN:3}
         else
            if [ ${__DIRN:0:1} = "." ] ; then
               __DIRN=$PWD/${__DIRN:2}
            else
               __DIRN=$PWD/$__DIRN
            fi
         fi
      fi
   fi
   echo $__DIRN
}

GFXLIST=${GFXLIST:-"gfx700;gfx701;gfx800;gfx801;gfx803;gfx900;gfx901"}
export GFXLIST

thisdir=$(getdname $0)
[ ! -L "$0" ] || thisdir=$(getdname `readlink "$0"`)
if [ -f $thisdir/HCC2_VERSION_STRING ] ; then 
   HCC2_VERSION_STRING=`cat $thisdir/HCC2_VERSION_STRING`
else 
   HCC2_VERSION_STRING=${HCC2_VERSION_STRING:-"0.4-0"}
fi
export HCC2_VERSION_STRING
INSTALL_DIR="${HCC2}_${HCC2_VERSION_STRING}"

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  echo " "
  echo "Example commands and actions: "
  echo "  ./build_rt.sh                   rsync, cmake, make, NO Install "
  echo "  ./build_rt.sh nocmake           NO rsync, NO cmake, make, NO install "
  echo "  ./build_rt.sh install           NO rsync, NO Cmake, make, INSTALL"
  echo " "
  echo "To build hcc2, you need to build 4 components with these commands"
  echo " "
  echo "  ./build_hcc2.sh "
  echo "  ./build_hcc2.sh install"
  echo "  ./build_atmi"
  echo "  ./build_atmi install"
  echo "  ./build_rt.sh "
  echo "  ./build_rt.sh install"
  echo "  ./build_libamdgcn.sh"
  echo "  ./build_libamdgcn.sh install"
  echo " "
  exit 
fi

WEBSITE="https\:\/\/github.com\/RadeonOpenCompute"

CUDAH=`find /usr/local/cuda/targets -type f -name "cuda.h" 2>/dev/null`
if [ "$CUDAH" == "" ] ; then
   echo
   echo "ERROR:  THE cuda.h FILE WAS NOT FOUND"
   echo "        A CUDA installation is necessary to build libomptarget deviceRTLs"
   echo "        Please install CUDA to build hcc2-rt"
   echo
   exit 1
fi
# I don't see now nvcc is called, but this eliminates the deprecated warnings
export CUDAFE_FLAGS="-w"

if [ -f /usr/bin/nvidia-smi ] ; then 
   GPU=`/usr/bin/nvidia-smi -L | grep -m1 GPU | cut -d: -f2 | cut -d"(" -f1`
   if [ "$GPU" == " Quadro K4000 " ] ; then 
      NVPTXGPU=30
   else
      if [ "$GPU" == " GeForce GTX 980 " ] ; then 
         NVPTXGPU=50
      elif [ "$GPU" == " Tesla K20c " ] ; then
         NVPTXGPU=35
      else 
         NVPTXGPU=$NVPTXGPU_DEFAULT
      fi
   fi
else
   NVPTXGPU=$NVPTXGPU_DEFAULT
fi

if [ ! -d $HCC2RT_REPOS/$RT_REPO_NAME ] ; then 
   echo "ERROR:  Missing repository $HCC2RT_REPOS/$RT_REPO_NAME "
   echo "        Consider setting env variables HCC2RT_REPOS and/or RT_REPO_NAME "
   exit 1
fi

# Make sure we can update the install directory
if [ "$1" == "install" ] ; then 
   $SUDO mkdir -p $INSTALL_DIR
   $SUDO touch $INSTALL_DIR/testfile
   if [ $? != 0 ] ; then 
      echo "ERROR: No update access to $INSTALL_DIR"
      exit 1
   fi
   $SUDO rm $INSTALL_DIR/testfile
fi

NUM_THREADS=
if [ ! -z `which "getconf"` ]; then
    NUM_THREADS=$(`which "getconf"` _NPROCESSORS_ONLN)
fi

COMMON_CMAKE_OPTS="-DCMAKE_C_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_CXX_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER=$HCC2/bin/clang -DCMAKE_CXX_COMPILER=$HCC2/bin/clang++ -DLIBOMPTARGET_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DLIBOMPTARGET_NVPTX_ENABLE_BCLIB=1 -DLIBOMPTARGET_NVPTX_CUDA_COMPILER=$HCC2/bin/clang++ -DLIBOMPTARGET_NVPTX_BC_LINKER=$HCC2/bin/llvm-link"

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then 

   echo " " 
   echo "This is a FRESH START. ERASING any previous builds in $BUILD_DIR/$RT_REPO_NAME "
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid FRESH START."

   if [ $COPYSOURCE ] ; then 
      mkdir -p $BUILD_DIR/$RT_REPO_NAME
      echo rsync -av --exclude ".git" $HCC2RT_REPOS/$RT_REPO_NAME/ $BUILD_DIR/$RT_REPO_NAME/ 
      rsync -av --exclude ".git" $HCC2RT_REPOS/$RT_REPO_NAME/ $BUILD_DIR/$RT_REPO_NAME/ 
   fi

      echo rm -rf $BUILD_DIR/build_lib
      rm -rf $BUILD_DIR/build_lib
      MYCMAKEOPTS="$COMMON_CMAKE_OPTS -DCMAKE_BUILD_TYPE=Release"
      mkdir -p $BUILD_DIR/build_lib
      cd $BUILD_DIR/build_lib
      echo " -----Running openmp cmake ---- " 
      echo cmake $MYCMAKEOPTS  $BUILD_DIR/$RT_REPO_NAME
      cmake $MYCMAKEOPTS  $BUILD_DIR/$RT_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR openmp cmake failed. Cmake flags"
         echo "      $MYCMAKEOPTS"
         exit 1
      fi

      echo rm -rf $BUILD_DIR/build_debug
      rm -rf $BUILD_DIR/build_debug
      export OMPTARGET_DEBUG=1
      MYCMAKEOPTS="$COMMON_CMAKE_OPTS -DLIBOMPTARGET_NVPTX_DEBUG=1 -DLIBOMPTARGET_AMDGCN_DEBUG=1 -DCMAKE_BUILD_TYPE=Debug"
      mkdir -p $BUILD_DIR/build_debug
      cd $BUILD_DIR/build_debug
      echo " -----Running openmp cmake for debug ---- " 
      echo cmake $MYCMAKEOPTS  $BUILD_DIR/$RT_REPO_NAME
      cmake $MYCMAKEOPTS  $BUILD_DIR/$RT_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR openmp debug cmake failed. Cmake flags"
         echo "      $MYCMAKEOPTS"
         exit 1
      fi
fi

cd $BUILD_DIR/build_lib
echo
echo " -----Running make for $BUILD_DIR/build_lib ---- "
make -j $NUM_THREADS
if [ $? != 0 ] ; then 
      echo " "
      echo "ERROR: make -j $NUM_THREADS  FAILED"
      echo "To restart:" 
      echo "  cd $BUILD_DIR/build_lib"
      echo "  make"
      exit 1
fi

cd $BUILD_DIR/build_debug
echo " -----Running make for $BUILD_DIR/build_debug ---- "
make -j $NUM_THREADS
if [ $? != 0 ] ; then 
      echo "ERROR make -j $NUM_THREADS failed"
      exit 1
else
      echo
      echo "Successful build of ./build_rt.sh .  Please run:"
      echo "./build_rt.sh install"
      echo
fi

#  ----------- Install only if asked  ----------------------------
if [ "$1" == "install" ] ; then 
      cd $BUILD_DIR/build_lib
      echo " -----Installing to $INSTALL_DIR/lib ----- " 
      $SUDO make install 
      if [ $? != 0 ] ; then 
         echo "ERROR make install failed "
         exit 1
      fi
      cd $BUILD_DIR/build_debug
      echo " -----Installing to $INSTALL_DIR/lib-debug ---- " 
      $SUDO make install 
      if [ $? != 0 ] ; then 
         echo "ERROR make install failed "
         exit 1
      fi
fi
