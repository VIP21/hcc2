#!/bin/bash
# 
#  build_trunk.sh: Smart script to build clang/llvm compiler for TRUNK. 
#                      This uses branch amd-common in llvm and lld repositories
#                      and branch amd-hip for clang repository.  amd-hip
#                      is a temporary fork of amd-common. 
#  
# The default install location is /usr/local/hip_0.5.0. You can override this by 
# setting environment variables TRUNK and TRUNK_VERSION.  Do not set TRUNK to a physical
# directory because this script installs to ${TRUNK}_${TRUNK_VERSION} and then creates 
# a symbolic directory link from there to ${TRUNK}. 
# 
# Written by Greg Rodgers
#
# See the help text below, run 'build_trunk.sh -h' for more information. 
#
TRUNK=${TRUNK:-/usr/local/trunk}
TRUNK_VERSION=${TRUNK_VERSION:-"0.5-0"}
TRUNK_REPOS_DIR=${TRUNK_REPOS_DIR:-/home/$USER/git/trunk}
BUILD_TYPE=${BUILD_TYPE:-Release}
SUDO=${SUDO:-set}
CLANG_REPO_NAME=${CLANG_REPO_NAME:-clang}
LLVM_REPO_NAME=${LLVM_REPO_NAME:-llvm}
LLD_REPO_NAME=${LLD_REPO_NAME:-lld}
TRUNKRT_REPO_NAME=${TRUNKRT_REPO_NAME:-openmp}

CLANG_BRANCH=${CLANG_BRANCH:-master}
REPO_BRANCH=${REPO_BRANCH:-master}
TRUNKRT_BRANCH=${TRUNKRT_BRANCH:-master}
TRUNK_URL="git"

BUILD_TRUNK_DIR=${BUILD_TRUNK_DIR:-$TRUNK_REPOS_DIR}

