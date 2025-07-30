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

include("${rapids-cmake-dir}/cpm/_init_hip_options.cmake")

#[=======================================================================[.rst:
rapids_cpm_hipmm
--------------

.. versionadded:: v21.10.00

Allow projects to find or build ROCm `RMM` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the current rapids-cmake version of ROCm RMM `as specified in the version file <cpm_versions>`
for  consistency across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_hipmm( [BUILD_EXPORT_SET <export-name>]
                  [INSTALL_EXPORT_SET <export-name>]
                  [<CPM_ARGS> ...])

.. |PKG_NAME| replace:: hipmm
.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^

  rmm::rmm target will be created

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`rmm_SOURCE_DIR` is set to the path to the source directory of RMM.
  :cmake:variable:`rmm_BINARY_DIR` is set to the path to the build directory of  RMM.
  :cmake:variable:`rmm_ADDED`      is set to a true value if RMM has not been added before.
  :cmake:variable:`rmm_VERSION`    is set to the version of RMM specified by the versions.json.

#]=======================================================================]
function(rapids_cpm_hipmm)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.rmm")

  include("${rapids-cmake-dir}/cpm/detail/package_info.cmake")
  rapids_cpm_package_info(hipmm ${ARGN} VERSION_VAR version FIND_VAR find_args CPM_VAR cpm_find_info
                          TO_INSTALL_VAR to_install)

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(rmm ${version} ${find_args} GLOBAL_TARGETS rmm::rmm rmm::rmm_logger
                                                             rmm::rmm_logger_impl
                  CPM_ARGS ${cpm_find_info} OPTIONS "BUILD_TESTS OFF" "BUILD_BENCHMARKS OFF")

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(hipmm)

  # Propagate up variables that CPMFindPackage provide
  set(rmm_SOURCE_DIR "${rmm_SOURCE_DIR}" PARENT_SCOPE)
  set(rmm_BINARY_DIR "${rmm_BINARY_DIR}" PARENT_SCOPE)
  set(rmm_ADDED "${rmm_ADDED}" PARENT_SCOPE)
  set(rmm_VERSION ${version} PARENT_SCOPE)

  # rmm creates the correct namespace aliases
endfunction()

if (HIP_AS_CUDA)
  macro(rapids_cpm_rmm)
    rapids_cpm_hipmm(${ARGN})
  endmacro()
endif()
