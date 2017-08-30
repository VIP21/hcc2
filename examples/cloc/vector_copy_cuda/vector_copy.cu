#include <cuda_runtime.h>

extern "C" __global__ void vector_copy(__device__ int *in, __device__ int *out) {
  int id = blockIdx.x; 
  out[id] = in[id];
}
