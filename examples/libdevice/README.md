```
This directory contains examples of how to build Device BC Libraries, DBCLs. 
For now, this README is the main source of information about DBCLs. 

The DBCL Concept:
----------------
The purpose of a DBCL is to support and encourage cross-platform portability
in the use of library functions. Specifically, DBCLs provide the abilit to
have the same host and device source code that reference functions from
external libraries. DBCLs allow the use of existing header files for both
the host and device passes without changing existing header files. 
This removes the need to maintain duplicate header files.  Also, the 
DBCL removes the overhead of compiling supplemental device header files
with architecture-specific implementations of all functions in the library.
Currently, each device compilation for CUDA and HIP requires this extra
overhead.  Lastly, the DBCL provides a method for end-users or third party
library maintainers to provide their own pre-compiled device libraries
with GPU-specific optimizations in a way that encourages portability
across hardware platforms.  

The canonical example of a DBCL will be libm.bc. The DBCL libm.bc will provide
the architecture-specific definitions of the standard c and C++ math libraries.
The system header files math.h and cmath.hpp typically provide ONLY
declarations of math functions. There are exceptions where header files provide
both a declaration and a definition or partial definition.  These exceptions
can be disabled with existing macros to control the header files so only
declarations are provided for math functions during the device pass.
For host linking of applications that use math functions, the programmer
typically provides the -lm flag so the linker will look for either
libm.so or libm.a at link time. We will use this flag to pickup the DBCL
libm.bc. 

Like host implementations of libm.so and libm.a, the DBCL libm.bc must be
compiled and installed ahead of time. They are typically stored as part of
the compiler installation.  Each DBCL is built for a specific GPU so the 
source code can have optimizations for different GPUs managed using #if 
compiler macros.The libdevice naming convention manages multiple
libm.bc files in a simple directory structure.

A DBCL provides the GPU-specific inline implementation (definition) of header
file functions WITHOUT requiring a user-compilable definition in a supplemental
header files. Currently both CUDA and HIP provide architecture-specific
definitions in supplemental header files that must be compiled by each device
compilation regardless of need. The use of DBCLs removes the need for
supplemental header files for OpenMP. But it does introduce a new compiler
build process. This concept could be adopted for CUDA and HIP in the future. 

A DBCL is activated by the clang driver by automatically adding the flag 
 -mlink-builtin-bitcode to the clang cc1 device pass as a result of the user
specified -l command line option.  The bc file specified by
 -mlink-builtin-bitcode will be linked immediately after 
clang compilation while the generated LLVM-IR is still in memory and before
the source module's LLVM-IR is written to disk for the compile phase.
This is NOT an additional clang driver phase, step, or command.  This is part
of the clang cc1 command for the compile phase.  So there is no change to
the internal clang driver phase actions other than a new cc1 flag that is
auotmatically add as a result of the user specified -l flag. 

The use of the -l flag by clang to identify DBCLs introduces a minor drawback
 of DBCLs. The -l flag and the supporting -L are now necessary as both a 
compile flag and link flag. The tradeoff is that only user-specified DBCLs
are linked in memory at the end of the compile phase. Also, the supporting
environment variable LIBRARY_PATH, if needed for host linking, must be active
for compilation to enable proper search of DBCLs. 

The internal clang compiler source code to search for a DBCL and generate
the -mlink-builtin-bitcode flag could be found in
 clang/lib/Driver/ToolChains/Clang.cpp. This feature is only available on
HCC2 0.5-4 and beyond. The libm demo in hcc2/examples/libdevice/libm is
actually installed in the compiler and will be duplicated in the openmp
repository in the directory openmp/libomptarget/libdevice. If accepted
upstream, this will remove OpenMP offload dependence on cuda headers
found in clang/lib/Headers as well as some headers. We expect other
cross-platform device libraries (DBCLs) to be added to this directory.
These DBCLs, will be maintained in the openmp trunk indefinitely.
Moving to an alternative repository such as clang would only be 
considered if other offloading models such as CUDA or HIP adopt the 
use of DBCLs for cross-platform portability. 

The libdevice Naming Convention:
--------------------------------
As the use of OpenMP offloading grows, we expect a significant number of new
DBCL libraries. Multiply this by the number of potential GPUs (sm_30, sm_60,
gfx802, gfx900, etc.) and then the number of potential variants such as debug
or special versions of the libraries (such reduced accuracy or fast versions).
It is certainly possible to store these bc files in the host linking
subdirectory.  That is typically ../lib.  The bc files in this directy must
be differentiated in the file name with the GPU name.
The current convention used for omptarget bc libraries is:

   ../lib/libomptarget-<archname>-<gpuname>.bc

For example, the current omptarget bc file for nvida sm_60 GPUs is typically
found at:

   ../lib/libomptarget-nvptx-sm_60.bc.

In order to better organize the large number of bc files expected, we propose
an extension to the current naming convention called the libdevice
naming convention.

Let's assume the the library name is X.  Then the compiler will first look
for libX-<archname>-<gpuname>.bc in the directory

   <LPATH>/libdevice/<gpuname>

If not found, the compiler will use the current convention and look for
libX-<archname>-<gpuname>.bc in the <LPATH> directory.  The directory <LPATH>
is first determined by the -L option, followed by directories specified by
LIBRARY_PATH environment variable, and lastly look in <CLANG_BIN>/../lib
where <CLANG_BIN> is the directory of the clang compiler executable.

Example of HOW to use DBCL:
---------------------------
Assume an openmp compile of foo.c and the target offload arch is sm_30.
We assume foo.c uses math functions by including math.h. 
The programmer must therefore compile with the -lm flag. 
The abbreviated clang command would be something like this.  

   clang -fopenmp ... -march=sm_30 -lm foo.c -o foo

By reusing the -l flag, there is nothing new about how external libraries
are specified to the compiler. However, there will be a new flag generated
for the clang -cc1 command for the device pass of the user source code. 
For example, if the GPU is sm_30 and the user specifies the -lm flag, 
the following clang cc1 option will be generated IF a DBCL is found:

   <CLANG_BIN>/clang -cc1 \
   -mlink-builtin-bitcode=<LPATH>/libdevice/sm_30/libm-nvptx-sm_30.bc

where <LPATH> is <CLANG_BIN>/../lib or a directory specified by user
 -L flag or the LIBRARY_PATH environment variable. The actual clang
 -cc1 command for a device pass has many other flags not shown above. 

Host-Only Libraries:
--------------------

Many user codes will have header files and corresponding -l link flags
where there is no device library or a device library has not yet been
implemented. The classic example of this is mpi. What will happen for
host-only libraries?  That is when the user code has #include <mpi.h>
and -lmpi was specified on the command line?

There are two scenarios:

  1. The users device code does not use mpi functions. There should be
     no warning or error messages. The driver will see the -lmpi and
     look for libmpi-<arch>-<gpu>.bc while constructing the device
     clang cc1 pass.  It will not find a DBCL and thus no option for
     -mlink-builtin-bitcode will be generated. No warning message should
     be generated for the use of the -lmpi flag by the user. 

  2. The user code accidentally uses an mpi function in their
     device code.  Where will there be warnings and where will be
     the error generated?  There will be no driver or device pass
     warning or error message. The error will occur when linking
     the device code.

FAQ:
---
Q: What happens when a user code uses a function in a library that is 
   only available on a certain GPU?  Example: fast_sqrt().  
A: The library implementor should surround the implementation with 
   the particulare macro ifdef for that GPU.  For nvptx they use
   __CUDA_ARCH__ .  For amdgcn, use __AMDGCN__.  
   #ifdef  __AMDGCN__  && ( __AMDGCN__ == 1000 )
   double fast_sqrt(double __a) { ... }
   #endif
   The user will get a GPU link failure (ldd on amdgcn, nvlink for nvidia)
   when he uses fast_sqrt. 
   A clever implementor would provide an alternative slow version
   for other GPUs. 
   #ifdef  __AMDGCN__  && ( __AMDGCN__ == 1000 )
   double fast_sqrt(double __a) { ... };
   #else
   #warning fast_sqrt not available on this platform, using sqrt.  
   double fast_sqrt(double __a) { sqrt(__a) };
   #endif
   This strategy encourages soft implementations that promote 
   portability. 

Q: Can a DBCL be built without a corresponding host link library? 
   e.g. -ldev-only
A: Currently NO.  We need a use case for device only functions. 
   OpenMP requires host fallback when offload devices are not 
   available. If there are special device only functions, it 
   would necessary to provide a host link-library version 
   whose functions are no-op or warning generators when the 
   OpenMP runtime falls back to the host. 


Construction of DBCL:
---------------------
The directory examples/libdevice/libm contains the source code and Makefile
to build and install libm.bc for many different GPUs. This example should
be used as a template for other library maintainers to build DBCLs. This 
example also demonstrates the construction of debug versions of DBCLs.

If we assume the compiler installation path is specified by the environment
variable HCC2, run these commands to build and install DBCLs for many GPUs:

    cp -rp $HCC2/examples/libdevice/libm /tmp
    cd /tmp/libm
    INSTALL_PATH=$HCC2 make
    INSTALL_PATH=$HCC2 sudo make install

The environment variables GFXLIST and NVPTXGPUS control the list of
GPU-specific DBCLs that the Makefile will build. See the Makefile for
the default lists. 

```
