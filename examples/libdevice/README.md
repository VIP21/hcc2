```
This directory contains examples of how to build Device BC Libraries, DBCLs. 

The DBCL Concept:
----------------
The purpose of a DBCL is to support the desire to have the same host and 
device source code that reference functions from external libraries.
DBCLs allow the use of existing header files for both the host and device
passes without changing existing header files. This removes the need to
maintain duplicate header files.  Also, the DBCL removes the overhead
of compiling supplemental device header files with architecture-specific
implementations of all functions in the library. Currently, each device
compilation for CUDA and HIP requires this extra overhead.  Lastly, the DBCL
provides a method for end-users or third party library maintainers to provide
their own pre-compiled device libraries with GPU-specific optimizations in a
way that encourages portability across hardware platforms.  

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

Like host implementations of libm.so and libm.a, the DBCL libm.bc
must be built ahead of time. They are typically stored as part of the 
compiler installation.  Each DBCL is built for a specific GPU so the 
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

A DBCL is enabled by the clang cc1 flag -mlink-builtin-bitcode.  The 
bc file specified by -mlink-builtin-bitcode will be linked immediately after 
clang compilation while the generated LLVM-IR is still in memory and before
the source module's LLVM-IR is written to disk for the compile phase.
This is NOT an additional clang driver phase, step, or command.  This is part
of the clang cc1 command for the compile phase.  So there is no change to
the internal clang driver phase actions other than a new cc1 flag that is
constructed as a result of the user specified -lm flag. This explains the
minor drawback of DBCLs. The -lX flag will now be necessary as both a compile
flag and link flag. The tradeoff is that only user-specified DBCLs are linked
in memory at the end of the compile phase.

The internal clang compiler source code to generate the -mlink-builtin-bitcode
flag could be found in clang/lib/Driver/ToolChains/Clang.cpp. This feature
is only available on HCC2 0.5-4 and beyond. 

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

The clang cc1 command generated by the OpenMP driver for the sm_30 device pass 
will add the -mlink-builtin-bitcode flag as a result of the -lm flag. 

<CLANG_BIN>/clang -cc1 -mlink-built-in-bitcode=<LPATH>/libdevice/sm_30/libm-nvptx-sm_30.bc

where <LPATH> is <CLANG_BIN>/../lib or a directory specified by user -L flag
or the LIBRARY_PATH environment variable. The actual cc1 command has 
many other flags not shown here. 

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