if [ "$SUDO" == "set" ]  || [ "$SUDO" == "yes" ] || [ "$SUDO" == "YES" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

# By default we build the sources from the repositories.  But you can force 
# replication to another location for speed with BUILD_TRUNK_DIR.
BUILD_DIR=$BUILD_TRUNK_DIR
if [ "$BUILD_DIR" != "$TRUNK_REPOS_DIR" ] ; then 
  COPYSOURCE=true
fi

INSTALL_DIR="${TRUNK}_${TRUNK_VERSION}"

PROC=`uname -p`
GCC=`which gcc`
GCPLUSCPLUS=`which g++`
if [ "$PROC" == "ppc64le" ] ; then 
   COMPILERS="-DCMAKE_C_COMPILER=/usr/bin/gcc-5 -DCMAKE_CXX_COMPILER=/usr/bin/g++-5"
else
   COMPILERS="-DCMAKE_C_COMPILER=$GCC -DCMAKE_CXX_COMPILER=$GCPLUSCPLUS"
fi
MYCMAKEOPTS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_TARGETS_TO_BUILD=AMDGPU;X86;NVPTX;PowerPC;AArch64 $COMPILERS "

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  echo
  echo " build_trunk.sh is a smart clang/llvm compiler build script."
  echo
  echo " Repositories:"
  echo "    build_trunk.sh uses these local git repositories:"
  echo "    DIRECTORY                                BRANCH"
  echo "    ---------                                ------"
  echo "    $TRUNK_REPOS_DIR/$CLANG_REPO_NAME             $CLANG_BRANCH" 
  echo "    $TRUNK_REPOS_DIR/$LLVM_REPO_NAME              $REPO_BRANCH"
  echo "    $TRUNK_REPOS_DIR/$LLD_REPO_NAME               $REPO_BRANCH"
  echo "    $TRUNK_REPOS_DIR/$TRUNKRT_REPO_NAME          $TRUNKRT_BRANCH"
  echo
  echo " Initial Build:"
  echo "    build_trunk.sh with no options does the initial build with these actions:"
  echo "    - Links clang and lld repos in $LLVM_REPO_NAME/tools for a full build."
  echo "    - mkdir -p $BUILD_DIR/build_trunk "
  echo "    - cd $BUILD_DIR/build_trunk"
  echo "    - cmake $BUILD_DIR/$LLVM_REPO_NAME (with cmake options below)"
  echo "    - make"
  echo
  echo " Optional Arguments 'nocmake' and 'install' :"
  echo "    build_trunk.sh takes one optional argument: 'nocmake' or 'install'. "
  echo "    The 'nocmake' or 'install' options can only be used after your initial build"
  echo "    with no options. The 'nocmake' option is intended to restart make after "
  echo "    you fix code following a failed build. The 'install' option will run 'make' "
  echo "    and 'make install' causing installation into the directorey $INSTALL_DIR . "
  echo "    The 'install' option will also create a symbolic link to directory $TRUNK ."
  echo
  echo "    COMMAND                        ACTIONS"
  echo "    -------                        -------"
  echo "    ./build_trunk.sh nocmake   runs 'make'"
  echo "    ./build_trunk.sh install   runs 'make' and 'make install'"
  echo
  echo " Environment Variables:"
  echo "    You can set environment variables to override behavior of build_trunk.sh"
  echo "    NAME              DEFAULT                  DESCRIPTION"
  echo "    ----              -------                  -----------"
  echo "    TRUNK               /usr/local/hip           Where the compiler will be installed"
  echo "    TRUNK_VERSION       $TRUNK_VERSION                    The version suffix to add to TRUNK"
  echo "    TRUNK_REPOS_DIR     /home/<USER>/git/hip     Location of llvm, clang, and lld repos"
  echo "    CLANG_REPO_NAME   clang                    Name of the clang repo"
  echo "    LLVM_REPO_NAME    llvm                     Name of the llvm repo"
  echo "    LLD_REPO_NAME     lld                      Name of the lld repo"
  echo "    REPO_BRANCH       $REPO_BRANCH               The branch for llvm and lld"
  echo "    CLANG_BRANCH      $CLANG_BRANCH                  The branch for clang"
  echo "    SUDO              set                      Use sudo when installing"
  echo "    BUILD_TYPE        Release                  The CMAKE build type" 
  echo "    BUILD_TRUNK_DIR   same as TRUNK_REPOS_DIR    Different build location than TRUNK_REPOS_DIR"
  echo
  echo "   Since install typically requires sudo authority, the default for SUOO is 'set'"
  echo "   Any other value will not use sudo to install. "
  echo
  echo " Examples:"
  echo "    To build a debug version of the compiler, run this command before the build:"
  echo "       export BUILD_TYPE=debug"
  echo "    To install the compiler in a different location without sudo, run these commands"
  echo "       export TRUNK=$HOME/install/hip "
  echo "       export SUDO=no"
  echo
  echo " Post-Install Requirements:"
  echo "    The TRUNK compiler needs the hip runtime and device libraries. Use the companion build "
  echo "    scripts build_libdevice.sh and build_hiprt.sh in that order to build and install "
  echo "    these components. You must have successfully built and installed the compiler before "
  echo "    building these components."
  echo
  echo " The BUILD_TRUNK_DIR Envronment Variable:"
  echo
  echo "    build_trunk.sh will always build with cmake and make outside of the source tree."
  echo "    By default (without BUILD_TRUNK_DIR) the build will occur in a subdirectory of"
  echo "    TRUNK_REPOS_DIR.  For you,that subdirectory is $TRUNK_REPOS_DIR/build_trunk"
  echo
  echo "    The BUILD_TRUNK_DIR environment variable enables source development outside your git"
  echo "    repositories.  By default, this feature is OFF.  This option exsits if access to your"
  echo "    git repositories is very slow. If you set BUILD_TRUNK_DIR to something other than"
  echo "    TRUNK_REPOS_DIR, your repositories willbe replicated to subdirectories of BUILD_TRUNK_DIR" 
  echo "    using rsync.  The build will occur in subdirectory BUILD_TRUNK_DIR/build_trunk."
  echo "    The replication only happens on your initial build, that is, if you specify no arguments."
  echo "    The option 'nocmake' skips replication and then restarts make in the build directory."
  echo "    The "install" option skips replication, skips cmake, runs 'make' and 'make install'. "
  echo "    Be careful to always use options nocmake or install if you made local changes in"
  echo "    BUILD_TRUNK_DIR or your changes will be overriden by your repositories." 
  echo
  echo " cmake Options In Effect:"
  echo "   $MYCMAKEOPTS"
  echo
  exit 
fi

if [ "$1" != "install" ] && [ "$1" != "nocmake" ] && [ "$1" != "" ] ; then 
  echo 
  echo "ERROR: Bad Option: $1"
  echo "       Only options 'install', or 'nocmake' or no options are allowed."
  echo 
  exit 1
fi

if [ ! -L $TRUNK ] ; then 
  if [ -d $TRUNK ] ; then 
     echo
     echo "ERROR: Directory $TRUNK is a physical directory."
     echo "       It must be a symbolic link or not exist"
     echo
     exit 1
  fi
fi

if [ "$1" == "nocmake" ] || [ "$1" == "install" ] ; then
   if [ ! -d $BUILD_DIR/build_trunk ] ; then 
      echo
      echo "ERROR: The build directory $BUILD_DIR/build_trunk does not exist"
      echo "       Run $0 with no options. Please read $0 help"
      echo
      exit 1
   fi
fi

#  Check the repositories exist and are on the correct branch
function checkrepo(){
   REPO_DIR=$TRUNK_REPOS_DIR/$REPONAME
   if [ ! -d $REPO_DIR ] ; then
      echo
      echo "ERROR:  Missing repository directory $REPO_DIR"
      echo "        Environment variables in effect:"
      echo "        TRUNK_REPOS_DIR   : $TRUNK_REPOS_DIR"
      echo "        LLVM_REPO_NAME  : $LLVM_REPO_NAME"
      echo "        CLANG_REPO_NAME : $CLANG_REPO_NAME"
      echo "        LLD_REPO_NAME   : $LLD_REPO_NAME"
      echo "        TRUNKRT_REPO_NAME : $TRUNKRT_REPO_NAME"
      echo
      exit 1
   fi
   echo cd $REPO_DIR
   cd $REPO_DIR
   echo git checkout $USEBRANCH
   git checkout $USEBRANCH
   rc=$?
   if [ "$rc" != 0 ] ; then 
      echo
      echo "ERROR:  Could not checkout branch '$USEBRANCH' repository found in the"
      echo "        directory $REPO_DIR . Please check your repositories"
      echo
      exit 1
   fi
   cat $REPO_DIR/.git/config | grep url | grep -i -q $THISURL/$REPONAME 
   rc=$?
   if [ "$rc" != 0 ] ; then 
      echo 
      echo "ERROR:  Repo at $REPO_DIR is not from http://github.com/$THISURL"
      echo 
      exit 1 
   fi
}

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   #  Check that the repos exist and are on the correct branch
   echo
   echo "Checking local git repositories in $TRUNK_REPOS_DIR ..."
   THISURL=$TRUNK_URL
   USEBRANCH=$REPO_BRANCH
   REPONAME=$LLVM_REPO_NAME
   checkrepo
   USEBRANCH=$CLANG_BRANCH
   REPONAME=$CLANG_REPO_NAME
   checkrepo
   USEBRANCH=$REPO_BRANCH
   REPONAME=$LLD_REPO_NAME
   checkrepo
   USEBRANCH=$TRUNKRT_BRANCH
   REPONAME=$TRUNKRT_REPO_NAME
   checkrepo
   echo "Done checking repositories in $TRUNK_REPOS_DIR"
   echo
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

# Calculate the number of threads to use for make
NUM_THREADS=
if [ ! -z `which "getconf"` ]; then
   NUM_THREADS=$(`which "getconf"` _NPROCESSORS_ONLN)
fi

# Skip synchronization from git repos if nocmake or install are specified
if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo 
   echo "This is a FRESH START. ERASING any previous builds in $BUILD_DIR/build_trunk "
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid FRESH START."
   rm -rf $BUILD_DIR/build_trunk
   mkdir -p $BUILD_DIR/build_trunk

   if [ $COPYSOURCE ] ; then 
      #  Copy/rsync the git repos into /tmp for faster compilation
      mkdir -p $BUILD_DIR
      echo rsync -av --exclude ".git" --delete $TRUNK_REPOS_DIR/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      rsync -av --exclude ".git" --delete $TRUNK_REPOS_DIR/$LLVM_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -a --exclude ".git" $TRUNK_REPOS_DIR/$CLANG_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" --delete $TRUNK_REPOS_DIR/$CLANG_REPO_NAME $BUILD_DIR 2>&1 
      echo rsync -av --exclude ".git" --delete $TRUNK_REPOS_DIR/$LLD_REPO_NAME $BUILD_DIR
      rsync -av --exclude ".git" --delete $TRUNK_REPOS_DIR/$LLD_REPO_NAME $BUILD_DIR 2>&1
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
         echo "ERROR link command for $LLD_REPO_NAME to lld failed."
         exit 1
      fi
   else
      cd $BUILD_DIR/$LLVM_REPO_NAME/tools
      rm -f $BUILD_DIR/$LLVM_REPO_NAME/tools/clang
      if [ ! -L $BUILD_DIR/$LLVM_REPO_NAME/tools/clang ] ; then
         echo ln -sf $BUILD_DIR/$CLANG_REPO_NAME clang
         ln -sf $BUILD_DIR/$CLANG_REPO_NAME clang
      fi
      rm -f $BUILD_DIR/$LLD_REPO_NAME/tools/ld
      if [ ! -L $BUILD_DIR/$LLVM_REPO_NAME/tools/ld ] ; then
         echo ln -sf $BUILD_DIR/$LLD_REPO_NAME ld 
         ln -sf $BUILD_DIR/$LLD_REPO_NAME ld
      fi
   fi
fi

cd $BUILD_DIR/build_trunk

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo 
   echo " ----- Running cmake ---- " 
   echo "   cd $BUILD_DIR/build_trunk"
   echo "   cmake $MYCMAKEOPTS  $BUILD_DIR/$LLVM_REPO_NAME"
   cmake $MYCMAKEOPTS  $BUILD_DIR/$LLVM_REPO_NAME 2>&1 | tee /tmp/cmake.out
   if [ $? != 0 ] ; then 
      echo "ERROR cmake failed. Cmake flags"
      echo "      $MYCMAKEOPTS"
      echo "      Above output saved in /tmp/cmake.out"
      exit 1
   fi
fi

echo
echo " ----- Running make ---- " 
echo "   cd $BUILD_DIR/build_trunk"
echo "   make -j $NUM_THREADS "
make -j $NUM_THREADS 
if [ $? != 0 ] ; then 
   echo "ERROR make -j $NUM_THREADS failed"
   exit 1
fi

if [ "$1" == "install" ] ; then
   echo 
   echo " ----- Installing to $INSTALL_DIR ---- " 
   echo "   cd $BUILD_DIR/build_trunk"
   echo "   $SUDO make install "
   $SUDO make install 
   if [ $? != 0 ] ; then 
      echo "ERROR make install failed "
      exit 1
   fi
   echo " "
   echo "------ Linking $INSTALL_DIR to $TRUNK -------"
   if [ -L $TRUNK ] ; then 
      $SUDO rm $TRUNK   
   fi
   $SUDO ln -sf $INSTALL_DIR $TRUNK   
   # add executables forgot by make install but needed for testing
   $SUDO cp -p $BUILD_DIR/build_trunk/bin/llvm-lit $TRUNK/bin/llvm-lit
   $SUDO cp -p $BUILD_DIR/build_trunk/bin/FileCheck $TRUNK/bin/FileCheck
   echo 
   echo "SUCCESSFUL INSTALL to $INSTALL_DIR with link to $TRUNK"
   echo "   Now rUn build_openmp.sh"
   echo 
else 
   echo 
   echo "SUCCESSFUL BUILD, please run:  $0 install"
   echo "  to install into $TRUNK"
   echo 
fi
