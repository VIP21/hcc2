HCC2 - Examples to demonstrate use of OpenMP
==============================================

The HCC2 compiler supports several accelerated programming models. OpenMP is one of these models. Examples in this directory demonstrate how to use hcc2 to compile and execute on GPU OpenMP 4.5 code.

Cd to a specific example folder and run the following commands to build and execute:

make
make run

There are many other make targets to show different ways to build the binary. Run "make help" to see all the possible demos as Makefile targets.


Bundling!

Even though only a single offload target is currently supported, you can still see how bundling works.

Except for the final binary, all intermediate objects are bundles.
For example, run the command:

cd vmulsum
make .ll

This will create one LLVM IR .ll file for each of the sources. However each of these is really a BUNDLE of 2 LLVM IR .ll files; one for host and one for the target offload. You can see these by editing any of the files, or you can unbundle them unbundle.sh utility script as follows:

/opt/rocm/hcc2/bin/unbundle.sh vmul.ll

The unbundle will create host and device files
