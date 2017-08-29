#!/bin/bash
# 
#  build_hcc2.sh:  Script to build the hcc2 compiler. 
#                     This clang 5.0 compiler supports CUDA clang AND OpenMP
#                     offloading for BOTH nvidia and Radeon accelerator cards.
#                     This compiler has both the NVPTX and AMDGPU LLVM backends.
#                     The AMDGPU LLVM backend is referred to as the Lightning Compiler.
#
# See the help text below, run 'build_hcc2.sh -h' for more information. 
#
# Do not edit this script to change these values. 
# Simply set the environment variables to override these defaults
HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
HCC2RT_REPOS=${HCC2RT_REPOS:-/home/$USER/git/hcc2}
BUILD_TYPE=${BUILD_TYPE:-Release}
SUDO=${SUDO:-set}
CLANG_REPO_NAME=${CLANG_REPO_NAME:-hcc2-clang}
LLD_REPO_NAME=${LLD_REPO_NAME:-hcc2-lld}
LLVM_REPO_NAME=${LLVM_REPO_NAME:-hcc2-llvm}
RT_REPO_NAME=${RT_REPO_NAME:-hcc2-rt}
BUILD_HCC2=${BUILD_HCC2:-$HCC2_REPOS}

if [ "$SUDO" == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

# By default we build the sources from the repositories
# But you can force replication to another location for speed.
BUILD_DIR=$BUILD_HCC2
if [ "$BUILD_DIR" != "$HCC2_REPOS" ] ; then 
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
thisdir=$(getdname $0)
[ ! -L "$0" ] || thisdir=$(getdname `readlink "$0"`)
if [ -f $thisdir/HCC2_VERSION_STRING ] ; then
   HCC2_VERSION_STRING=`cat $thisdir/HCC2_VERSION_STRING`
else
   HCC2_VERSION_STRING=${HCC2_VERSION_STRING:-"0.3-6"}
fi
export HCC2_VERSION_STRING
INSTALL_DIR="${HCC2}_${HCC2_VERSION_STRING}"

WEBSITE="http\:\/\/github.com\/ROCm-Developer-Tools\/hcc2"

PROC=`uname -p`
GCC=`which gcc`
GCPLUSCPLUS=`which g++`
if [ "$PROC" == "ppc64le" ] ; then 
   COMPILERS="-DCMAKE_C_COMPILER=/usr/bin/gcc-5 -DCMAKE_CXX_COMPILER=/usr/bin/g++-5"
else
   COMPILERS="-DCMAKE_C_COMPILER=$GCC -DCMAKE_CXX_COMPILER=$GCPLUSCPLUS"
fi
MYCMAKEOPTS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_TARGETS_TO_BUILD=AMDGPU;X86;NVPTX;PowerPC;AArch64 $COMPILERS -DHCC2_VERSION_STRING=$HCC2_VERSION_STRING"

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  echo " "
  echo " This LLVM build script uses these git repositories:"
  echo "    $HCC2_REPOS/$CLANG_REPO_NAME"
  echo "    $HCC2_REPOS/$LLVM_REPO_NAME"
  echo "    $HCC2_REPOS/$LLD_REPO_NAME"
  echo " "
  echo " When you provide NO arguments to this script, it performs these actions:"
  echo " 1. mkdir $BUILD_DIR/build_hcc2"
  echo " 2. Link clang and lld repos for in-tree build :" 
  echo "    ln -sf $BUILD_DIR/$CLANG_REPO_NAME $BUILD_DIR/llvm/tools/clang"
  echo "    ln -sf $BUILD_DIR/$LLD_REPO_NAME $BUILD_DIR/llvm/tools/ld"
  echo " 3. Run 'cmake ../$LLVM_REPO_NAME ' in :  $BUILD_DIR/build_hcc2"
  echo " 4. Run make               :  $BUILD_DIR/build_hcc2"
  echo " "
  echo " This script takes one optional argument: 'nocmake' or 'install' "
  echo " Example Commands          Actions"
  echo " ----------------          -------"
  echo " ./build_hcc2.sh           link, cmake, make, but NO install "
  echo " ./build_hcc2.sh nocmake   make, but NO install"
  echo " ./build_hcc2.sh install  $SUDO make install"
  echo " "
  echo " These cmake options are in effect:  "
  echo " $MYCMAKEOPTS"
  echo " "
  echo " The 'nocmake' or 'install' options can only be used after running"
  echo " this script with no options at least one time. The 'nocmake' option is intended to allow"
  echo " you to debug and fix code in $BUILD_DIR without changing your git repos."
  echo " It only runs the make command in $BUILD_DIR/build_hcc2"  
  echo " The 'install' option requires sudo authority. It will also link install directory"
  echo " $INSTALL_DIR to directory $HCC2"
  echo " "
  echo " You can set these environment variables to override behavior of this build script"
  echo " The listed defaults are used the environment variable is not set." 
  echo " "
  echo "    HCC2            /opt/rocm/hcc2           Where the compiler will be installed"
  echo "    HCC2_REPOS      /home/<USER>/git/HCC2    Dir for llvm and $CLANG_REPO_NAME git repos"
  echo "    BUILD_TYPE      Release                  The CMAKE build type" 
  echo "    SUDO            set                      If equal to set, use sudo to install"
  echo "    CLANG_REPO_NAME hcc2-clang               The name of the clang repo"
  echo "    LLD_REPO_NAME   hcc2-lld                 The name of the lld repo"
  echo "    LLVM_REPO_NAME  hcc2-llvm                The name of the llvm repo"
  echo "    BUILD_HCC2      same as HCC2_REPOS       Forces build from other than HCC2_REPOS"
  echo "  "
  echo " We recommend that you do NOT set BUILD_HCC2 unless access to your repositories is very slow. "
  echo " If you set BUILD_HCC2 to something other than $HCC2_REPOS, (e.g. /tmp/hcc2), the source repositories"
  echo " will be incrementally replicated, rsync'ed, to subdirectories of BUILD_HCC2. Set BUILD_HCC2 ONLY"
  echo " if you do not want to build from sources in $HCC2_REPOS. This replication only"
  echo " happens on a complete build.  That is, if you specify 'install' or 'nocmake', "
  echo " NO replication of the repositories is made to BUILD_HCC2.  You do NOT need to set BUILD_HCC2"  
  echo " to force cmake and make to build outside of the sources. The cmake command and subsequent make"
  echo " will occur in $BUILD_DIR/build_hcc2"
  echo "  "
  echo " Examples: To build a debug version of the compiler, run this command before the build:"
  echo "    export BUILD_TYPE=debug"
  echo " To install the compiler in a different location without sudo, run these commands"
  echo "    export HCC2=$HOME/hcc2"
  echo "    export SUDO=noset"
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
      echo "WARNING:  The repository at $REPO_DIR is not on branch rel_$HCC2_VERSION_STRING"
      echo "          It is on branch $COBRANCH"
   fi
   if [ ! -d $REPO_DIR ] ; then
      echo "ERROR:  Missing repository directory $REPO_DIR"
      exit 1
   fi
}
REPO_DIR=$HCC2_REPOS/$LLVM_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$CLANG_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$LLD_REPO_NAME
checkrepo
REPO_DIR=$HCC2RT_REPOS/$RT_REPO_NAME
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

