#!/bin/bash
# 
#  build_hcc2.sh:  Script to build the hcc2 compiler. 
#                  This clang 7.0 compiler supports clang hip, OpenMP, and clang cuda
#                  offloading languages for BOTH nvidia and Radeon accelerator cards.
#                  This compiler has both the NVPTX and AMDGPU LLVM backends.
#                  The AMDGPU LLVM backend is referred to as the Lightning Compiler.
#
# See the help text below, run 'build_hcc2.sh -h' for more information. 
#
# Do not edit this script to change these values. 
# Simply set the environment variables to override these defaults
HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
BUILD_TYPE=${BUILD_TYPE:-Release}
SUDO=${SUDO:-set}
HCC2_REPO_NAME=${HCC2_REPO_NAME:-hcc2}
CLANG_REPO_NAME=${CLANG_REPO_NAME:-clang}
LLD_REPO_NAME=${LLD_REPO_NAME:-lld}
LLVM_REPO_NAME=${LLVM_REPO_NAME:-llvm}
RT_REPO_NAME=${RT_REPO_NAME:-openmp}
BUILD_HCC2=${BUILD_HCC2:-$HCC2_REPOS}
REPO_BRANCH=${REPO_BRANCH:-HCC2-180328}

if [ "$SUDO" == "set" ]  || [ "$SUDO" == "yes" ] || [ "$SUDO" == "YES" ] ; then
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
   HCC2_VERSION_STRING=${HCC2_VERSION_STRING:-"0.5-0"}
fi
export HCC2_VERSION_STRING
INSTALL_DIR=${INSTALL_HCC2:-"${HCC2}_${HCC2_VERSION_STRING}"}

WEBSITE="http\:\/\/github.com\/ROCm-Developer-Tools\/hcc2"

PROC=`uname -p`
GCC=`which gcc`
GCPLUSCPLUS=`which g++`
if [ "$PROC" == "ppc64le" ] ; then 
   COMPILERS="-DCMAKE_C_COMPILER=/usr/bin/gcc-6 -DCMAKE_CXX_COMPILER=/usr/bin/g++-6"
else
   COMPILERS="-DCMAKE_C_COMPILER=$GCC -DCMAKE_CXX_COMPILER=$GCPLUSCPLUS"
