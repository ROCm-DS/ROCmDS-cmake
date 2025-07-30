#=============================================================================
# Copyright (c) 2021, NVIDIA CORPORATION.
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
# Modifications Copyright (c) 2023-2024 Advanced Micro Devices, Inc.
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
include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_hipbench
------------------

.. versionadded:: v21.10.00

Allow projects to find or build `hipbench` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the version of hipbench :ref:`specified in the version file <cpm_versions>` for consistency
across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_hipbench( [BUILD_EXPORT_SET <export-name>]
                      [<CPM_ARGS> ...])

``BUILD_EXPORT_SET``
  Record that a :cmake:command:`CPMFindPackage(nvbench)` call needs to occur as part of
  our build directory export set.

``CPM_ARGS``
  Any arguments after `CPM_ARGS` will be forwarded to the underlying :cmake:command:`CPMFindPackage(<PackageName> ...)` call

.. note::

  RAPIDS-cmake will error out if an INSTALL_EXPORT_SET is provided, as nvbench
  doesn't provide any support for installation.


.. note::

  Always sets both ``hipbench``- and ``nvbench``-prefixed variables and targets.
  In contrast to other projects, ``hipBench`` provides ``nvbench``-prefixed variable and target names instead
  of `hipbench``-prefixed ones.

Result Targets
^^^^^^^^^^^^^^
  ``hipbench::hipbench`` target will be created.
  ``hipbench::main`` target will be created.

  ``nvbench::nvbench`` target will be created.
  ``nvbench::main`` target will be created.

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`hipbench_SOURCE_DIR` is set to the path to the source directory of nvbench.
  :cmake:variable:`hipbench_BINARY_DIR` is set to the path to the build directory of  nvbench.
  :cmake:variable:`hipbench_ADDED`      is set to a true value if nvbench has not been added before.
  :cmake:variable:`hipbench_VERSION`    is set to the version of nvbench specified by the versions.json.
  :cmake:variable:`nvbench_SOURCE_DIR` Same as ``hipbench_``-prefixed variable (always created).
  :cmake:variable:`nvbench_BINARY_DIR` Same as ``hipbench_``-prefixed variable (always created).
  :cmake:variable:`nvbench_ADDED`      Same as ``hipbench_``-prefixed variable (always created).
  :cmake:variable:`nvbench_VERSION`    Same as ``hipbench_``-prefixed variable (always created).

#]=======================================================================]
function(rapids_cpm_hipbench)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.hipbench")

  set(build_shared ON)
  if(BUILD_STATIC IN_LIST ARGN)
    set(build_shared OFF)
    set(CPM_DOWNLOAD_hipbench ON) # Since we need static we build from source
    set(CPM_DOWNLOAD_fmt ON) # Make sure we don't link to a preexisting shared fmt
  endif()

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(hipbench ${ARGN} VERSION_VAR version FIND_VAR find_args CPM_VAR
                          cpm_find_info TO_INSTALL_VAR to_install)

  # CUDA::nvml is an optional package and might not be installed ( aka conda )
  #: find_package(CUDAToolkit REQUIRED)
  #: TODO(HIP/AMD): Lookup pyrsmi instead
  set(hipbench_with_nvml "OFF")
  #: if(TARGET CUDA::nvml)
  #:   set(hipbench_with_nvml "ON")
  #: endif()

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(nvbench ${version} ${find_args}
                  GLOBAL_TARGETS nvbench::nvbench nvbench::main
                  CPM_ARGS ${cpm_find_info}
                  OPTIONS "NVBench_ENABLE_NVML ${hipbench_with_nvml}"
                          "NVBench_ENABLE_CUPTI OFF"
                          "NVBench_ENABLE_EXAMPLES OFF"
                          "NVBench_ENABLE_TESTING OFF"
                          "NVBench_ENABLE_INSTALL_RULES ${to_install}"
                          "BUILD_SHARED_LIBS ${build_shared}")

  #: NOTE(HIP/AMD): also provide hip-prefixed targets
  #: NOTE(HIP/AMD): The download tests (see testing/CMakeLists.txt and testing/utils/fillcache/CMakeLists.txt)
  #:                may pass the CPM option DOWNLOAD_ONLY ON. In this case, none of the
  #:                nvbench:: targets  exist.
  if (TARGET nvbench::nvbench AND NOT TARGET hipbench::hipbench)
    get_target_property(nvbench_orig nvbench::nvbench ALIASED_TARGET)
    if(nvbench_orig)
      add_library(hipbench::hipbench ALIAS ${nvbench_orig})
    else()
      add_library(hipbench::hipbench ALIAS nvbench::nvbench)
    endif()
  endif()
  if (TARGET nvbench::main AND NOT TARGET hipbench::main)
    get_target_property(main_orig nvbench::main ALIASED_TARGET)
    if(main_orig)
      add_library(hipbench::main ALIAS ${main_orig})
    else()
      add_library(hipbench::main ALIAS nvbench::main)
    endif()
  endif()

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(nvbench)

  # Propagate up variables that CPMFindPackage provide
  set(nvbench_SOURCE_DIR "${nvbench_SOURCE_DIR}" PARENT_SCOPE)
  set(nvbench_BINARY_DIR "${nvbench_BINARY_DIR}" PARENT_SCOPE)
  set(nvbench_ADDED "${nvbench_ADDED}" PARENT_SCOPE)
  set(nvbench_VERSION ${version} PARENT_SCOPE)
  #: NOTE(HIP/AMD): also provide hip-prefixed variables
  set(hipbench_SOURCE_DIR "${nvbench_SOURCE_DIR}" PARENT_SCOPE)
  set(hipbench_BINARY_DIR "${nvbench_BINARY_DIR}" PARENT_SCOPE)
  set(hipbench_ADDED "${nvbench_ADDED}" PARENT_SCOPE)
  set(hipbench_VERSION ${version} PARENT_SCOPE)

  # nvbench creates the correct namespace aliases
endfunction()

if (HIP_AS_CUDA)
  macro(rapids_cpm_nvbench)
    rapids_cpm_hipbench(${ARGN})
  endmacro()
endif()
