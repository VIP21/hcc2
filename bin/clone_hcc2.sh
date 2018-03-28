#!/bin/bash

#  clone_hcc2.sh:  Clone the repositories needed to build the hcc2 compiler.  
#
# This script and other utility scripts are now kept in the bin directory of the hcc2 repository 
#
GITROC="https://github.com/radeonopencompute"
GITROCDEV="https://github.com/ROCm-Developer-Tools"
STASH_BEFORE_PULL=${STASH_BEFORE_PULL:-YES}

# Set the directory location for all REPOS
ROC_REPOS=${ROC_REPOS:-/home/$USER/git/hcc2}
HCC2_REPOS=${HCC2_REPOS:-/home/$USER/git/hcc2}
ATMI_REPOS=${ATMI_REPOS:-/home/$USER/git/hcc2}

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

function clone_or_pull(){
repodirname=$basedir/$reponame
echo
if [ -d $repodirname  ] ; then 
   echo "--- Pulling updates to existing dir $repodirname ----"
   echo "    We assume this came from an earlier clone of $repo_web_location/$reponame"
   cd $repodirname
   if [ "$STASH_BEFORE_PULL" == "YES" ] ; then
      git stash -u
   fi
   echo "cd $repodirname ; git checkout $COBRANCH"
   git checkout $COBRANCH
   echo "git pull "
   git pull 
else 
   echo --- NEW CLONE of repo $reponame to $repodirname ----
   cd $basedir
   echo git clone $repo_web_location/$reponame
   git clone $repo_web_location/$reponame
   echo "cd $repodirname ; git checkout $COBRANCH"
   cd $repodirname
   git checkout $COBRANCH
fi
}

mkdir -p $HCC2_REPOS
mkdir -p $ATMI_REPOS

# ---------------------------------------
#  The first 5 REPOS are in ROCm-Development
# ---------------------------------------
repo_web_location=$GITROCDEV
basedir=$HCC2_REPOS

reponame="hcc2"
COBRANCH="master"
clone_or_pull

reponame="openmp"
COBRANCH="master"
clone_or_pull

reponame="llvm"
COBRANCH="HCC2-180315"
clone_or_pull

reponame="clang"
COBRANCH="HCC2-180315"
clone_or_pull

reponame="lld"
COBRANCH="HCC2-180315"
clone_or_pull

reponame="hcc2-hip"
COBRANCH="master"
clone_or_pull

# ---------------------------------------
# The following repos are in RadeonOpenCompute
# ---------------------------------------
repo_web_location=$GITROC

# This repo is used to build /opt/rocm/libamdgcn
basedir=$ROC_REPOS
reponame="rocm-device-libs"
COBRANCH="master"
clone_or_pull

# This is the ATMI repo for ATMI 0.4 in development
basedir=$ATMI_REPOS
reponame="atmi-staging"
COBRANCH="0.4"
clone_or_pull

