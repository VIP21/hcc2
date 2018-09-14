//===--------- libm/libm-amdgcn.h -----------------------------------------===//
//
//                The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef __LIBM_AMDGCN_H__
#define __LIBM_AMDGCN_H__

float __ocml_sin_f32(float x);
double __ocml_sin_f64(double x);

float __ocml_sqrt_f32(float x);
double __ocml_sqrt_f64(double x);

#endif // __LIBM_AMDGCN_H__
