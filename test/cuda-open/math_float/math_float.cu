// MIT License
//
// Copyright (c) 2018 Advanced Micro Devices, Inc. All Rights Reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// These test only check if the code compiles, we don't test
// functionality yet.
// Reference: Cuda Toolkit v 9.2.88
//  1.3 Single Presicion Mathematical Functions
//  1.5 Single Presicion Intrinsics
#include <stdio.h>
#include <hip/hip_host_runtime_api.h>
#define N 10

__global__
void testFloatMath(float *b)
{
  int i = blockIdx.x;
  float f = (float) i;
  float dummy;
  float dummy2;
  int idummy;
  if (i<N) {
    // 1.3 Single Presicion Mathematical Functions
    b[i] = acosf(f);
    b[i] += acoshf(f);
    b[i] += asinf(f);
    b[i] += asinhf(f);
    b[i] += atan2f(f,f);
    b[i] += atanf(f);
    b[i] += atanhf(f);
    b[i] += cbrtf(f);
    b[i] += ceilf(f);
    //b[i] += copysign(f, -f); // Fixme: Add to cuda_open headers
    b[i] += cosf(f);
    b[i] += coshf(f);
    b[i] += cospif(f);
    b[i] += cyl_bessel_i0f(f);
    b[i] += cyl_bessel_i1f(f);
    b[i] += erfcf(f);
    b[i] += erfcinvf(f);
    b[i] += erfcxf(f);
    b[i] += erff(f);
    b[i] += erfinvf(f);
    b[i] += exp10f(f);
    b[i] += exp2f(f);
    b[i] += expf(f);
    b[i] += expm1f(f);
    b[i] += fabsf(f);
    b[i] += fdimf(f,f);
    b[i] += fdividef(f,f);
    b[i] += floorf(f);
    b[i] += fmaf(f,f,f);
    b[i] += fmaxf(f,f);
    b[i] += fminf(f,f);
    b[i] += fmodf(f,f);
    // b[i] += frexpf(f, &idummy); // Fixme: missing function _nv_frexpf
    b[i] += hypotf(f,f);
    b[i] += (float) ilogbf(f);
    b[i] += isfinite(f);
    b[i] += isinf(f);
    b[i] += isnan(f);
    b[i] += j0f(f);
    b[i] += j1f(f);
    // b[i] += jnf(1,f); // Fixme: missing function _nv_jnf
    b[i] += ldexpf(f,1);
    b[i] += lgammaf(f);
    b[i] += (float) llrintf(f);
    b[i] += (float) llroundf(f);
    b[i] += log10f(f);
    b[i] += log1pf(f);
    b[i] += log2f(f);
    b[i] += logbf(f);
    b[i] += logf(f);
    b[i] += (float) lrintf(f);
    b[i] += (float) lroundf(f);
    // b[i] += modff(f, &dummy); // Fixme: missing function _nv_modff
    // b[i] += nanf(""); // Fixme: Add to cuda_open headers
    b[i] += nearbyintf(f);
    b[i] += nextafterf(f,f);
    b[i] += norm3df(f,f,f);
    b[i] += norm4df(f,f,f,f);
    b[i] += normcdff(f);
    b[i] += normcdfinvf(f);
    //    b[i] += normf(1,&f); // Fixme: missing function __nv_normf
    b[i] += powf(f,f);
    b[i] += rcbrtf(f);
    b[i] += remainderf(f,f);
    // b[i] += remquof(f,f, &idummy); // Fixme: missing function __nv_remquof
    b[i] += rhypotf(f,f);
    b[i] += rintf(f);
    // b[i] += rnorm3df(f,f,f); // Fixme: missing function __nv_rnorm3df
    // b[i] += rnorm4df(f,f,f,f); // Fixme: missing function __nv_rnorm4df
    // b[i] += rnormf(1, &f); // Fixme: missing function __nv_rnormf
    b[i] += roundf(f);
    b[i] += rsqrtf(f);
    //b[i] += scalblnf(f, 1); // Fixme: missing function __nv_scalbnf
    //b[i] += scalbnf(f, 1);  // Fixme: missing function __nv_scalbnf
    b[i] += signbit(f);
    // sincosf(f, &dummy, &dummy2); // Fixme: missing function __nv_sincosf
    // sincospif(f, &dummy, &dummy2); // Fixme: missing function __nv_sincospif
    b[i] += sinf(f);
    b[i] += sinhf(f);
    b[i] += sinpif(f);
    b[i] += sqrtf(f);
    b[i] += tanf(f);
    b[i] += tanhf(f);
    b[i] += tgammaf(f);
    b[i] += truncf(f);
    b[i] += y0f(f);
    b[i] += y1f(f);
    // b[i] += ynf(1,f); // Fixme: missing function __nv_ynf

   // 1.5 Single Presicion Intrinsics

    b[i] += __cosf(f);
    b[i] += __exp10f(f);
    b[i] += __expf(f);
    //    b[i] += __fadd_rd(f, f); // Fixme: missing function __nv_fadd_rd
    //    b[i] += __fadd_rn(f, f); // Fixme: missing function __nv_fadd_rn
    //    b[i] += __fadd_ru(f, f); // Fixme: missing function __nv_fadd_ru
    //    b[i] += __fadd_rz(f, f); // Fixme: missing function __nv_fadd_rz
    //    b[i] += __fdiv_rd(f, f); // Fixme: missing function __nv_fdiv_rd
    //    b[i] += __fdiv_rn(f, f); // Fixme: missing function __nv_fdiv_rn
    //    b[i] += __fdiv_ru(f, f); // Fixme: missing function __nv_fdiv_ru
    //    b[i] += __fdiv_rz(f, f); // Fixme: missing function __nv_fdiv_rz
    b[i] += __fdividef(f, f);
    // b[i] += __fmaf_rd(f, f, f); // Fixme: missing function __nv_fmaf_rd
    // b[i] += __fmaf_rn(f, f, f); // Fixme: missing function __nv_fmaf_rn
    // b[i] += __fmaf_ru(f, f, f); // Fixme: missing function __nv_fmaf_ru
    // b[i] += __fmaf_rz(f, f, f); // Fixme: missing function __nv_fmaf_rz
    // b[i] += __fmul_rd(f, f); // Fixme: missing function: __nv_fmul_rd
    // b[i] += __fmul_rn(f, f); // Fixme: missing function: __nv_fmul_rn
    // b[i] += __fmul_ru(f, f); // Fixme: missing function: __nv_fmul_ru
    // b[i] += __fmul_rz(f, f); // Fixme: missing function: __nv_fmul_rz
    // b[i] += __frcp_rd(f); // Fixme: missing function: __nv_frcp_rd
    // b[i] += __frcp_rn(f); // Fixme: missing function: __nv_frcp_rn
    // b[i] += __frcp_ru(f); // Fixme: missing function: __nv_frcp_ru
    // b[i] += __frcp_rz(f); // Fixme: missing function: __nv_frcp_rz
    // b[i] += __fsqrt_rd(f); // Fixme: missing function: __nv_fsqrt_rd
    // b[i] += __fsqrt_rn(f); // Fixme: missing function: __nv_fsqrt_rn
    // b[i] += __fsqrt_ru(f); // Fixme: missing function: __nv_fsqrt_ru
    // b[i] += __fsqrt_rz(f); // Fixme: missing function: __nv_fsqrt_rz
    // b[i] += __fsub_rd(f, f); // Fixme: missinf function: __nv_fsub_rd
    b[i] += __log10f(f);
    b[i] += __log2f(f);
    b[i] += __logf(f);
    b[i] += __powf(f, f);
    b[i] += __saturatef(f);
    // __sincosf(f, &dummy, &dummy2); // Fixme: indirect call error to __nv_fast_sincosf
    b[i] += __sinf(f);
    b[i] += __tanf(f);
  }
}

