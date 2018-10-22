#!/bin/bash
#
#  File: build_libdevice.sh
#        buind the rocm-device-libs libraries in $HCC2/lib/libdevice/$MCPU
#        The rocm-device-libs get built for each processor in $GFXLIST
#        even though currently all rocm-device-libs are identical for each 
#        gfx processor (amdgcn)
#

# Do not change these values. Set the environment variables to override these defaults

HCC2=${HCC2:-/opt/rocm/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
BUILD_HCC2=${BUILD_HCC2:-$HCC2_REPOS}
HCC2_REPO_NAME=${HCC2_REPO_NAME:-hcc2}
HCC2_LIBDEVICE_REPO_NAME=${HCC2_LIBDEVICE_REPO_NAME:-rocm-device-libs}
HSA_DIR=${HSA_DIR:-/opt/rocm/hsa}
SKIPTEST=${SKIPTEST:-"YES"}
SUDO=${SUDO:-set}
if [ "$SUDO" == "set" ] ; then 
   SUDO="sudo"
else 
   SUDO=""
fi

BUILD_DIR=$BUILD_HCC2
if [ "$BUILD_DIR" != "$HCC2_REPOS" ] ; then 
   COPYSOURCE=true
fi

INSTALL_ROOT_DIR=${INSTALL_LIBDEVICE:-"${HCC2}"}
INSTALL_DIR=$INSTALL_ROOT_DIR/lib/libdevice


LLVM_BUILD=$HCC2
SOURCEDIR=$HCC2_REPOS/$HCC2_LIBDEVICE_REPO_NAME

MCPU_LIST=${GFXLIST:-"gfx700 gfx701 gfx801 gfx803 gfx900"}

# build_libdevice now builds cross-platform DBCLs for libm
NVPTXGPUS=${NVPTXGPUS:-30,35,50,60,70}
LIBM_DIR="$HCC2_REPOS/$HCC2_REPO_NAME/examples/libdevice/libm"

REPO_BRANCH=${REPO_BRANCH:-HCC2-180918}
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
REPO_DIR=$HCC2_REPOS/$HCC2_LIBDEVICE_REPO_NAME
checkrepo

MYCMAKEOPTS="-DLLVM_DIR=$LLVM_BUILD -DBUILD_HC_LIB=ON -DBUILD_CUDA2GCN=ON -DROCM_DEVICELIB_INCLUDE_TESTS=OFF -DPREPARE_BUILTINS=$HCC2/bin/prepare-builtins"

function cleanup_sedfiles(){
   #  Put the cmake files in repository back to original condition.
   if [ ! $COPYSOURCE ] ; then
      cd $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      git checkout $sedfile1
      git checkout $sedfile2
   else 
      cp -p $origsedfile1 $sedfile1
      cp -p $origsedfile2 $sedfile2
   fi
}
function define_and_ensure_sedfiles_have_the_fiji_string() {
   # ensure sed files are not corrupted from previous failed builds
   sedfile1=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/OCL.cmake
   origsedfile1=$HCC2_REPOS/$HCC2_LIBDEVICE_REPO_NAME/OCL.cmake
   git checkout $origsedfile1
   sedfile2=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/hip/CMakeLists.txt
   origsedfile2=$HCC2_REPOS/$HCC2_LIBDEVICE_REPO_NAME/hip/CMakeLists.txt
   git checkout $origsedfile2
}
function change_mcpu_in_the_sedfiles() {
   sed -i -e"s/$LASTMCPU/$MCPU/" $sedfile1
   if [ "$MCPU" != "gfx803" ] ; then
      sed -i -e"s/gfx803/$MCPU/" $sedfile1
   fi
   sed -i -e"s/$LASTMCPU/$MCPU/" $sedfile2
}

if [ ! -d $HCC2/lib ] ; then 
  echo "ERROR: Directory $HCC2/lib is missing"
  echo "       HCC2 must be installed in $HCC2 to continue"
  exit 1
fi

function gfx2code(){ 
   case "$1" in 
      "gfx600") codename="tahiti"
      ;;
      "gfx601") codename="pitcairn"
      ;;
      "gfx700") codename="kaveri"
      ;;
      "gfx701") codename="hawaii"
      ;;
      "gfx702") codename="r390"
      ;;
      "gfx703") codename="kabini"
      ;;
      "gfx704") codename="bonaire"
      ;;
      "gfx800") codename="iceland"
      ;;
      "gfx801") codename="carrizo"
      ;;
      "gfx802") codename="tonga"
      ;;
      "gfx803") codename="fiji"
      ;;
      "gfx804") codename="polaris"
      ;;
      "gfx810") codename="stoney"
      ;;
      "gfx900") codename="vega"
      ;;
      "gfx901") codename="tbd901"
      ;;
      "gfx902") codename="tbd902"
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
    
   define_and_ensure_sedfiles_have_the_fiji_string

   if [ $COPYSOURCE ] ; then 
      if [ -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME ] ; then 
         echo rm -rf $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
         $SUDO rm -rf $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      fi
      mkdir -p $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      echo rsync -a $SOURCEDIR/ $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/
      rsync -a $SOURCEDIR/ $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/
      # Fixup ll files to avoid link warnings
      for llfile in `find $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -type f | grep "\.ll" ` ; do 
        sed -i -e"s/:64-A5/:64-S32-A5/" $llfile
      done
   fi

   LASTMCPU="fiji"
   for MCPU in $MCPU_LIST  ; do 
      builddir_mcpu=$BUILD_DIR/build/libdevice/$MCPU
      if [ -d $builddir_mcpu ] ; then 
         echo rm -rf $builddir_mcpu
         # need SUDO because a previous make install was done with sudo 
         $SUDO rm -rf $builddir_mcpu
      fi
      mkdir -p $builddir_mcpu
      cd $builddir_mcpu
      echo 
      echo DOING BUILD FOR $MCPU in Directory $builddir_mcpu
      echo 
      installdir_gfx="$INSTALL_DIR/$MCPU"

      change_mcpu_in_the_sedfiles
      LASTMCPU="$MCPU"

      CC="$LLVM_BUILD/bin/clang"
      export CC
      echo "cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME"
      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR cmake failed for $MCPU, command was \n"
         echo "      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME"
         cleanup_sedfiles
         exit 1
      fi
      make -j $NUM_THREADS 
      if [ $? != 0 ] ; then 
         echo "ERROR make failed for $MCPU "
         cleanup_sedfiles
         exit 1
      fi
   done
   cleanup_sedfiles
