#=============================================================================
# Copyright (c) 2025, NVIDIA CORPORATION.
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

include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_rocmds_logger
------------------------

.. versionadded:: v25.02.00

Allow projects to build `rocmds-logger` via `CPM`.

Uses the version of rapids-logger :ref:`specified in the version file <cpm_versions>` for consistency
across all ROCm-DS projects.

.. code-block:: cmake

  rapids_cpm_rocmds_logger( [BUILD_EXPORT_SET <export-name>]
                            [INSTALL_EXPORT_SET <export-name>]
                            [<CPM_ARGS> ...])

.. |PKG_NAME| replace:: logger
.. include:: common_package_args.txt

Result Targets
^^^^^^^^^^^^^^
  rapids_logger::rapids_logger target will be created

#]=======================================================================]
function(rapids_cpm_rocmds_logger)
    list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.rapids_logger")

    include("${rapids-cmake-dir}/cpm/detail/package_details.cmake")
    rapids_cpm_package_details("rocmds_logger" version repository tag shallow exclude) # NOTE: rocmds_logger is versions.json key

    include("${rapids-cmake-dir}/cpm/detail/generate_patch_command.cmake")
    rapids_cpm_generate_patch_command("rocmds_logger" ${version} patch_command build_patch_only) # NOTE: rocmds_logger is versions.json key

    include("${rapids-cmake-dir}/cpm/find.cmake")
    rapids_cpm_find(rapids_logger ${version} ${ARGN} ${build_patch_only} # NOTE: rapids_logger is CMake project/package name
            CPM_ARGS
            GIT_REPOSITORY ${repository}
            GIT_TAG ${tag}
            GIT_SHALLOW ${shallow} ${patch_command}
            OPTIONS "BUILD_TESTS OFF")

    include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
    rapids_cpm_display_patch_status(logger)

    # Propagate up variables that CPMFindPackage provides
    set(rapids_logger_SOURCE_DIR "${rapids_logger_SOURCE_DIR}" PARENT_SCOPE)
    set(rapids_logger_BINARY_DIR "${rapids_logger_BINARY_DIR}" PARENT_SCOPE)
    set(rapids_logger_ADDED "${rapids_logger_ADDED}" PARENT_SCOPE)
    set(rapids_logger_VERSION ${version} PARENT_SCOPE)

    # Also propagate rocmds prefixed variables to parent scope
    set(rocmds_logger_SOURCE_DIR "${rapids_logger_SOURCE_DIR}" PARENT_SCOPE)
    set(rocmds_logger_BINARY_DIR "${rapids_logger_BINARY_DIR}" PARENT_SCOPE)
    set(rocmds_logger_ADDED "${rapids_logger_ADDED}" PARENT_SCOPE)
    set(rocmds_logger_VERSION ${version} PARENT_SCOPE)
endfunction()

if (HIP_AS_CUDA)
    function(rapids_cpm_rapids_logger)
        rapids_cpm_rocmds_logger(${ARGN})
    endfunction()
endif()