void printArray(float *array)
{
  printf("[");
  bool first = true;
  for (int i = 0; i<N; ++i)
  {
    if (first)
    {
      printf("%f", array[i]);
      first = false;
    }
    else
    {
      printf(", %f", array[i]);
    }
  }
  printf("]");
}

void printHipError(hipError_t error)
{
  printf("Hip Error: %s\n", hipGetErrorString(error));
}

bool hipCallSuccessful(hipError_t error)
{
  if (error != hipSuccess)
    printHipError(error);
  return error == hipSuccess;
}

bool deviceCanCompute(int deviceID)
{
  bool canCompute = false;
  hipDeviceProp_t deviceProp;
  bool devicePropIsAvailable =
    hipCallSuccessful(hipGetDeviceProperties(&deviceProp, deviceID));
  if (devicePropIsAvailable)
  {
    canCompute = deviceProp.computeMode != hipComputeModeProhibited;
    if (!canCompute)
      printf("Compute mode is prohibited\n");
  }
  return canCompute;
}

bool deviceIsAvailable(int *deviceID)
{
  return hipCallSuccessful(hipGetDevice(deviceID));
}

// We always use device 0
bool haveComputeDevice()
{
  int deviceID = 0;
  return deviceIsAvailable(&deviceID) && deviceCanCompute(deviceID);
}

int main()
{

  float hostArray[N];

  if (!haveComputeDevice())
  {
    printf("No compute device available\n");
    return 0;
  }

  for (int i = 0; i<N; ++i)
    hostArray[i] = 0.0;

  printf("Array content before kernel:\n");
  printArray(hostArray);
  printf("\n");

  float *deviceArray;
  if (!hipCallSuccessful(hipMalloc((void **)&deviceArray, N*sizeof(float))))
  {
    printf("Unable to allocate device memory\n");
    return 0;
  }

  hipLaunchKernelGGL((testFloatMath), dim3(N), dim3(1), 0, 0, deviceArray);

  if (hipCallSuccessful(hipMemcpy(hostArray,
                                     deviceArray,
                                     N * sizeof(float),
                                     hipMemcpyDeviceToHost)))
  {
    printf("Array content after kernel:\n");
    printArray(hostArray);
    printf("\n");
  }
  else
  {
    printf("Unable to copy memory from device to host\n");
  }

  hipFree(deviceArray);
  return 0;
}