#  Now build the math lib
   cd $LIBM_DIR
   for gpu in $MCPU_LIST ; do
      HCC2_GPU=$gpu make
   done
   origIFS=$IFS
   IFS=","
   for gpu in $NVPTXGPUS ; do
      HCC2_GPU="sm_$gpu" make
   done
   IFS=$origIFS
   echo 
   echo "  Done with all makes"
   echo "  Please run ./build_libdevice.sh install "
   echo 

   if [ "$SKIPTEST" != "YES" ] ; then 
      for MCPU in $MCPU_LIST  ; do 
         builddir_mcpu=$BUILD_DIR/build/libdevice/$MCPU
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

   define_and_ensure_sedfiles_have_the_fiji_string

   LASTMCPU="fiji"
   for MCPU in $MCPU_LIST  ; do 
      echo 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      echo mkdir -p $installdir_gfx/include
      $SUDO mkdir -p $installdir_gfx/include
      $SUDO mkdir -p $installdir_gfx/lib
      builddir_mcpu=$BUILD_DIR/build/libdevice/$MCPU

      change_mcpu_in_the_sedfiles
      LASTMCPU="$MCPU"

      echo "running make install from $builddir_mcpu"
      cd $builddir_mcpu
      echo $SUDO make -j $NUM_THREADS install
      $SUDO make -j $NUM_THREADS install

   done
   cleanup_sedfiles

   echo
   echo "INSTALLING DBCL libm from $LIBM_DIR/build "
   echo "rsync -av $LIBM_DIR/build/libdevice $INSTALL_ROOT_DIR/lib"
   $SUDO rsync -av $LIBM_DIR/build/libdevice $INSTALL_ROOT_DIR/lib
   echo "rsync -av $LIBM_DIR/build/libdevice $INSTALL_ROOT_DIR/lib-debug"
   $SUDO rsync -av $LIBM_DIR/build/libdevice $INSTALL_ROOT_DIR/lib-debug

   # rocm-device-lib cmake installs to lib dir, move all bc files up one level
   # and cleanup unused oclc_isa_version bc files and link correct one
   echo
   echo "POST-INSTALL REORG OF SUBDIRECTORIES $INSTALL_DIR"
   for MCPU in $MCPU_LIST  ; do 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      echo "--"
      echo "-- $installdir_gfx"
      echo "-- MOVING bc FILES FROM lib DIRECTORY UP ONE LEVEL"
      $SUDO mv $installdir_gfx/lib/*.bc $installdir_gfx
      $SUDO rmdir $installdir_gfx/lib 

      codename=$(gfx2code $MCPU)
      installdir_codename=$INSTALL_DIR/${codename}
      if [ -L $installdir_codename ] ; then 
         $SUDO rm $installdir_codename
      fi
      cd $INSTALL_DIR
      echo "-- LINKING CODENAME '$codename' TO $MCPU"
      $SUDO ln -sf $MCPU ${codename}

      cd $installdir_gfx
      id=${installdir_gfx##*gfx}
      for fixfile in `ls $installdir_gfx/oclc_isa_version_* 2>/dev/null` ; do
         idfile=${fixfile##*isa_version_}
         relfile=oclc_isa_version_$idfile
         idfile=${idfile%*.amdgcn.bc}
         if [ "$id" == "$idfile" ] ; then 
            if [ -f oclc_isa_version.amdgcn.bc ] ; then
              $SUDO rm -f oclc_isa_version.amdgcn.bc
            fi
            echo "-- LINKING oclc_isa_version.amdgcn.bc TO $relfile"
            $SUDO ln -sf $relfile oclc_isa_version.amdgcn.bc
         else
            $SUDO rm $fixfile
         fi
      done
   done
   # END OF POST-INSTALL REORG 

   echo 
   echo " $0 Installation complete into $INSTALL_DIR"
   echo 
fi
