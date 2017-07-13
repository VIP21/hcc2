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

if [ $SUDO == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

BUILD_DIR=$BUILD_RT
if [ "$BUILD_DIR" != "$HCC2RT_REPOS" ] ; then 
   COPYSOURCE=true
fi
 
HCC2_VERSION=0.3
HCC2_MOD=6

INSTALL_DIR="${HCC2}_${HCC2_VERSION}-${HCC2_MOD}"

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
BUILDTYPE="Release"

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

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then 

   echo " " 
   echo "This is a FRESH START. ERASING any previous builds in $BUILD_DIR/$RT_REPO_NAME "
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid FRESH START."

   if [ $COPYSOURCE ] ; then 
      mkdir -p $BUILD_DIR/$RT_REPO_NAME
      echo rsync -av --exclude ".git" $HCC2RT_REPOS/$RT_REPO_NAME/ $BUILD_DIR/$RT_REPO_NAME/ 
      rsync -av --exclude ".git" $HCC2RT_REPOS/$RT_REPO_NAME/ $BUILD_DIR/$RT_REPO_NAME/ 
   fi

      BUILDTYPE="Release"
      echo rm -rf $BUILD_DIR/build_lib
      rm -rf $BUILD_DIR/build_lib
      MYCMAKEOPTS="-DCMAKE_C_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_CXX_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_BUILD_TYPE=$BUILDTYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER=$HCC2/bin/clang -DCMAKE_CXX_COMPILER=$HCC2/bin/clang++ -DLIBOMPTARGET_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU "
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

      BUILDTYPE="Debug"
      echo rm -rf $BUILD_DIR/build_debug
      rm -rf $BUILD_DIR/build_debug
      MYCMAKEOPTS="-DCMAKE_C_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_CXX_FLAGS=-DOPENMP_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU -DCMAKE_BUILD_TYPE=$BUILDTYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER=$HCC2/bin/clang -DCMAKE_CXX_COMPILER=$HCC2/bin/clang++ -DLIBOMPTARGET_NVPTX_COMPUTE_CAPABILITY=$NVPTXGPU "
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
