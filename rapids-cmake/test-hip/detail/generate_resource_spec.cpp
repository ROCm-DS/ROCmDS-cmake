/*
 * Copyright (c) 2022-2025, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// MIT License
//
// Modifications Copyright (C) 2024-2026 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifdef HAVE_HIP
#include <hip/hip_runtime_api.h>
#endif

#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

struct version {
  version() : json_major(1), json_minor(0) {}
  int json_major;
  int json_minor;
};

struct gpu {
  gpu(int i) : id(i), memory(0), slots(0){};
  gpu(int i, size_t mem) : id(i), memory(mem), slots(100) {}
  int id;
  size_t memory;
  int slots;
};

// A hard-coded JSON printer that generates a ctest resource-specification file:
// https://cmake.org/cmake/help/latest/manual/ctest.1.html#resource-specification-file
void to_json(std::ostream& buffer, version const& v)
{
  buffer << "\"version\": {\"major\": " << v.json_major << ", \"minor\": " << v.json_minor << "}";
}
void to_json(std::ostream& buffer, gpu const& g)
{
  buffer << "\t\t{\"id\": \"" << g.id << "\", \"slots\": " << g.slots << "}";
}

int main(int argc, char** argv)
{
  std::vector<gpu> gpus;
  int nDevices = 0;

#ifdef HAVE_HIP
  hipError_t err = hipGetDeviceCount(&nDevices);
  assert(err == hipSuccess);
  if (nDevices == 0) {
    gpus.push_back(gpu(0));
  } else {
    for (int i = 0; i < nDevices; ++i) {
      hipDeviceProp_t prop;
      err = hipGetDeviceProperties(&prop, i); assert(err == hipSuccess);
      gpus.push_back(gpu(i, prop.totalGlobalMem));
    }
  }
#else
  gpus.push_back(gpu(0));
#endif

  if (argc != 2) {
    std::cout << "Usage: " << argv[0] << " <filename>\n";
    return 1;
  }

  // GENERATED_RESOURCE_SPEC_FILE requires an absolute path, and CMake does
  // not have a "give me the current working directory" command, so we have to
  // get it from here.
  std::string arg = argv[1];
  if (arg == "--cwd") {
    std::cout << std::filesystem::current_path().string();
    std::cout.flush();
    return 0;
  }

  std::ofstream fout(argv[1]);

  version v;
  fout << "{\n";
  to_json(fout, v);
  fout << ",\n";
  fout << "\"local\": [{\n";
  fout << "\t\"gpus\": [\n";
  for (int i = 0; i < gpus.size(); ++i) {
    to_json(fout, gpus[i]);
    if (i != (gpus.size() - 1)) { fout << ","; }
    fout << "\n";
  }
  fout << "\t]\n";
  fout << "}]\n";
  fout << "}" << std::endl;
  return 0;
}
