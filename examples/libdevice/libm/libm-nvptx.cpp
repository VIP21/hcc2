//===--------- libm/libm-nvptx.cpp ----------------------------------------===//
//
//                The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <cmath>
#include "libm-nvptx.h"
#ifdef __cplusplus

float sin(float __a) { return __nv_sinf(__a); }

float sqrt(float __a) { return __nv_sqrtf(__a); }

#endif
