#!/bin/bash
#
#  File: build_libamdgcn.sh
#        buind device libraries in $LIBAMDGCN
#

# Do not change these values. Set the environment variables to override these defaults
HCC2=${HCC2:-/opt/rocm/hcc2}
LIBAMDGCN=${LIBAMDGCN:-/opt/rocm/libamdgcn}
LIBAMDGCN_REPOS=${LIBAMDGCN_REPOS:-/home/$USER/git/hcc2}
BUILD_LIBAMDGCN=${BUILD_LIBAMDGCN:-$LIBAMDGCN_REPOS}
LIBAMDGCN_REPO_NAME=${LIBAMDGCN_REPO_NAME:-rocm-device-libs}
HSA_DIR=${HSA_DIR:-/opt/rocm/hsa}
SKIPTEST=${SKIPTEST:-"YES"}
SUDO=${SUDO:-set}
if [ "$SUDO" == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

BUILD_DIR=$BUILD_LIBAMDGCN
if [ "$BUILD_DIR" != "$LIBAMDGCN_REPOS" ] ; then 
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
INSTALL_DIR="${LIBAMDGCN}_${HCC2_VERSION_STRING}"

LLVM_BUILD=$HCC2
SOURCEDIR=$LIBAMDGCN_REPOS/$LIBAMDGCN_REPO_NAME

MCPU_LIST=${GFXLIST:-"gfx700 gfx701 gfx800 gfx801 gfx803 gfx900 gfx901"}

MYCMAKEOPTS="-DLLVM_DIR=$LLVM_BUILD -DGENERIC_IS_ZERO=ON -DCUDA_TRIPLE=ON -DBUILD_HC_LIB=ON -DROCM_DEVICELIB_INCLUDE_TESTS=OFF"

#  Use the following CMAKEOPTS to turn on testing
#MYCMAKEOPTS="-DLLVM_DIR=$LLVM_BUILD -DAMDHSACOD=$HSA_DIR/bin/amdhsacod -DGENERIC_IS_ZERO=ON -DCUDA_TRIPLE=ON -DBUILD_HC_LIB=ON -DROCM_DEVICELIB_INCLUDE_TESTS=ON"

if [ ! -L $LIBAMDGCN ] ; then 
  if [ -d $LIBAMDGCN ] ; then 
     echo "ERROR: Directory $LIBAMDGCN is a physical directory."
     echo "       It must be a symbolic link or not exist"
     exit 1
  fi
fi

function gfx2code(){ 
   case "$1" in 
      "gfx700") codename="kaveri"
      ;;
      "gfx701") codename="hawaii"
      ;;
      "gfx800") codename="iceland"
      ;;
      "gfx801") codename="carrizo"
      ;;
      "gfx802") codename="tonga"
      ;;
      "gfx803") codename="fiji"
      ;;
      "gfx900") codename="vega"
      ;;
      *) codename="$1" 
      ;;
   esac
   echo $codename
}

NUM_THREADS=
if [ ! -z `which "getconf"` ]; then
   NUM_THREADS=$(`which "getconf"` _NPROCESSORS_ONLN)
fi

export LLVM_BUILD HSA_DIR
export PATH=$LLVM_BUILD/bin:$PATH

