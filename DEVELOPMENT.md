HCC2 - V 0.4-0
==============

## HCC2 Repositories

<A NAME="Repositories">
In addition to this base hcc2 repository, these repositories contain development and release source code.
The hcc2 compiler is an LLVM and CLANG 6 compiler.  It requires a number of repositories to build from source.

### hcc2-clang
https:/github.com/ROCM-Developer-Tools/hcc2-clang
```
Original: 		https://github.com/radeonOpenCompute/hcc-clang-upgrade  branch:clang_tot_upgrade
Original Branch:  	clang_tot_upgrade.   This is a copy of clang_tot_upgrade as of June 27
Development Branch:     master
```
The clang_tot_upgrade branch of this repository is a clone of the HCC development branch clang_tot_upgrade. That clone containes support for the new address space and alloca in address space 5 (local).

The master branche contains significant changes to support OpenMP 4.5. OpenMP 4.5 changes were taken from the IBM coral compiler (clang repository). This compiler supports nvptx64 backend.   Then significant changes were made to support Radeon GPUs (amdgcn).  Both nvptx64 and amdgcn targets are supported by HCC2.

### hcc2-llvm
https:/github.com/ROCM-Developer-Tools/hcc2-llvm
```
Original: 		https://github.com/radeonOpenCompute/llvm   branch:amd-hcc
Original Branch:  	amd-hcc  This is a copy of amd-hcc as of June 27
Development Branch:     master
```
The amd-hcc branch of this repository is a clone of the HCC development branch amd-hcc taken on various dates when the code for hcc2 is rebased.  It containes the amdgcn backend to support the new address space scheme (Generic-is-zero) and alloca in address space 5 (local).  The only llvm repository updates we need for hcc2 are to accept the osname "cuda" in the triple to trigger the new address space scheme.  Both OpenMP offloading and Cuda Clang languages require the osname "cuda".  The Nvidia CUDA operating environment is only needed when specifying an nvptx64 target.

### hcc2-lld
https:/github.com/ROCM-Developer-Tools/hcc2-lld
```
Original: 		https://github.com/radeonOpenCompute/lld   branch:amd-hcc
Original Branch:  	amd-hcc  This is a copy of amd-hcc as of June 27
Development Branch:     master
```
The amd-hcc branch of this repository is a clone of the HCC development branch amd-hcc.   There are no changes to lld to support hcc2.  So the develoment branch is identical to the master branch.

### hcc2-rt
https:/github.com/ROCM-Developer-Tools/hcc2-rt
```
Original: 		https://github.com/clang-ykt/openmp branch:master
Original Branch:  	ykt_170609 This is a copy of original master(ykt) as of June 27)
Original Branch:  	ykt_master  This is a copy of original master(ykt) as of October 27)
Development Branch:     master
```
This repository is a clone of the IBM Coral compiler openmp runtime with significant updates to support AMDGCN.

### ROCm-Device-Libs
https:/github.com/RadeonOpenCompute/ROCm-Device-Libs
```
Original: 		https://github.com/RadeonOpenCompute/ROCm-Device-Libs  branch:rel_0.3-9
```
This is a frozen branch of the ROCm-Device-libs.  It is used to build the libamdgcn package that has LLVM bitcode libraries needed linking before compilation of LLVM IR by the Lightning Compiler.
