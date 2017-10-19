HCC2 - Examples to demonstrate use of CUDA Clang
================================================

The HCC2 compiler supports several accelerated programming models.
HCC2 includes a CUDA front end. This allows CUDA code to be compiled
by the HCC2 compiler, which will produce a binary containing code
generated for the specified target GPU, as well as host code. The
examples in this directory demonstrate how to use HCC2 to compile CUDA
code to an executable.

Currently the executable code works only with Nvidia GPUs, since this
is the only platform with a host runtime.

To compile an example simply run 'make', and to run 'make run'. For
more information and other options use 'make help'

Examples:
vectorAdd - adds two vectors
matrixmul - simple implementation of matrix multiplication

### About this file

This is the README.md file for
https:/github.com/ROCM-Developer-Tools/hcc2/examples/cudaclang

