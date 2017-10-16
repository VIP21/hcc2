cmake_minimum_required( VERSION 3.0 )
project (HCC)

include(GNUInstallDirs)

set(HCC2 $ENV{HCC2})
if (NOT HCC2) 
   set(HCC2 "/opt/rocm/hcc2")
endif()
MESSAGE("-- Using HCC2 path: ${HCC2}")

SET(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/scripts/cmake")
MESSAGE("-- Module path: ${CMAKE_MODULE_PATH}")

# set as release build by default
IF (NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: Release Debug" FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

include (MCWAMP)

# obtain specific information about llvm setup
SET(LOCAL_LLVM_INCLUDE compiler/include)

# setup compilation environment
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_BINARY_DIR}/bin" )
set(LIBRARY_OUTPUT_PATH "${CMAKE_BINARY_DIR}/lib" )

SET(PROJ_SEARCH_PATH "${PROJECT_BINARY_DIR}/include" "${PROJECT_SOURCE_DIR}/include" "${PROJECT_SOURCE_DIR}/${LOCAL_LLVM_INCLUDE}") 
include_directories( ${PROJ_SEARCH_PATH} )

LINK_DIRECTORIES( ${LLVM_LIB_DIR} )


#################
# Detect ROCm
#################

# ROCm external dependencies
set (ROCM_ROOT "/opt/rocm" CACHE PATH "ROCM runtime path")

find_path(HSA_HEADER hsa/hsa.h
  HINTS
    ${HSA_HEADER_DIR}
  PATHS
    ${ROCM_ROOT}/include
)

if (NOT HSA_HEADER)
  MESSAGE("HSA header not found. Use -DHSA_HEADER=<path_to_hsa.h>.")
endif (NOT HSA_HEADER)

find_library(HSA_LIBRARY hsa-runtime64
  HINTS
    ${HSA_LIBRARY_DIR}
  PATHS
    ${ROCM_ROOT}/lib
)

if (NOT HSA_LIBRARY)
  MESSAGE("HSA runtime library not found. Use -DHSA_LIBRARY=<path_to_libhsa-runtime64.so>.")
endif (NOT HSA_LIBRARY)

add_library(hsa-runtime64 SHARED IMPORTED GLOBAL)

set_target_properties(hsa-runtime64 PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${HSA_HEADER}"
  IMPORTED_LOCATION "${HSA_LIBRARY}"
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${HSA_HEADER}"
)

# display ROCm information
MESSAGE("")
MESSAGE("ROCm INFORMATION:")
MESSAGE("HSA_HEADER_DIR = ${HSA_HEADER_DIR}, actually found at: ${HSA_HEADER}")
MESSAGE("HSA_LIBRARY_DIR = ${HSA_LIBRARY_DIR}, actually found at: ${HSA_LIBRARY}")

################
# Detect CodeXL Activity Logger
################
if (USE_CODEXL_ACTIVITY_LOGGER EQUAL 1)

find_path(CODEXL_ACTIVITY_LOGGER_HEADER NAMES CXLActivityLogger.h PATHS ${CODEXL_ACTIVITY_LOGGER_HEADER_DIR} ${ROCM_ROOT}/profiler/CXLActivityLogger/include NO_DEFAULT_PATH)
find_path(CODEXL_ACTIVITY_LOGGER_HEADER NAMES CXLActivityLogger.h)

if (NOT CODEXL_ACTIVITY_LOGGER_HEADER)
  MESSAGE("CodeXL header not found. use -DCODEXL_ACTIVITY_LOGGER_HEADER_DIR=<path_to_CXLActivityLogger.h>.")
endif (NOT CODEXL_ACTIVITY_LOGGER_HEADER)

find_path(CODEXL_ACTIVITY_LOGGER_LIBRARY NAMES libCXLActivityLogger.so PATHS ${CODEXL_ACTIVITY_LOGGER_LIBRARY_DIR} ${ROCM_ROOT}/profiler/CXLActivityLogger/bin/x86_64 NO_DEFAULT_PATH)
find_path(CODEXL_ACTIVITY_LOGGER_LIBRARY NAMES libCXLActivityLogger.so)

if (NOT CODEXL_ACTIVITY_LOGGER_LIBRARY)
  MESSAGE("CodeXL Activity Logger library not found. Use -DCODEXL_ACTIVITY_LOGGER_LIBRARY_DIR=<path_to_libCXLActivityLogger.so>.")
endif (NOT CODEXL_ACTIVITY_LOGGER_LIBRARY)

# display CodeXL information
MESSAGE("")
MESSAGE("CodeXL INFORMATION:")
MESSAGE("CODEXL_ACTIVITY_LOGGER_HEADER_DIR = ${CODEXL_ACTIVITY_LOGGER_HEADER_DIR}, actually found at: ${CODEXL_ACTIVITY_LOGGER_HEADER}")
MESSAGE("CODEXL_ACTIVITY_LOGGER_LIBRARY_DIR = ${CODEXL_ACTIVITY_LOGGER_LIBRARY_DIR}, actually found at: ${CODEXL_ACTIVITY_LOGGER_LIBRARY}")
MESSAGE("")

endif (USE_CODEXL_ACTIVITY_LOGGER EQUAL 1)

#################
# Configure which C++ runtime to use
# hcc will use libc++ if USE_LIBCXX is set to ON; otherwise, it will use libstdc++
#################

# if USE_LIBCXX is not explicitly set
if( NOT DEFINED USE_LIBCXX )
  # default to libstdc++
  set( USE_LIBCXX "OFF" )

  if( CMAKE_COMPILER_IS_GNUCXX AND (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 5.0) )
    # If host compiler is g++, use libc++ if version is less than 5.0
    set( USE_LIBCXX "ON" )
  elseif( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
    # If host compiler is clang, detect version of system g++ and use libc++ if less than 5.0
    execute_process( COMMAND g++ -dumpversion OUTPUT_VARIABLE gplusplus_version )
    if( gplusplus_version VERSION_LESS 5.0 )
      set( USE_LIBCXX "ON" )
    endif( )
  endif( )
endif( )
set( USE_LIBCXX "OFF" )

# Detect libc++
if (USE_LIBCXX)
  find_path(LIBCXX_HEADER random PATHS /usr/local/include/c++/v1 /usr/include/c++/v1 NO_DEFAULT_PATH)
  message( "libc++ headers found at ${LIBCXX_HEADER}" )
endif( )

# set default installation path
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND CMAKE_INSTALL_PREFIX MATCHES "/usr/local")
  set(CMAKE_INSTALL_PREFIX ${HCC2})
endif ()

# show HCC version string
MESSAGE("====================================================")
MESSAGE("Building hc for HCC2 version:  ${HCC2_VERSION_STRING}")
MESSAGE("Installation path:  ${CMAKE_INSTALL_PREFIX}")
MESSAGE("====================================================")

#################
# Detect if we have ROCm stack available
#################

# at least we need the followings:
# - HSA headers (installed by HSA runtime)
# - HSA runtime libraries (installed by HSA runtime)
# - ROCm Device Library
if ((NOT HSA_HEADER) OR (NOT HSA_LIBRARY))
  set(HAS_ROCM 0)
else ((NOT HSA_HEADER) OR (NOT HSA_LIBRARY))
  set(HAS_ROCM 1)
endif ((NOT HSA_HEADER) OR (NOT HSA_LIBRARY))

if (HAS_ROCM EQUAL 0)
  MESSAGE(FATAL_ERROR "ROCm is NOT available on the system!")
endif (HAS_ROCM EQUAL 0)

#################
# Detect AMDGPU backend for native codegen
#################

set(HSA_AMDGPU_GPU_TARGET "auto" CACHE STRING "Target AMDGPU ISA version")

# Tokenize HSA_AMDGPU_GPU_TARGET

# Temporary workaround for use of old long-form GFX_ip names, to be removed once
# we fully deprecate them.
string(REGEX MATCHALL "AMD:AMDGPU:(7:0:0|7:0:1|8:0:1|8:0:2|8:0:3|9:0:0|9:0:1)"
                      tmp
                      ${HSA_AMDGPU_GPU_TARGET})
foreach(long_form IN LISTS tmp)
  string(REPLACE "AMD:AMDGPU:" "gfx" short_form ${long_form})
  string(REPLACE ":" "" short_form ${short_form})
  message(DEPRECATION "Be advised that use of long-form GFX_ip names, such as \
                       ${long_form}, is deprecated. Please use the short-form: \
                       ${short_form}.")
  list(REMOVE_ITEM HSA_AMDGPU_GPU_TARGET ${long_form})
  list(APPEND HSA_AMDGPU_GPU_TARGET ${short_form})
endforeach()

# join list
string(REPLACE ";" " " AMDGPU_TARGET "${HSA_AMDGPU_GPU_TARGET}")
MESSAGE(STATUS "HCC configured with AMDGPU targets: ${AMDGPU_TARGET}")

#################
# Setup HCC backend macro string
# Possible values:
# - AMDGPU : for HSA systems configured with Lightning backend
#################

set(KALMAR_BACKEND "HCC_BACKEND_AMDGPU")

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  set(LLVM_ENABLE_ASSERTIONS "On" CACHE BOOL "Compile with assertion checks enabled")
else ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  set(LLVM_ENABLE_ASSERTIONS "Off" CACHE BOOL "Compile with assertion checks enabled")
endif ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")

# force library install path to lib
set(CMAKE_INSTALL_LIBDIR "lib" CACHE INTERNAL "Installation directory for libraries" FORCE)

install( FILES ${CMAKE_CURRENT_SOURCE_DIR}/scripts/cmake/ImportedTargets.cmake
         DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/hcc )

add_subdirectory(include)

# build the integrated ROCm Device Library
set(AMDHSACOD ${ROCM_ROOT}/bin/amdhsacod CACHE FILEPATH "Specify the amdhsacod tool")

add_subdirectory(hcc_config)
#add_subdirectory(lib)

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/hcc_config/hcc_config.hxx.in
  ${CMAKE_CURRENT_BINARY_DIR}/hcc_config/hcc_config.hxx ESCAPE_QUOTES)

