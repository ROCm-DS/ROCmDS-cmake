# RUN
# apt install rocmds-cmake-dev # list installed files: dpkg -L rocmds-cmake-dev
# mkdir build && cd build
# cmake ../ -DCMAKE_MODULE_PATH=<rocm-ds-cmake-modules-path>

cmake_minimum_required(VERSION 3.23.1 FATAL_ERROR)

project(MyTestProject VERSION 0.0.0)

include(rapids-cmake)
include(rapids-cpm)
# include(rapids-cuda)
include(rapids-hip)
include(rapids-export)
include(rapids-find)

message(STATUS "rapids-cmake-dir=${rapids-cmake-dir}")

rapids_hip_init_architectures(MyTestProject)

rapids_cpm_init()

macro(find_and_configure_libhipcxx)
  include(${rapids-cmake-dir}/cpm/libhipcxx.cmake)

  rapids_cpm_libhipcxx(
    BUILD_EXPORT_SET myproject-targets
    INSTALL_EXPORT_SET myproject-targets
  )
endmacro()

macro(find_and_configure_hipbench)
  include(${rapids-cmake-dir}/cpm/hipbench.cmake)

  rapids_cpm_hipbench(
    BUILD_EXPORT_SET myproject-targets
    # INSTALL_EXPORT_SET myproject-targets NOTE: hipbench doesn't provide install rules
  )
endmacro()

macro(find_and_configure_cccl)
  include(${rapids-cmake-dir}/cpm/cccl.cmake)

  rapids_cpm_cccl(
    BUILD_EXPORT_SET myproject-targets
    INSTALL_EXPORT_SET myproject-targets
  )
endmacro()

set(HIP_AS_CUDA ON)
find_and_configure_cccl()

add_library(dummy INTERFACE)
target_link_libraries(dummy INTERFACE hipCCL::libhipcxx CCCL::Thrust)

add_library(dummy2 INTERFACE)
target_link_libraries(dummy2 INTERFACE CCCL::CCCL)

add_library(dummy3 INTERFACE)
target_link_libraries(dummy3 INTERFACE libcudacxx::libcudaxx)

find_and_configure_libhipcxx()
find_and_configure_hipbench()

message(STATUS "hipCCL_ADDED: " ${hipCCL_ADDED})
message(STATUS "CCCL_ADDED: " ${CCCL_ADDED})
message(STATUS "hipCCL_VERSION: " ${hipCCL_VERSION})
message(STATUS "CCCL_VERSION: " ${CCCL_VERSION})

# Propagate up variables that CPMFindPackage provides
message(STATUS "libhipcxx_SOURCE_DIR: " ${libhipcxx_SOURCE_DIR})
message(STATUS "libhipcxx_BINARY_DIR: " ${libhipcxx_BINARY_DIR})
message(STATUS "libhipcxx_ADDED: " ${libhipcxx_ADDED})
message(STATUS "libhipcxx_VERSION: " ${libhipcxx_VERSION})

message(STATUS "libcudacxx_SOURCE_DIR: " ${libcudacxx_SOURCE_DIR})
message(STATUS "libcudacxx_BINARY_DIR: " ${libcudacxx_BINARY_DIR})
message(STATUS "libcudacxx_ADDED: " ${libcudacxx_ADDED})
message(STATUS "libcudacxx_VERSION: " ${libcudacxx_VERSION})

message(STATUS "rocthrust_VERSION: " ${rocthrust_VERSION})
message(STATUS "hipcub_VERSION: " ${hipcub_VERSION})
message(STATUS "rocprim_VERSION: " ${rocprim_VERSION})
message(STATUS "Thrust_VERSION: " ${Thrust_VERSION})
message(STATUS "CUB_VERSION: " ${CUB_VERSION})
