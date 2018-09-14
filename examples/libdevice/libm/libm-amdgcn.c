//===--------- libm/libm-amdgcn.c -----------------------------------------===//
//
//                The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <math.h>
#include "libm-amdgcn.h"

double sin(double x) { return __ocml_sin_f64(x); }
float sinf(float x) { return __ocml_sin_f32(x); }

double sqrt(double x) { return __ocml_sin_f64(x); }
float sqrtf(float x) { return __ocml_sin_f32(x); }

