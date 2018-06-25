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
//  1.4 Double Presicion Mathematical Functions
//  1.6 Double Presicion Intrinsics
#include <stdio.h>
#include <hip/hip_host_runtime_api.h>
#define N 10

__global__
void testDoubleMath(double *b)
{
  int i = blockIdx.x;
  double f = (double) i;
  double dummy;
  double dummy2;
  int idummy;
  if (i<N) {
    // 1.4 Single Presicion Mathematical Functions
    b[i] = acos(f);
    b[i] += acosh(f);
    b[i] += asin(f);
    b[i] += asinh(f);
    b[i] += atan(f);
    b[i] += atan2(f,f);
    b[i] += atanh(f);
    b[i] += cbrt(f);
    b[i] += ceil(f);
    b[i] += copysign(f, -f);
    b[i] += cos(f);
    b[i] += cosh(f);
    b[i] += cospi(f);
    b[i] += cyl_bessel_i0(f);
    b[i] += cyl_bessel_i1(f);
    b[i] += erf(f);
    b[i] += erfc(f);
    b[i] += erfcinv(f);
    b[i] += erfcxf(f);
    b[i] += erfinv(f);
    b[i] += exp(f);
    b[i] += exp10(f);
    b[i] += exp2(f);
    b[i] += expm1(f);
    b[i] += fabs(f);
    b[i] += fdim(f,f);
    b[i] += floor(f);
    b[i] += fma(f,f,f);
    b[i] += fmax(f,f);
    b[i] += fmin(f,f);
    b[i] += fmod(f,f);
    // b[i] += frexp(f, &idummy); // Fixme: Unsupported indirect call to __nv_frexp
    b[i] += hypot(f,f);
    b[i] += (double) ilogb(f);
    // b[i] += isfinite(f); // Fixme: Add to cuda_open headers
    // b[i] += isinf(f); // Fixme: Add to cuda_open headers
    // b[i] += isnan(f); // Fixme: Add to cuda_open headers
    b[i] += j0(f);
    b[i] += j1(f);
    // b[i] += jn(1,f); // Fixme: missing function _nv_jn
    b[i] += ldexp(f,1);
    b[i] += lgamma(f);
    b[i] += (double) llrint(f);
    b[i] += (double) llround(f);
    b[i] += log(f);
    b[i] += log10(f);
    b[i] += log1p(f);
    b[i] += log2(f);
    b[i] += logb(f);
    b[i] += (double) lrint(f);
    b[i] += (double) lround(f);
    // b[i] += modf(f, &dummy); // Fixme: missing function _nv_modf
    // b[i] += nan(""); // Fixme: add nan to cuda_open headers
    b[i] += nearbyint(f);
    b[i] += nextafter(f,f);
    // b[i] += norm(1,&f); // Fixme: missing function _nv_norm
    b[i] += norm3d(f,f,f);
    b[i] += norm4d(f,f,f,f);
    b[i] += normcdf(f);
    b[i] += normcdfinv(f);
    b[i] += pow(f,f);
    b[i] += rcbrt(f);
    b[i] += remainder(f,f);
    // b[i] += remquo(f,f, &idummy); // Fixme: Unsupported indirect call to  __nv_remquo
    b[i] += rhypot(f,f);
    b[i] += rint(f);
    // b[i] += rnorm(1, &f); // Fixme: missing function __nv_rnorm
    // b[i] += rnorm3d(f,f,f); // Fixme: missing function __nv_rnorm3d
    // b[i] += rnorm4d(f,f,f,f); // Fixme: missing function __nv_rnorm4d
    b[i] += round(f);
    b[i] += rsqrt(f);
    // b[i] += scalbln(f, 1); // Fixme: Unsupported indirect call to __nv_scalbn
    // b[i] += scalbn(f, 1);  // Fixme: Unsupported indirect call to __nv_scalbn
    // b[i] += signbit(f); // Fixme: Add to cuda_open headers
    b[i] += sin(f);
    // sincos(f, &dummy, &dummy2); // Fixme: Unsupported indirect call to __nv_sincos
    // sincospi(f, &dummy, &dummy2); // Fixme: Unsupported indirect call to __nv_sincospi
    b[i] += sinh(f);
    b[i] += sinpi(f);
    b[i] += sqrt(f);
    b[i] += tan(f);
    b[i] += tanh(f);
    b[i] += tgamma(f);
    b[i] += trunc(f);
    b[i] += y0(f);
    b[i] += y1(f);
    // b[i] += yn(1,f); // Fixme: missing function __nv_yn

   // 1.6 Single Presicion Intrinsics
    b[i] += __cosf(f);
    b[i] += __exp10f(f);
    b[i] += __expf(f);
    //    b[i] += __dadd_rd(f, f); // Fixme: missing function __nv_dadd_rd
    //    b[i] += __dadd_rn(f, f); // Fixme: missing function __nv_dadd_rn
    //    b[i] += __dadd_ru(f, f); // Fixme: missing function __nv_dadd_ru
    //    b[i] += __dadd_rz(f, f); // Fixme: missing function __nv_dadd_rz
    //    b[i] += __ddiv_rd(f, f); // Fixme: missing function __nv_ddiv_rd
    //    b[i] += __ddiv_rn(f, f); // Fixme: missing function __nv_ddiv_rn
    //    b[i] += __ddiv_ru(f, f); // Fixme: missing function __nv_ddiv_ru
    //    b[i] += __ddiv_rz(f, f); // Fixme: missing function __nv_ddiv_rz
    b[i] += __fdividef(f, f);
    // b[i] += __dmul_rd(f, f); // Fixme: missing function: __nv_dmul_rd
    // b[i] += __dmul_rn(f, f); // Fixme: missing function: __nv_dmul_rn
    // b[i] += __dmul_ru(f, f); // Fixme: missing function: __nv_dmul_ru
    // b[i] += __dmul_rz(f, f); // Fixme: missing function: __nv_dmul_rz
    // b[i] += __drcp_rd(f); // Fixme: missing function: __nv_drcp_rd
    // b[i] += __drcp_rn(f); // Fixme: missing function: __nv_drcp_rn
    // b[i] += __drcp_ru(f); // Fixme: missing function: __nv_drcp_ru
    // b[i] += __drcp_rz(f); // Fixme: missing function: __nv_drcp_rz
    // b[i] += __dsqrt_rd(f); // Fixme: missing function: __nv_dsqrt_rd
    // b[i] += __dsqrt_rn(f); // Fixme: missing function: __nv_dsqrt_rn
    // b[i] += __dsqrt_ru(f); // Fixme: missing function: __nv_dsqrt_ru
    // b[i] += __dsqrt_rz(f); // Fixme: missing function: __nv_dsqrt_rz

    // b[i] += __dsub_rd(f, f); // Fixme: missinf function: __nv_dsub_rd
    // b[i] += __dsub_rn(f, f); // Fixme: missinf function: __nv_dsub_rn
    // b[i] += __dsub_ru(f, f); // Fixme: missinf function: __nv_dsub_ru
    // b[i] += __dsub_rz(f, f); // Fixme: missinf function: __nv_dsub_rz

    // b[i] += __fma_rd(f, f, f); // Fixme: missing function __nv_fma_rd
    // b[i] += __fma_rn(f, f, f); // Fixme: missing function __nv_fma_rn
    // b[i] += __fma_ru(f, f, f); // Fixme: missing function __nv_fma_ru
    // b[i] += __fma_rz(f, f, f); // Fixme: missing function __nv_fma_rz
  }
}

void printArray(double *array)
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

  double hostArray[N];

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

  double *deviceArray;
  if (!hipCallSuccessful(hipMalloc((void **)&deviceArray, N*sizeof(double))))
  {
    printf("Unable to allocate device memory\n");
    return 0;
  }

  hipLaunchKernelGGL((testDoubleMath), dim3(N), dim3(1), 0, 0, deviceArray);

  if (hipCallSuccessful(hipMemcpy(hostArray,
                                     deviceArray,
                                     N * sizeof(double),
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
