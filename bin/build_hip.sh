#!/bin/bash
# 
#  build_hip.sh:  Script to hip and cudaclang-rt with HCC2. This build will use 
#                 the hcc2 compiler, so only run this after build_hcc2.sh
#                 AND "build_hcc2.sh install"
#
# See the help text below, run 'build_hip.sh -h' for more information. 
#
# Do not edit this script to change these values. 
# Simply set the environment variables to override these defaults
HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
SUDO=${SUDO:-set}
HCC2_REPO_NAME=${HCC2_REPO_NAME:-hcc2}
HIP_REPO_NAME=${HIP_REPO_NAME:-hip}
CUDACLANG_REPO_NAME=${CUDACLANG_REPO_NAME:-cudaclang-rt}

if [ "$SUDO" == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

BUILD_DIR=$HCC2_REPOS

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
   HCC2_VERSION_STRING=${HCC2_VERSION_STRING:-"0.4-0"}
fi
export HCC2_VERSION_STRING
INSTALL_DIR="${HCC2}_${HCC2_VERSION_STRING}"

WEBSITE="http\:\/\/github.com\/ROCm-Developer-Tools\/hcc2"

PROC=`uname -p`
GCC=`which gcc`
GCPLUSCPLUS=`which g++`
if [ "$PROC" == "ppc64le" ] ; then 
   COMPILERS="-DCMAKE_C_COMPILER=/usr/bin/gcc-6 -DCMAKE_CXX_COMPILER=/usr/bin/g++-6"
else
   COMPILERS="-DCMAKE_C_COMPILER=$GCC -DCMAKE_CXX_COMPILER=$GCPLUSCPLUS"
fi

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  echo " "
  echo " This build script uses these git repositories:"
  echo "    $HCC2_REPOS/$HIP_REPO_NAME"
  echo "    $HCC2_REPOS/$CUDACLANG_REPO_NAME"
  echo " "
  echo " When you provide NO arguments to this script, it performs these actions:"
  echo " 1. mkdir $BUILD_DIR/build_hip"
  echo " 2. cd $BUILD_DIR/build_hip ; cmake ../$HIP_REPO_NAME"
  echo " 3. Run make               :  $BUILD_DIR/build_hip"
  echo " "
  echo " This script takes one optional argument: 'nocmake' or 'install' "
  echo " Example Commands          Actions"
  echo " ----------------          -------"
  echo " ./build_hip.sh           cmake, make, but NO install "
  echo " ./build_hip.sh nocmake   make, but NO install"
  echo " ./build_hip.sh install   $SUDO make install"
  echo " "
  echo " The 'nocmake' or 'install' options can only be used after running"
  echo " this script with no options at least one time. The 'nocmake' option is intended to allow"
  echo " you to debug and fix code in $BUILD_DIR without changing your git repos."
  echo " It only runs the make command in $BUILD_DIR/build_hip"  
  echo " The 'install' option requires sudo authority. It will also link install directory"
  echo " $INSTALL_DIR to directory $HCC2"
  echo " "
  echo " You can set these environment variables to override behavior of this build script"
  echo " The listed defaults are used the environment variable is not set." 
  echo " "
  echo "    HCC2                 /opt/rocm/hcc2           The HCC2 installation dir"
  echo "    HCC2_REPOS           /home/<USER>/git/hcc2    Directory for hcc2 repositories"
  echo "    SUDO                 set                      If equal to set, use sudo to install"
  echo "    HCC2_REPO_NAME       hcc2                     The name of this hcc2 repo"
  echo "    HIP_REPO_NAME        hip                      The name of the hip repo"
  echo "    CUDACLANG_REPO_NAME  cudaclang-rt             Name of cuda clang runtime repo"
  echo "  "
  exit 
fi

if [ ! -L $HCC2 ] ; then 
  if [ -d $HCC2 ] ; then 
     echo "ERROR: Directory $HCC2 is a physical directory."
     echo "       It must be a symbolic link or not exist"
     exit 1
  fi
fi

#  Check the repositories exist and are on the correct branch
function checkrepo(){
   cd $REPO_DIR
   COBRANCH=`git branch --list | grep "\*" | cut -d" " -f2`
   if [ "$COBRANCH" != "rel_$HCC2_VERSION_STRING" ] ; then
      if [ "$COBRANCH" == "master" ] ; then 
        echo "WARNING:  Repository $REPO_DIR is on development branch: master"
      else 
        echo "WARNING:  The repository at $REPO_DIR is not on branch rel_$HCC2_VERSION_STRING"
        echo "          It is on branch $COBRANCH"
     fi
   fi
   if [ ! -d $REPO_DIR ] ; then
      echo "ERROR:  Missing repository directory $REPO_DIR"
      exit 1
   fi
}

REPO_DIR=$HCC2_REPOS/$HCC2_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$HIP_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$CUDACLANG_REPO_NAME
checkrepo

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

# Calculate the number of threads to use for make
NUM_THREADS=
if [ ! -z `which "getconf"` ]; then
   NUM_THREADS=$(`which "getconf"` _NPROCESSORS_ONLN)
fi

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then

   echo 
   echo "WARNING! FRESH START. ERASING any previous builds in $BUILD_DIR/build_hip "
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid this FRESH START."
   echo
   rm -rf $BUILD_DIR/build_hip
   mkdir -p $BUILD_DIR/build_hip

else

   if [ ! -d $BUILD_DIR/build_hip ] ; then 
      echo "ERROR: The build directory $BUILD_DIR/build_hip does not exist"
      echo "       run $0 without nocmake or install options. " 
      exit 1
   fi

fi

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then

   cd $BUILD_DIR/build_hip
   echo
   echo " -----Running hip cmake ---- " 
   echo "cd $BUILD_DIR/build_hip; cmake ../$HIP_REPO_NAME"
   echo cmake -DHCC_HOME=$HCC2 -DCMAKE_INSTALL_PREFIX=$HCC2 ../$HIP_REPO_NAME 2>&1 | tee -a /tmp/cmake.out
   cmake -DHCC_HOME=$HCC2 -DCMAKE_INSTALL_PREFIX=$HCC2 ../$HIP_REPO_NAME 2>&1 | tee -a /tmp/cmake.out
   #cmake -DHCC_HOME=/opt/rocm/hcc -DCMAKE_INSTALL_PREFIX=$HCC2 ../$HIP_REPO_NAME 2>&1 | tee -a /tmp/cmake.out
   if [ $? != 0 ] ; then 
      echo "ERROR cmake hip failed. Full log of cmake in /tmp/cmake.out"
      exit 1
   fi
fi

cd $BUILD_DIR/build_hip
echo
echo " -----Running hip make ---- " 
echo "cd $BUILD_DIR/build_hip; make -j $NUM_THREADS"
make -j $NUM_THREADS 
if [ $? != 0 ] ; then 
   echo "ERROR make -j $NUM_THREADS failed"
   exit 1
fi

if [ "$1" == "install" ] ; then

   cd $BUILD_DIR/build_hip
   echo 
   echo " -----Installing hip to $INSTALL_DIR ---- " 
   $SUDO make install 
   if [ $? != 0 ] ; then 
      echo "ERROR make install for hip failed "
      exit 1
   fi

else 
   echo 
   echo "SUCCESSFUL BUILD, please run:  $0 install"
   echo "  to install into $HCC2"
   echo 
fi
