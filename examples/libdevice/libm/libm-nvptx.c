//===--------- libm/libm-nvptx.c ------------------------------------------===//
//
//                The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <math.h>
#include "libm-nvptx.h"

double sin(double __a) { return __nv_sin(__a); }
float sinf(float __a) { return __nv_sinf(__a); }

double sqrt(double __a) { return __nv_sqrt(__a); }
float sqrtf(float __a) { return __nv_sqrtf(__a); }
