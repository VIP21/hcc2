#!/bin/bash
#
#  File: build_hip.sh
#        Build the hip host and device runtimes, 
#        The install option will install components into the hcc2 installation. 
#        The components include:
#          hip headers installed in $HCC2/include/hip
#          hip host runtime installed in $HCC2/lib/libhiprt.so
#          hip device runtime installed in $HCC2/lib/libdevice/libhiprt.<devicetype.bc
#
# MIT License
#
# Copyright (c) 2017 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
#HIP_REPO_NAME=${HIP_REPO_NAME:-hip}
HIP_REPO_NAME=${HIP_REPO_NAME:-hip}
HCC2_REPO_NAME=${HCC2_REPO_NAME:-hcc2}
BUILD_HCC2=${BUILD_HCC2:-$HCC2_REPOS}
HIP_REPO_DIR=$HCC2_REPOS/$HIP_REPO_NAME
GFXLIST=${GFXLIST:-"gfx700 gfx701 gfx801 gfx803 gfx900"}
export GFXLIST
export HIP_PLATFORM="hcc"

SUDO=${SUDO:-set}
if [ $SUDO == "set" ] ; then
   SUDO="sudo"
else
   SUDO=""
fi

BUILD_DIR=${BUILD_HCC2}

BUILDTYPE="Release"
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
thisdir=$(getdname $0)
[ ! -L "$0" ] || thisdir=$(getdname `readlink "$0"`)
if [ -f $thisdir/HCC2_VERSION_STRING ] ; then
   HCC2_VERSION_STRING=`cat $thisdir/HCC2_VERSION_STRING`
else
   HCC2_VERSION_STRING=${HCC2_VERSION_STRING:-"0.5-2"}
fi
export HCC2_VERSION_STRING
INSTALL_DIR=${INSTALL_HIP:-"${HCC2}_${HCC2_VERSION_STRING}"}
LLVM_BUILD=$HCC2

REPO_BRANCH=${REPO_BRANCH:-HCC2.180805}
#  Check the repositories exist and are on the correct branch
function checkrepo(){
   cd $REPO_DIR
   COBRANCH=`git branch --list | grep "\*" | cut -d" " -f2`
   if [ "$COBRANCH" != "$REPO_BRANCH" ] ; then
      if [ "$COBRANCH" == "master" ] ; then 
        echo "EXIT:  Repository $REPO_DIR is on development branch: master"
        exit 1
      else 
        echo "ERROR:  The repository at $REPO_DIR is not on branch $REPO_BRANCH"
        echo "          It is on branch $COBRANCH"
        exit 1
     fi
   fi
   if [ ! -d $REPO_DIR ] ; then
      echo "ERROR:  Missing repository directory $REPO_DIR"
      exit 1
   fi
}
REPO_DIR=$HCC2_REPOS/$HIP_REPO_NAME
checkrepo

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then
  echo " "
  echo "Example commands and actions: "
  echo "  ./build_hip.sh                   cmake, make, NO Install "
  echo "  ./build_hip.sh nocmake           NO cmake, make,  NO install "
  echo "  ./build_hip.sh install           NO Cmake, make install "
  echo " "
  exit
fi

if [ ! -d $HIP_REPO_DIR ] ; then
   echo "ERROR:  Missing repository $HIP_REPO_DIR/"
   exit 1
fi

if [ ! -f $HCC2/bin/clang ] ; then
   echo "ERROR:  Missing file $HCC2/bin/clang"
   echo "        Build the HCC2 llvm compiler in $HCC2 first"
   echo "        This is needed to build the device libraries"
   echo " "
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

  if [ -d "$BUILD_DIR/build/hip" ] ; then
     echo
     echo "FRESH START , CLEANING UP FROM PREVIOUS BUILD"
     echo rm -rf $BUILD_DIR/build/hip
     rm -rf $BUILD_DIR/build/hip
  fi

  MYCMAKEOPTS="-DCMAKE_BUILD_TYPE=$BUILDTYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
# -DBUILD_SHARED_LIBS=ON -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLVM_DIR=$LLVM_BUILD/lib/cmake/llvm"

  mkdir -p $BUILD_DIR/build/hip
  cd $BUILD_DIR/build/hip
  echo " -----Running hip cmake ---- "
  echo cmake $MYCMAKEOPTS $HIP_REPO_DIR
  cmake $MYCMAKEOPTS $HIP_REPO_DIR
  if [ $? != 0 ] ; then
      echo "ERROR hip cmake failed. Cmake flags"
      echo "      $MYCMAKEOPTS"
      exit 1
  fi

fi

cd $BUILD_DIR/build/hip
echo
echo " -----Running make for hip ---- "
make -j $NUM_THREADS 
if [ $? != 0 ] ; then
      echo " "
      echo "ERROR: make -j $NUM_THREADS  hip_hcc FAILED"
      echo "To restart:"
      echo "  cd $BUILD_DIR/build/hip"
      echo "  make "
      exit 1
fi

#  ----------- Install only if asked  ----------------------------
if [ "$1" == "install" ] ; then
      cd $BUILD_DIR/build/hip
      echo
      echo " -----Installing to $INSTALL_DIR ----- "
      $SUDO make install
      if [ $? != 0 ] ; then
         echo "ERROR make install failed "
         exit 1
      fi
fi