# Fix the banner to print the HCC2 version string. 
cd $HCC2_REPOS/$LLVM_REPO_NAME
LLVMID=`git log | grep -m1 commit | cut -d" " -f2`
cd $HCC2_REPOS/$CLANG_REPO_NAME
CLANGID=`git log | grep -m1 commit | cut -d" " -f2`
cd $HCC2_REPOS/$LLD_REPO_NAME
LLDID=`git log | grep -m1 commit | cut -d" " -f2`
SOURCEID="Source ID:$HCC2_VERSION_STRING-$LLVMID-$CLANGID-$LLDID"
TEMPCLFILE="/tmp/clfile$$.cpp"
ORIGCLFILE="$HCC2_REPOS/$LLVM_REPO_NAME/lib/Support/CommandLine.cpp"
BUILDCLFILE="$BUILD_DIR/$LLVM_REPO_NAME/lib/Support/CommandLine.cpp"
sed "s/LLVM (http:\/\/llvm\.org\/):/HCC2-${HCC2_VERSION_STRING} ($WEBSITE):\\\n $SOURCEID/" $ORIGCLFILE > $TEMPCLFILE
if [ $? != 0 ] ; then 
   echo "ERROR sed command to fix CommandLine.cpp failed."
   exit 1
fi

# Calculate the number of threads to use for make
NUM_THREADS=
if [ ! -z `which "getconf"` ]; then
   NUM_THREADS=$(`which "getconf"` _NPROCESSORS_ONLN)
fi

