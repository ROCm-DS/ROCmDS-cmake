#=============================================================================
# Copyright (c) 2021-2025, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================
# MIT License
#
# Modifications Copyright (c) 2025 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#=============================================================================
#
# This is the legacy entry point for projects using rapids-cmake.
#
# This will setup the following variables in the parent directory
# - CMAKE_MODULE_PATH
# - rapids-cmake-dir
#
# This is considered legacy as it has issues when multiple projects
# use rapids-cmake via CPM inside the same global project. In those
# cases it can fail due to CMAKE_MODULE_PREFIX not being exported properly
#
# Build ROCMmDS-CMake package:
#
# The option RAPIDS_CMAKE_ONLY_CREATE_PACKAGE will install (directly or via package install)
# a version of rapids-cmake/rapids-cmake.cmake that sets `rapids-cmake-dir` if
# included via `include(rapids-cmake)`. The latter requires that the installed
# `rapids-cmake` subfolder is in the CMAKE_MODULE_PATH, which must be done by
# the caller.

# Enforce the minimum required CMake version for all users
cmake_minimum_required(VERSION 3.30.4 FATAL_ERROR)

option(RAPIDS_CMAKE_ONLY_CREATE_PACKAGE "Package the `rapids-cmake` subfolder." OFF)
if (RAPIDS_CMAKE_ONLY_CREATE_PACKAGE)
  project(rocmds_cmake VERSION 3.0.0)

  set(DEFAULT_RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX "dev")
  if (DEFINED ENV{RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX})
    set(DEFAULT_RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX "$ENV{RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX}")
  endif()
  set(RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX "${DEFAULT_RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX}")
  set(CPACK_PACKAGE_NAME "rocmds-cmake-${RAPIDS_CMAKE_DEVEL_PACKAGE_SUFFIX}" CACHE STRING "Overwrite package name.")

  set(rapids-cmake-dir "${CMAKE_CURRENT_LIST_DIR}/rapids-cmake")
  set(install_prefix share/cmake/rocmds-cmake)

  install(FILES init.cmake VERSION RAPIDS_BRANCH DESTINATION ${install_prefix})
  install(DIRECTORY ${rapids-cmake-dir}/ DESTINATION ${install_prefix}/modules
          PATTERN "rapids-cmake/rapids-cmake.cmake" EXCLUDE)

  # Make `include(rapids-cmake)` entry point for configuring ROCm-DS CMake correctly
  # when using it via module path.
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/_prepare)
  set(modified-rapids-cmake-file ${CMAKE_CURRENT_BINARY_DIR}/_prepare/rapids-cmake.cmake)
  file(COPY_FILE ${rapids-cmake-dir}/rapids-cmake.cmake ${modified-rapids-cmake-file})
  file(APPEND ${modified-rapids-cmake-file}
       [=[

set(RAPIDS_CMAKE_FROM_MODULE_PATH ON)
set(rapids-cmake-dir ${CMAKE_CURRENT_LIST_DIR})
       ]=])
  install(FILES ${modified-rapids-cmake-file}
          DESTINATION ${install_prefix}/modules)

  set(CPACK_PACKAGE_VENDOR "Advanced Micro Devices, Inc.")
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR}")
  set(CPACK_OUTPUT_FILE_PREFIX "dist" CACHE PATH "Package output file prefix.")
  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
  set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
  set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/rocm-ds" CACHE PATH "Package install prefix.")
  include(CPack)
  return() # return prematurely
endif()

set(rapids-cmake-dir "${CMAKE_CURRENT_LIST_DIR}/rapids-cmake")
if(NOT DEFINED CACHE{rapids-cmake-dir})
  set(rapids-cmake-dir "${rapids-cmake-dir}" CACHE INTERNAL "" FORCE)
endif()

if(NOT "${rapids-cmake-dir}" IN_LIST CMAKE_MODULE_PATH)
  list(APPEND CMAKE_MODULE_PATH "${rapids-cmake-dir}")
endif()

# Propagate up the rapids-cmake version/tag info
include("${rapids-cmake-dir}/rapids-version.cmake")
set(rapids-cmake-version ${rapids-cmake-version} PARENT_SCOPE)
set(rapids-cmake-checkout-tag ${rapids-cmake-checkout-tag} PARENT_SCOPE)

# install a hook that sets up `rapids-cmake-dir` and `CMAKE_MODULE_PATH` all the way up the
# call-stack
cmake_language(DEFER DIRECTORY ${CMAKE_CURRENT_LIST_DIR} CALL include
               "${rapids-cmake-dir}/../init.cmake")