fi
MYCMAKEOPTS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_TARGETS_TO_BUILD=AMDGPU;X86;NVPTX;PowerPC;AArch64 $COMPILERS -DHCC2_VERSION_STRING=$HCC2_VERSION_STRING"

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  echo
  echo " build_hcc2.sh is a smart clang/llvm compiler build script."
  echo
  echo " Repositories:"
  echo "    build_hcc2.sh uses these local git repositories:"
  echo "    DIRECTORY                         BRANCH"
  echo "    ---------                         ------"
  echo "    $HCC2_REPOS/$CLANG_REPO_NAME     $REPO_BRANCH"
  echo "    $HCC2_REPOS/$LLVM_REPO_NAME      $REPO_BRANCH"
  echo "    $HCC2_REPOS/$LLD_REPO_NAME       $REPO_BRANCH"
  echo "    $HCC2_REPOS/$RT_REPO_NAME    $REPO_BRANCH"
  echo
  echo " Initial Build:"
  echo "    build_hcc2.sh with no options does the initial build with these actions:"
  echo "    - Links clang and lld repos in $LLVM_REPO_NAME/tools for a full build."
  echo "    - mkdir -p $BUILD_DIR/build_hcc2 "
  echo "    - cd $BUILD_DIR/build_hcc2"
  echo "    - cmake $BUILD_DIR/$LLVM_REPO_NAME (with cmake options below)"
  echo "    - make"
  echo
  echo " Optional Arguments 'nocmake' and 'install' :"
  echo "    build_hcc2.sh takes one optional argument: 'nocmake' or 'install'. "
  echo "    The 'nocmake' or 'install' options can only be used after your initial build"
  echo "    with no options. The 'nocmake' option is intended to restart make after "
  echo "    you fix code following a failed build. The 'install' option will run 'make' "
  echo "    and 'make install' causing installation into the directorey $INSTALL_DIR . "
  echo "    The 'install' option will also create a symbolic link to directory $HCC2 ."
  echo
  echo "    COMMAND                   ACTIONS"
  echo "    -------                   -------"
  echo "    ./build_hcc2.sh nocmake   make"
  echo "    ./build_hcc2.sh install   make install"
  echo
  echo " Environment Variables:"
  echo "    You can set environment variables to override behavior of build_hcc2.sh"
  echo "    NAME              DEFAULT                  DESCRIPTION"
  echo "    ----              -------                  -----------"
  echo "    HCC2              /opt/rocm/hcc2           Where the compiler will be installed"
  echo "    HCC2_REPOS        /home/<USER>/git/hcc2    Location of llvm, clang, lld, and hcc2 repos"
  echo "    CLANG_REPO_NAME   clang                    Name of the clang repo"
  echo "    LLVM_REPO_NAME    llvm                     Name of the llvm repo"
  echo "    LLD_REPO_NAME     lld                      Name of the lld repo"
  echo "    REPO_BRANCH       $REPO_BRANCH              The branch for clang, llvm, lld, and openmp"
  echo "    SUDO              set                      Use sudo when installing"
  echo "    BUILD_TYPE        Release                  The CMAKE build type"
  echo "    BUILD_HCC2        same as HCC2_REPOS       Different build location than HCC2_REPOS"
  echo "    INSTALL_HCC2      <HCC2>_${HCC2_VERSION_STRING}             Different install location than <HCC2>_${HCC2_VERSION_STRING}"
  echo
  echo "   Since install typically requires sudo authority, the default for SUOO is 'set'"
  echo "   Any other value will not use sudo to install. "
  echo
  echo " Examples:"
  echo "    To build a debug version of the compiler, run this command before the build:"
  echo "       export BUILD_TYPE=debug"
  echo "    To install the compiler in a different location without sudo, run these commands"
  echo "       export HCC2=$HOME/install/hcc2 "
  echo "       export SUDO=no"
  echo
  echo " Post-Install Requirements:"
  echo "    The HCC2 compiler needs openmp, hip, and rocm device libraries. Use the companion build"
  echo "    scripts build_openmp.sh, build_libdevice.sh build_hiprt.sh in that order to build and"
  echo "    install these components. You must have successfully built and installed the compiler"
  echo "    before building these components."
  echo
  echo " The BUILD_HCC2 Envronment Variable:"
  echo
  echo "    build_hcc2.sh will always build with cmake and make outside your source git trees."
  echo "    By default (without BUILD_HCC2) the build will occur in a subdirectory of"
  echo "    HCC2_REPOS.  That subdirectory is $HCC2_REPOS/build_hcc2"
  echo
  echo "    The BUILD_HCC2 environment variable enables source development outside your git"
  echo "    repositories. By default, this feature is OFF.  The BUILD_HCC2 environment variable "
  echo "    can be used if access to your git repositories is very slow or you want to test "
  echo "    changes outside of your local git repositories (specified by HCC2_REPOS env var). "
  echo "    If BUILD_HCC2 is set, your git repositories (specifed by HCC2_REPOS) will be"
  echo "    replicated to subdirectories of BUILD_HCC2 using rsync.  The subsequent build "
  echo "    (cmake and make) will occur in subdirectory BUILD_HCC2/build_hcc2."
  echo "    This replication only happens on your initial build, that is, if you specify no arguments."
  echo "    The option 'nocmake' skips replication and then restarts make in the build directory."
  echo "    The "install" option skips replication, skips cmake, runs 'make' and 'make install'. "
  echo "    Be careful to always use options nocmake or install if you made local changes in"
  echo "    BUILD_HCC2 or your changes will be lost by a new replica of your git repositories."
  echo
  echo " cmake Options In Effect:"

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
REPO_DIR=$HCC2_REPOS/$LLVM_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$CLANG_REPO_NAME
checkrepo
REPO_DIR=$HCC2_REPOS/$LLD_REPO_NAME
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
      echo
      echo "WARNING!  BUILD_DIR!=HCC2_REPOS($HCC2_REPOS)"
      echo "SO RSYNCING HCC2_REPOS TO: $BUILD_DIR"
      echo
      echo rsync -av --exclude ".git" --exclude "CommandLine.cpp" --delete $HCC2_REPOS/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      rsync -av --exclude ".git" --exclude "CommandLine.cpp" --delete $HCC2_REPOS/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -a --exclude ".git" --delete $HCC2_REPOS/$CLANG_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" --delete $HCC2_REPOS/$CLANG_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -a --exclude ".git" --delete $HCC2_REPOS/$LLD_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" --delete $HCC2_REPOS/$LLD_REPO_NAME $BUILD_DIR 2>&1
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
      if [ ! -L $BUILD_DIR/$LLVM_REPO_NAME/tools/hc ] ; then
         echo ln -sf $BUILD_DIR/$HCC2_REPO_NAME/hc hc
         ln -sf $BUILD_DIR/$HCC2_REPO_NAME/hc hc
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
   echo
   echo "SUCCESSFUL INSTALL to $INSTALL_DIR with link to $HCC2"
   echo
else 
   echo 
   echo "SUCCESSFUL BUILD, please run:  $0 install"
   echo "  to install into $HCC2"
   echo 
fi
