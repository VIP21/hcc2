//===--------- libm/libm-amdgcn.cpp ---------------------------------------===//
//
//                The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <cmath>
#include "libm-amdgcn.h"

float sin(float x) { return __ocml_sin_f32(x); }

float sqrt(float x) { return __ocml_sqrt_f32(x); }
