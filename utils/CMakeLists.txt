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
add_custom_target(hcc2utils ALL)

find_package(LLVM QUIET CONFIG
  PATHS
  $ENV{HCC2}
  /usr/lib/rocm/hcc2
  /opt/rocm/hcc2
  NO_DEFAULT_PATH
)

if (LLVM_DIR)
  if("{CMAKE_INSTALL_PREFIX}" STREQUAL "")
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

string(LENGTH ${LLVM_PACKAGE_VERSION} vlen)
math(EXPR vstart "${vlen}-5")
string(SUBSTRING ${LLVM_PACKAGE_VERSION} ${vstart} 5 version_str)

#FIXME:  This could be a loop
add_custom_command( OUTPUT cloc.sh
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/cloc.sh ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/cloc.sh)
# edit in place to preserve permissions
add_custom_command( OUTPUT cloc.sh.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/" ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh > cloc.sh.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh)

add_custom_command( OUTPUT mymcpu
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/mymcpu ${CMAKE_CURRENT_BINARY_DIR}/mymcpu
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/mymcpu)
add_custom_command( OUTPUT mymcpu.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/" ${CMAKE_CURRENT_BINARY_DIR}/mymcpu > mymcpu.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/mymcpu)

add_custom_command( OUTPUT hcc2version
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/hcc2version ${CMAKE_CURRENT_BINARY_DIR}/hcc2version
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/hcc2version)
add_custom_command( OUTPUT hcc2version.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/" ${CMAKE_CURRENT_BINARY_DIR}/hcc2version > hcc2version.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/hcc2version)

add_custom_target(utils_scripts ALL DEPENDS cloc.sh.phantom mymcpu.phantom hcc2version.phantom)

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
   ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh
   ${CMAKE_CURRENT_BINARY_DIR}/mymcpu
   ${CMAKE_CURRENT_BINARY_DIR}/hcc2version
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/mygpu
   ${CMAKE_CURRENT_SOURCE_DIR}/bin/make_header_from_ll_defines.sh
   ${CMAKE_CURRENT_BINARY_DIR}/prepare-builtins
   DESTINATION "bin")

install(FILES
/opt/rocm/hsa/include/hsa/amd_hsa_kernel_code.h
/opt/rocm/hsa/include/hsa/amd_hsa_signal.h
/opt/rocm/hsa/include/hsa/hsa.h
/opt/rocm/hsa/include/hsa/amd_hsa_queue.h
/opt/rocm/hsa/include/hsa/amd_hsa_common.h
/opt/rocm/hsa/include/hsa/amd_hsa_elf.h
/opt/rocm/hcc/include/device_amd_hsa.h
/opt/rocm/hcc/include/hc_am.hpp
/opt/rocm/hcc/include/hc.hpp
/opt/rocm/hcc/include/hc_defines.h
/opt/rocm/hcc/include/ockl_hsa.h
/opt/rocm/hcc/include/ockl.h
/opt/rocm/hcc/include/ocml.h
/opt/rocm/hcc/include/kalmar_exception.h
/opt/rocm/hcc/include/kalmar_index.h
        DESTINATION include COMPONENT hcc2utils)

# /opt/rocm/hsa/include/hsa/hsa_ext_debugger.h
# /opt/rocm/hsa/include/hsa/amd_hsa_tools_interfaces.h
# /opt/rocm/hsa/include/hsa/hsa_ext_profiler.h
install(FILES
/opt/rocm/hsa/include/hsa/hsa_api_trace.h
/opt/rocm/hsa/include/hsa/amd_hsa_kernel_code.h
/opt/rocm/hsa/include/hsa/amd_hsa_signal.h
/opt/rocm/hsa/include/hsa/hsa_ven_amd_aqlprofile.h
/opt/rocm/hsa/include/hsa/hsa_ext_finalize.h
/opt/rocm/hsa/include/hsa/hsa.h
/opt/rocm/hsa/include/hsa/amd_hsa_common.h
/opt/rocm/hsa/include/hsa/hsa_ext_image.h
/opt/rocm/hsa/include/hsa/hsa_ext_amd.h
/opt/rocm/hsa/include/hsa/amd_hsa_elf.h
/opt/rocm/hsa/include/hsa/hsa_ven_amd_loader.h
/opt/rocm/hsa/include/hsa/amd_hsa_queue.h
/opt/rocm/hsa/include/hsa/Brig.h
        DESTINATION include/hsa COMPONENT hcc2utils)

