//===----------------------------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is dual licensed under the MIT and the University of Illinois Open
// Source Licenses. See LICENSE.txt for details.
//
//===----------------------------------------------------------------------===//

#include <stdio.h>

#define N 10

__global__
void addVector(int *vectorA, int *vectorB, int*vectorC)
{
  int i = blockIdx.x;
  if (i<N) {
    vectorC[i] = vectorA[i] + vectorB[i];
  }
}

void printVector(int *vector)
{
  printf("[");
  bool first = true;
  for (int i = 0; i<N; ++i)
  {
    if (first)
    {
      printf("%d", vector[i]);
      first = false;
    }
    else
    {
      printf(", %d", vector[i]);
    }
  }
  printf("]");
}

void printCudaError(cudaError_t error)
{
  printf("Cuda Error: %s\n", cudaGetErrorString(error));
}

void randomizeVector(int *vector)
{
  for (int i = 0; i < N; ++i)
    vector[i] = rand() % 10;
}

void clearVector(int *vector)
{
  for (int i = 0; i < N; ++i)
    vector[i] = 0;
}
bool cudaCallSuccessful(cudaError_t error)
{
  if (error != cudaSuccess)
    printCudaError(error);
  return error == cudaSuccess;
}

bool deviceCanCompute(int deviceID)
{
  bool canCompute = false;
  cudaDeviceProp deviceProp;
  bool devicePropIsAvailable =
    cudaCallSuccessful(cudaGetDeviceProperties(&deviceProp, deviceID));
  if (devicePropIsAvailable)
  {
    canCompute = deviceProp.computeMode != cudaComputeModeProhibited;
    if (!canCompute)
      printf("Compute mode is prohibited\n");
  }
  return canCompute;
}

bool deviceIsAvailable(int *deviceID)
{
  return cudaCallSuccessful(cudaGetDevice(deviceID));
}

// We always use device 0
bool haveComputeDevice()
{
  int deviceID = 0;
  return deviceIsAvailable(&deviceID) && deviceCanCompute(deviceID);
}

int main()
{
  int hostSrcVecA[N];
  int hostSrcVecB[N];
  int hostDstVec[N];

  if (!haveComputeDevice())
  {
    printf("No compute device available\n");
    return 0;
  }

  randomizeVector(hostSrcVecA);
  randomizeVector(hostSrcVecB);
  clearVector(hostDstVec);

  printf("  A: ");
  printVector(hostSrcVecA);
  printf("\n  B: ");
  printVector(hostSrcVecB);
  printf("\n");

  int *deviceSrcVecA = NULL;
  int *deviceSrcVecB = NULL;
  int *deviceDstVec = NULL;

  bool vectorAAllocated =
    cudaCallSuccessful(cudaMalloc((void **)&deviceSrcVecA, N*sizeof(int)));
  bool vectorBAllocated =
    cudaCallSuccessful(cudaMalloc((void **)&deviceSrcVecB, N*sizeof(int)));
  bool vectorCAllocated =
    cudaCallSuccessful(cudaMalloc((void **)&deviceDstVec, N*sizeof(int)));

  if (vectorAAllocated && vectorBAllocated && vectorCAllocated)
  {
    bool copiedSrcVecA =
      cudaCallSuccessful(cudaMemcpy(deviceSrcVecA, hostSrcVecA,
                                    N * sizeof(int), cudaMemcpyHostToDevice));
    bool copiedSrcVecB =
      cudaCallSuccessful(cudaMemcpy(deviceSrcVecB, hostSrcVecB,
                                    N * sizeof(int), cudaMemcpyHostToDevice));

    if (copiedSrcVecA && copiedSrcVecB)
    {
      addVector<<<N, 1>>>(deviceSrcVecA, deviceSrcVecB, deviceDstVec);

      if (cudaCallSuccessful(cudaMemcpy(hostDstVec,
                                        deviceDstVec,
                                        N * sizeof(int),
                                        cudaMemcpyDeviceToHost)))
      {
        printf("Sum: ");
        printVector(hostDstVec);
        printf("\n");
      }
      else
      {
        printf("Unable to copy memory from device to host\n");
      }
    }
  }

  if (vectorAAllocated)
    cudaFree(deviceSrcVecA);
  if (vectorBAllocated)
    cudaFree(deviceSrcVecB);
  if (vectorCAllocated)
    cudaFree(deviceDstVec);

  return 0;
}
