##===----------------------------------------------------------------------===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is dual licensed under the MIT and the University of Illinois Open
# Source Licenses. See LICENSE.txt for details.
##===----------------------------------------------------------------------===##
#
# utils/CMakeLists.txt
# Written by Greg Rodgers (Gregory.Rodgers@amd.com)
#
##===----------------------------------------------------------------------===##

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  project(hcc2utils)
endif()

find_package(LLVM QUIET CONFIG
  PATHS
  $ENV{HCC2}
  /usr/lib/rocm/hcc2
  /opt/rocm/hcc2
  NO_DEFAULT_PATH
)

if (LLVM_DIR)
  if(NOT ${CMAKE_INSTALL_PREFIX})
     set(CMAKE_INSTALL_PREFIX ${LLVM_INSTALL_PREFIX})
  endif()
  message("")
  message(STATUS "HCC2 LLVM Found!")
  message(STATUS "     LLVM_PACKAGE_VERSION:     ${LLVM_PACKAGE_VERSION} ")
  message(STATUS "     LLVM_DIR:                 ${LLVM_DIR}")
  message(STATUS "     LLVM LLVM_INSTALL_PREFIX: ${LLVM_INSTALL_PREFIX}")
  message(STATUS "     CMAKE_INSTALL_PREFIX:     ${CMAKE_INSTALL_PREFIX}")
  message("")
else()
  message("")
  message("  ERROR:  Could not find an HCC2 version of LLVM.")
  message("          You must build HCC2 before building HCC2 utils")
  message("")
  error(" Could not find an HCC2 version of LLVM.")
endif()

set(HCC2_DIR_FOUND ${LLVM_DIR})
set(HCC2_INSTALL_PREFIX ${LLVM_INSTALL_PREFIX})
set(HCC2_MAIN_INCDIR ${LLVM_BUILD_MAIN_INCLUDE_DIR})
set(HCC2_BINDIR ${HCC2_INSTALL_PREFIX}/bin)
set(HCC2_INCDIR ${HCC2_INSTALL_PREFIX}/include)
set(HCC2_LIBDIR ${HCC2_INSTALL_PREFIX}/lib)
set(HCC2_LIBS
  ${HCC2_LIBDIR}/libLLVMBitWriter.a
  ${HCC2_LIBDIR}/libLLVMBitReader.a
  ${HCC2_LIBDIR}/libLLVMObject.a
  ${HCC2_LIBDIR}/libLLVMCore.a
  ${HCC2_LIBDIR}/libLLVMDemangle.a
  ${HCC2_LIBDIR}/libLLVMMC.a
  ${HCC2_LIBDIR}/libLLVMMCParser.a
  ${HCC2_LIBDIR}/libLLVMSupport.a
  ${HCC2_LIBDIR}/libLLVMBinaryFormat.a )
mark_as_advanced(
  HCC2_DIR_FOUND
  HCC2_INSTALL_PREFIX
  HCC2_BINDIR
  HCC2_INCDIR
  HCC2_LIBDIR
  HCC2_MAIN_INCDIR)

add_custom_target(hcc2utils ALL)

# We need prepare-builtins in the HCC2 distribution to build bc libs for components
list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(AddLLVM)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-rtti")
add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIR})
add_executable(prepare-builtins ${CMAKE_CURRENT_SOURCE_DIR}/src/prepare-builtins.cpp)
llvm_map_components_to_libnames(llvm_libs support core bitreader bitwriter)
target_link_libraries(prepare-builtins ${llvm_libs})

install(PROGRAMS 
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/bundle.sh
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/unbundle.sh
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/cloc.sh
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/mymcpu
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/mygpu
   ${CMAKE_CURRENT_BINARY_DIR}/prepare-builtins
   DESTINATION "bin")

install(FILES
/opt/rocm/include/amd_hsa_kernel_code.h
/opt/rocm/include/amd_hsa_signal.h
/opt/rocm/include/hsa.h
/opt/rocm/include/device_amd_hsa.h
/opt/rocm/include/amd_hsa_common.h
/opt/rocm/include/ockl_hsa.h
/opt/rocm/include/amd_hsa_elf.h
/opt/rocm/include/ockl.h
/opt/rocm/include/amd_hsa_queue.h
/opt/rocm/include/ocml.h
        DESTINATION include COMPONENT hcc2utils)

install(FILES
/opt/rocm/hsa/include/hsa/hsa_api_trace.h
/opt/rocm/hsa/include/hsa/hsa_ext_debugger.h
/opt/rocm/hsa/include/hsa/amd_hsa_kernel_code.h
/opt/rocm/hsa/include/hsa/amd_hsa_signal.h
/opt/rocm/hsa/include/hsa/hsa_ven_amd_aqlprofile.h
/opt/rocm/hsa/include/hsa/hsa_ext_finalize.h
/opt/rocm/hsa/include/hsa/hsa.h
/opt/rocm/hsa/include/hsa/amd_hsa_tools_interfaces.h
/opt/rocm/hsa/include/hsa/amd_hsa_common.h
/opt/rocm/hsa/include/hsa/hsa_ext_image.h
/opt/rocm/hsa/include/hsa/hsa_ext_amd.h
/opt/rocm/hsa/include/hsa/amd_hsa_elf.h
/opt/rocm/hsa/include/hsa/hsa_ext_profiler.h
/opt/rocm/hsa/include/hsa/hsa_ven_amd_loader.h
/opt/rocm/hsa/include/hsa/amd_hsa_queue.h
/opt/rocm/hsa/include/hsa/Brig.h
        DESTINATION include/hsa COMPONENT hcc2utils)
