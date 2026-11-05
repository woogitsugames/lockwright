# Spike 5 (TECH.md §4): builds lockcore from outside (read-only) plus spike tools.
#   cmake -S spikes/determinism -B spikes/determinism/build/x86_64-gcc
cmake_minimum_required(VERSION 3.20)
project(lockcore_determinism LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

set(LOCKCORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../lockcore" CACHE PATH "lockcore source dir")
enable_testing()
# Tests and tools of lockcore itself (ctest, golden replays, verify_seeds).
add_subdirectory(${LOCKCORE_DIR} lockcore)

add_executable(replay_fuzz tools/replay_fuzz.cpp)
target_link_libraries(replay_fuzz PRIVATE lockcore)

option(DET_STATIC "Link executables statically (qemu-user, Android without adb)" OFF)
if(DET_STATIC)
  # every executable of lockcore (incl. tools added later, e.g. check_locks for practice_locks) + ours:
  # a dynamically linked binary under qemu-user fails with "Could not open /lib/ld-linux-aarch64.so.1"
  get_property(_lc_targets DIRECTORY ${LOCKCORE_DIR} PROPERTY BUILDSYSTEM_TARGETS)
  foreach(t replay_fuzz ${_lc_targets})
    get_target_property(_type ${t} TYPE)
    if(_type STREQUAL "EXECUTABLE")
      target_link_options(${t} PRIVATE -static)
    endif()
  endforeach()
endif()
