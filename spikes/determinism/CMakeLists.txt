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
  foreach(t replay_fuzz lockcore_tests verify_seeds replay_tool)
    if(TARGET ${t})
      target_link_options(${t} PRIVATE -static)
    endif()
  endforeach()
endif()
