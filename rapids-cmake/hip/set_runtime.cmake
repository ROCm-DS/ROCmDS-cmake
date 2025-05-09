#=============================================================================
# Copyright (c) 2023-2024, NVIDIA CORPORATION.
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

include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_hip_set_runtime
-------------------------------

.. versionadded:: v23.08.00

Establish what HIP runtime library should be used by a single target

  .. code-block:: cmake

    rapids_hip_set_runtime( target USE_STATIC (TRUE|FALSE) )

  Establishes what HIP runtime will be used for a target, via
  the :cmake:prop_tgt:`HIP_RUNTIME_LIBRARY <cmake:prop_tgt:HIP_RUNTIME_LIBRARY>`
  and by linking to `hip::host` if the :cmake:module:`find_package(HIP)
  <cmake:module:FindHIP>` has been called.

  The linking to the `hip::host` will have the following
  usage behavior:

    - For `INTERFACE` targets the linking will be `INTERFACE`
    - For all other targets the linking will be `PRIVATE`

 .. note::
 If using the deprecated `FindHIP.cmake` you must use the
  :cmake:command:`rapids_hip_init_runtime` method to properly establish the default
  mode.

  When `USE_STATIC TRUE` is provided the target will link to a
    statically-linked HIP runtime library (**NOTE**: This is presently not supported on HIP platform.).

  When `USE_STATIC FALSE` is provided the target will link to a
    shared-linked HIP runtime library.


#]=======================================================================]
function(rapids_hip_set_runtime target use_static value)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.hip.set_runtime")

  get_target_property(type ${target} TYPE)
  if(type STREQUAL "INTERFACE_LIBRARY")
    set(mode INTERFACE)
  else()
    set(mode PRIVATE)
  endif()

  if(${value})
    message(FATAL_ERROR "Cannot use static runtime with HIP")	  
  else()
    #set_target_properties(${target} PROPERTIES CUDA_RUNTIME_LIBRARY Shared)
    target_link_libraries(${target} ${mode} $<TARGET_NAME_IF_EXISTS:hip::host>)
  endif()

endfunction()

if (HIP_AS_CUDA)
  macro(rapids_cuda_set_runtime use_static value)
    rapids_hip_set_runtime(${use_static} ${value})
  endmacro()
endif()
