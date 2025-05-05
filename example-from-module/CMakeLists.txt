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

function(find_and_configure_libhipcxx)
  include(${rapids-cmake-dir}/cpm/libhipcxx.cmake)

  rapids_cpm_libhipcxx(
    BUILD_EXPORT_SET myproject-targets
    INSTALL_EXPORT_SET myproject-targets
  )

endfunction()

function(find_and_configure_hipbench)
  include(${rapids-cmake-dir}/cpm/hipbench.cmake)

  rapids_cpm_hipbench(
    BUILD_EXPORT_SET myproject-targets
    # INSTALL_EXPORT_SET myproject-targets NOTE: hipbench doesn't provide install rules
  )

endfunction()

find_and_configure_libhipcxx()

find_and_configure_hipbench()
