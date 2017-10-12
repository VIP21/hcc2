
if (HCC_RUNTIME_DEBUG)
  add_compile_options(-g -O0)
endif (HCC_RUNTIME_DEBUG)

include_directories(${CMAKE_CURRENT_BINARY_DIR}/../hcc_config)

set(CMAKE_CXX_FLAGS "-std=c++11" )

if (USE_LIBCXX)
  add_definitions(-DUSE_LIBCXX  -DLIBCXX_HEADER=${LIBCXX_HEADER})
  if (HCC_TOOLCHAIN_RHEL)
    add_definitions(-DHCC_TOOLCHAIN_RHEL)
  endif()
endif (USE_LIBCXX)


####################
# CodeXL Activity Logger
####################
if (USE_CODEXL_ACTIVITY_LOGGER EQUAL 1)
add_definitions(-DCODEXL_ACTIVITY_LOGGER_ENABLED)
if (CODEXL_ACTIVITY_LOGGER_HEADER)
  add_definitions(-DCODEXL_ACTIVITY_LOGGER_HEADER=${CODEXL_ACTIVITY_LOGGER_HEADER})
endif (CODEXL_ACTIVITY_LOGGER_HEADER)
if (CODEXL_ACTIVITY_LOGGER_LIBRARY)
  add_definitions(-DCODEXL_ACTIVITY_LOGGER_LIBRARY=${CODEXL_ACTIVITY_LOGGER_LIBRARY})
endif (CODEXL_ACTIVITY_LOGGER_LIBRARY)
endif (USE_CODEXL_ACTIVITY_LOGGER EQUAL 1)

add_llvm_tool(hcc-config hcc_config.cpp)
add_llvm_tool_symlink(clamp-config hcc-config)



