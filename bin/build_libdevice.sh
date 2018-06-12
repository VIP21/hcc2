#!/bin/bash
#
#  File: build_libdevice.sh
#        buind device libraries in $HCC2/lib/libdevice
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

INSTALL_DIR=${INSTALL_LIBDEVICE:-"${HCC2}/lib/libdevice"}

LLVM_BUILD=$HCC2
SOURCEDIR=$HCC2_REPOS/$HCC2_LIBDEVICE_REPO_NAME

MCPU_LIST=${GFXLIST:-"gfx700 gfx701 gfx801 gfx803 gfx900"}

MYCMAKEOPTS="-DLLVM_DIR=$LLVM_BUILD -DBUILD_HC_LIB=ON -DBUILD_CUDA2GCN=ON -DROCM_DEVICELIB_INCLUDE_TESTS=OFF -DPREPARE_BUILTINS=$HCC2/bin/prepare-builtins"

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
   if [ $COPYSOURCE ] ; then 
      if [ -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME ] ; then 
         echo rm -rf $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
         rm -rf $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
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
   sedfile1=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/OCL.cmake
   sedfile2=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/CMakeLists.txt
   origsedfile2=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/CMakeLists.txt.orig

   # Temporarily fix name collision in sync.cl
   hipsrc=$BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/hip/src/sync.cl
   sed -i -e "s/__syncthreads/__syncthreads_hc_barrier/" $hipsrc

   echo patch -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -p1  $HCC2_REPOS/$HCC2_REPO_NAME/fixes/rocdl.patch
   patch -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -p1 < $HCC2_REPOS/$HCC2_REPO_NAME/fixes/rocdl.patch
   echo "cp $HCC2_REPOS/$HCC2_REPO_NAME/fixes/opencuda2gcn.ll $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/cuda2gcn/src/opencuda2gcn.ll"
   cp $HCC2_REPOS/$HCC2_REPO_NAME/fixes/opencuda2gcn.ll $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME/cuda2gcn/src/opencuda2gcn.ll

   if [ ! $COPYSOURCE ] ; then 
     cp $sedfile2 $origsedfile2 
   fi

   for MCPU in $MCPU_LIST  ; do 
      builddir_mcpu=$BUILD_DIR/build/libdevice/$MCPU
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
      if [ "$MCPU" != "gfx803" ] ; then
         sed -i -e"s/gfx803/$MCPU/" $sedfile1
      fi
      sed -i -e"s/mcpu=$LASTMCPU/mcpu=$MCPU/" $sedfile2
      LASTMCPU="$MCPU"

      # check seds worked
      echo CHECK: grep mcpu $sedfile1
      grep mcpu $sedfile1
      echo CHECK: grep mcpu $sedfile2
      grep mcpu $sedfile2
      CC="$LLVM_BUILD/bin/clang"
      export CC
      echo "cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME"
      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR cmake failed for $MCPU, command was \n"
         echo "      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$installdir_gfx $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME"
         if [ ! $COPYSOURCE ] ; then
            #  Put the cmake files in repository back to original condition.
            cd $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
            git checkout $sedfile1
            cp $origsedfile2 $sedfile2
            git checkout $sedfile1
            git checkout $hipsrc
            patch -R -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -p1 < $HCC2_REPOS/$HCC2_REPO_NAME/fixes/rocdl.patch
         fi
         exit 1
      fi
      make -j $NUM_THREADS 
      if [ $? != 0 ] ; then 
         echo "ERROR make failed for $MCPU "
         if [ ! $COPYSOURCE ] ; then
            #  Put the cmake files in repository back to original condition.
            cd $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
            git checkout $sedfile1
            cp $origsedfile2 $sedfile2
            patch -R -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -p1 < $HCC2_REPOS/$HCC2_REPO_NAME/fixes/rocdl.patch
         fi
         exit 1
      fi
   done
   if [ ! $COPYSOURCE ] ; then
      #  Put the cmake files in repository back to original condition.
      cd $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME
      git checkout $sedfile1
      cp $origsedfile2 $sedfile2
      rm $origsedfile2 
   fi
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
   for MCPU in $MCPU_LIST  ; do 
      echo 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      echo mkdir -p $installdir_gfx/include
      $SUDO mkdir -p $installdir_gfx/include
      $SUDO mkdir -p $installdir_gfx/lib
      builddir_mcpu=$BUILD_DIR/build/libdevice/$MCPU
      codename=$(gfx2code $MCPU)
      installdir_codename=$INSTALL_DIR/${codename}
      echo "running make install from $builddir_mcpu"
      cd $builddir_mcpu
      echo $SUDO make -j $NUM_THREADS install
      $SUDO make -j $NUM_THREADS install
      if [ -L $installdir_codename ] ; then 
         $SUDO rm $installdir_codename
      fi
      cd $installdir_gfx/..
      echo $SUDO ln -sf $MCPU ${codename}
      $SUDO ln -sf $MCPU ${codename}
   done

   # Make sure the ocl_isa_version returns correct version
   for fixdir in `ls -d $INSTALL_DIR/gfx*` ; do 
      id=${fixdir##*gfx}
      for fixfile in `ls $fixdir/lib/oclc_isa_version_* 2>/dev/null` ; do
         idfile=${fixfile##*isa_version_}
         idfile=${idfile%*.amdgcn.bc}
         if [ "$id" == "$idfile" ] ; then 
            if [ -f $fixdir/lib/oclc_isa_version.amdgcn.bc ] ; then
              $SUDO rm -f $fixdir/lib/oclc_isa_version.amdgcn.bc
            fi
            $SUDO ln -sf $fixfile $fixdir/lib/oclc_isa_version.amdgcn.bc
         else
            $SUDO rm $fixfile
         fi
      done
   done

   # rocm-device-lib cmake installs to lib dir, move all bc files up one level
   for MCPU in $MCPU_LIST  ; do 
      installdir_gfx="$INSTALL_DIR/$MCPU"
      echo mv $installdir_gfx/lib/*.bc $installdir_gfx
      $SUDO mv $installdir_gfx/lib/*.bc $installdir_gfx
      echo rmdir $installdir_gfx/lib 
      $SUDO rmdir $installdir_gfx/lib 
   done

   if [ ! $COPYSOURCE ] ; then
      echo RESTORING $hipsrc with : git checkout $hipsrc and reverse patch
      git checkout $hipsrc
      patch -R -d $BUILD_DIR/$HCC2_LIBDEVICE_REPO_NAME -p1 < $HCC2_REPOS/$HCC2_REPO_NAME/fixes/rocdl.patch
   fi
   echo 
   echo " $0 Installation complete into $INSTALL_DIR"
   echo 
fi