# Skip synchronization from git repos if nocmake or install are specified
if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo 
   echo "This is a FRESH START. ERASING any previous builds in $BUILD_DIR/build_hcc2 "
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid FRESH START."
   rm -rf $BUILD_DIR/build_hcc2
   mkdir -p $BUILD_DIR/build_hcc2

   if [ $COPYSOURCE ] ; then 
      #  Copy/rsync the git repos into /tmp for faster compilation
      mkdir -p $BUILD_DIR
      echo rsync -av --exclude ".git" --exclude "CommandLine.cpp" --delete $HCC2_REPOS/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      rsync -av --exclude ".git" --exclude "CommandLine.cpp" --delete $HCC2_REPOS/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -a --exclude ".git" $HCC2_REPOS/$CLANG_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" --delete $HCC2_REPOS/$CLANG_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -a --exclude ".git" $HCC2_REPOS/$LLD_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" $HCC2_REPOS/$LLD_REPO_NAME $BUILD_DIR 2>&1 
      mkdir -p $BUILD_DIR/$LLVM_REPO_NAME/tools
      if [ -L $BUILD_DIR/$LLVM_REPO_NAME/tools/clang ] ; then 
        rm $BUILD_DIR/$LLVM_REPO_NAME/tools/clang
      fi
      ln -sf $BUILD_DIR/$CLANG_REPO_NAME $BUILD_DIR/$LLVM_REPO_NAME/tools/clang
      if [ $? != 0 ] ; then 
         echo "ERROR link command for $CLANG_REPO_NAME to clang failed."
         exit 1
      fi
      if [ -L $BUILD_DIR/$LLVM_REPO_NAME/tools/ld ] ; then 
        rm $BUILD_DIR/$LLVM_REPO_NAME/tools/ld
      fi
      ln -sf $BUILD_DIR/$LLD_REPO_NAME $BUILD_DIR/$LLVM_REPO_NAME/tools/ld
      if [ $? != 0 ] ; then 
         echo "ERROR link command for $LLD_REPO_NAME to ld failed."
         exit 1
      fi
   else
      cd $BUILD_DIR/$LLVM_REPO_NAME/tools
      rm -f $BUILD_DIR/$LLVM_REPO_NAME/tools/clang
      if [ ! -L $BUILD_DIR/$LLVM_REPO_NAME/tools/clang ] ; then
         echo ln -sf $BUILD_DIR/$CLANG_REPO_NAME clang
         ln -sf $BUILD_DIR/$CLANG_REPO_NAME clang
      fi
      if [ ! -L $BUILD_DIR/$LLVM_REPO_NAME/tools/ld ] ; then
         echo ln -sf $BUILD_DIR/$LLD_REPO_NAME ld
         ln -sf $BUILD_DIR/$LLD_REPO_NAME ld
      fi
   fi

else
   if [ ! -d $BUILD_DIR/build_hcc2 ] ; then 
      echo "ERROR: The build directory $BUILD_DIR/build_hcc2 does not exist"
      echo "       run $0 without nocmake or install options. " 
      exit 1
   fi
fi

cd $BUILD_DIR/build_hcc2

if [ -f $BUILDCLFILE ] ; then 
   # only copy if there has been a change to the source.  
   diff $TEMPCLFILE $BUILDCLFILE >/dev/null
   if [ $? != 0 ] ; then 
      echo "Updating $BUILDCLFILE with corrected $SOURCEID"
      cp $TEMPCLFILE $BUILDCLFILE
   else 
      echo "File $BUILDCLFILE already has correct $SOURCEID"
   fi
else
   echo "Updating $BUILDCLFILE with $SOURCEID"
   cp $TEMPCLFILE $BUILDCLFILE
fi
rm $TEMPCLFILE

cd $BUILD_DIR/build_hcc2

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo " -----Running cmake ---- " 
   echo cmake $MYCMAKEOPTS  ../$LLVM_REPO_NAME
   cmake $MYCMAKEOPTS  ../$LLVM_REPO_NAME 2>&1 | tee /tmp/cmake.out
   if [ $? != 0 ] ; then 
      echo "ERROR cmake failed. Cmake flags"
      echo "      $MYCMAKEOPTS"
      exit 1
   fi
fi

echo
echo " -----Running make ---- " 
make -j $NUM_THREADS 
if [ $? != 0 ] ; then 
   echo "ERROR make -j $NUM_THREADS failed"
   exit 1
fi

if [ "$1" == "install" ] ; then
   echo " -----Installing to $INSTALL_DIR ---- " 
   $SUDO make install 
   if [ $? != 0 ] ; then 
      echo "ERROR make install failed "
      exit 1
   fi
   echo " "
   echo "------ Linking $INSTALL_DIR to $HCC2 -------"
   if [ -L $HCC2 ] ; then 
      $SUDO rm $HCC2   
   fi
   $SUDO ln -sf $INSTALL_DIR $HCC2   
   # add executables forgot by make install but needed for testing
   $SUDO cp -p $BUILD_DIR/build_hcc2/bin/llvm-lit $HCC2/bin/llvm-lit
   $SUDO cp -p $BUILD_DIR/build_hcc2/bin/FileCheck $HCC2/bin/FileCheck
   echo " "
else 
   echo 
   echo "SUCCESSFUL BUILD, please run:  $0 install"
   echo "  to install into $HCC2"
   echo 
fi