if [ "$1" != "install" ] ; then 
   if [ $COPYSOURCE ] ; then 
      if [ -d $BUILD_DIR/$LIBAMDGCN_REPO_NAME ] ; then 
         echo rm -rf $BUILD_DIR/$LIBAMDGCN_REPO_NAME
         rm -rf $BUILD_DIR/$LIBAMDGCN_REPO_NAME
      fi
      mkdir -p $BUILD_DIR/$LIBAMDGCN_REPO_NAME
      echo rsync -a $SOURCEDIR/ $BUILD_DIR/$LIBAMDGCN_REPO_NAME/
      rsync -a $SOURCEDIR/ $BUILD_DIR/$LIBAMDGCN_REPO_NAME/
   fi

   LASTMCPU="fiji"
   sedfile1=$BUILD_DIR/$LIBAMDGCN_REPO_NAME/OCL.cmake
   sedfile2=$BUILD_DIR/$LIBAMDGCN_REPO_NAME/CMakeLists.txt
   origsedfile2=$BUILD_DIR/$LIBAMDGCN_REPO_NAME/CMakeLists.txt.orig
   if [ ! $COPYSOURCE ] ; then 
     cp $sedfile2 $origsedfile2 
   fi
   for MCPU in $MCPU_LIST  ; do 
      builddir_mcpu=$BUILD_DIR/build_libamdgcn_$MCPU
      if [ -d $builddir_mcpu ] ; then 
         echo rm -rf $builddir_mcpu
         rm -rf $builddir_mcpu
      fi
      mkdir -p $builddir_mcpu
      cd $builddir_mcpu
      echo 
      echo DOING BUILD FOR $MCPU in Directory $builddir_mcpu
      echo 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      sed -i -e"s/mcpu=$LASTMCPU/mcpu=$MCPU/" $sedfile1
      sed -i -e"s/mcpu=$LASTMCPU/mcpu=$MCPU/" $sedfile2
      LASTMCPU="$MCPU"

      # check seds worked
      echo CHECK: grep mcpu $sedfile1
      grep mcpu $sedfile1
      echo CHECK: grep mcpu $sedfile2
      grep mcpu $sedfile2
      CC="$LLVM_BUILD/bin/clang"
      export CC
      echo "cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$LIBAMDGCN_REPO_NAME"
      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$LIBAMDGCN_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR cmake failed for $MCPU, command was \n"
         echo "      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$LIBAMDGCN_REPO_NAME"
         if [ ! $COPYSOURCE ] ; then 
            #  Put the cmake files in repository back to original condition.
            cd $BUILD_DIR/$LIBAMDGCN_REPO_NAME
            git checkout $sedfile1
            cp $origsedfile2 $sedfile2
         fi
         exit 1
      fi
      make -j $NUM_THREADS 
      if [ $? != 0 ] ; then 
         echo "ERROR make failed for $MCPU "
         if [ ! $COPYSOURCE ] ; then 
            #  Put the cmake files in repository back to original condition.
            cd $BUILD_DIR/$LIBAMDGCN_REPO_NAME
            git checkout $sedfile1
            cp $origsedfile2 $sedfile2
         fi
         exit 1
      fi
   done
   if [ ! $COPYSOURCE ] ; then 
      #  Put the cmake files in repository back to original condition.
      cd $BUILD_DIR/$LIBAMDGCN_REPO_NAME
      git checkout $sedfile1
      cp $origsedfile2 $sedfile2
      rm $origsedfile2 
   fi
   echo 
   echo "  Done with all makes"
   echo "  Please run ./build_libamdgcn.sh install "
   echo 

   if [ "$SKIPTEST" != "YES" ] ; then 
      for MCPU in $MCPU_LIST  ; do 
         builddir_mcpu=$BUILD_DIR/build_libamdgcn_$MCPU
         cd $builddir_mcpu
         echo "running tests in $builddir_mcpu"
         make test 
      done
      echo 
      echo "# done with all tests"
      echo 
   fi
fi

if [ "$1" == "install" ] ; then 
   for MCPU in $MCPU_LIST  ; do 
      echo 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      echo mkdir -p $installdir_gfx/lib
      $SUDO mkdir -p $installdir_gfx/lib
      $SUDO mkdir -p $installdir_gfx/include
      builddir_mcpu=$BUILD_DIR/build_libamdgcn_$MCPU
      codename=$(gfx2code $MCPU)
      installdir_codename=$INSTALL_DIR/${codename}
      echo "running make install from $builddir_mcpu"
      cd $builddir_mcpu
      echo $SUDO make -j $NUM_THREADS install
      $SUDO make -j $NUM_THREADS install
      if [ -L $installdir_codename ] ; then 
         $SUDO rm $installdir_codename
      fi
      echo $SUDO ln -sf $installdir_gfx $installdir_codename
      $SUDO ln -sf $installdir_gfx $installdir_codename
   done

   # Make sure the ocl_isa_version returns correct version
   for fixdir in `ls -d $INSTALL_DIR/gfx*` ; do 
      id=${fixdir##*gfx}
      for fixfile in `ls $fixdir/lib/oclc_isa_version_* 2>/dev/null` ; do
         idfile=${fixfile##*isa_version_}
         idfile=${idfile%*.amdgcn.bc}
         if [ "$id" == "$idfile" ] ; then 
            $SUDO mv $fixfile $fixdir/lib/oclc_isa_version.amdgcn.bc
         else
            $SUDO rm $fixfile
         fi
      done
   done

   # we know $LIBAMDGCN is a link so ok to remove it
   if [ -L $LIBAMDGCN ] ; then 
      $SUDO rm $LIBAMDGCN
   fi
   echo $SUDO ln -sf $INSTALL_DIR $LIBAMDGCN
   $SUDO ln -sf $INSTALL_DIR $LIBAMDGCN
   echo 
   echo "# installation complete "
   echo 
fi
