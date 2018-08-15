HCC2 - Examples to demonstrate use of OpenMP
==============================================

The HCC2 compiler supports several accelerated programming models. OpenMP is one of these models. 

Examples in this directory demonstrate how to use hcc2 to compile OpenMP 4.5 sources and execute the binaries on GPU.

Cd to a specific example folder and run the following commands to build and execute:

```
make
make run
```
There are many other make targets to show different ways to build the binary. Run ```make help``` to see all the possible demos as Makefile targets.

E.g. to run with some debug output set OFFLOAD_DEBUG variable:

```
env OFFLOAD_DEBUG=1 make
env OFFLOAD_DEBUG=1 make run
```

To compile and run the reduction example on Fiji card manually for x86_64 machine:

```
env LIBRARY_PATH=/opt/rocm/hcc2/lib/libdevice:/opt/rocm/hcc2/lib:/opt/rocm/libamdgcn/gfx803/lib \
PATH=/opt/rocm/hcc2/bin:$PATH \
/opt/rocm/hcc2/bin/clang -O3 -target x86_64-pc-linux-gnu -fopenmp -fopenmp-targets=amdgcn--cuda \
                         --cuda-gpu-arch=gfx803 -I/opt/rocm/hcc2/include  -L/opt/rocm/hcc2/lib \
                         -L/opt/rocm/hcc2/lib/libdevice reduction.c -o reduction
env LD_LIBRARY_PATH=/opt/rocm/hcc2/lib  ./reduction
The result is correct = 499999500000!
```

## Bundling

Even though only a single offload target is currently supported, you can still see how bundling works.

Except for the final binary, all intermediate objects are bundles.
For example, run the command:

```
cd vmulsum
make .ll
```

This will create one LLVM IR .ll file for each of the sources. However each of these is really a BUNDLE of 2 LLVM IR .ll files; one for host and one for the target offload. You can see these by editing any of the files, or you can unbundle them unbundle.sh utility script as follows:

```
/opt/rocm/hcc2/bin/unbundle.sh vmul.ll
```

This will create host and device files.
