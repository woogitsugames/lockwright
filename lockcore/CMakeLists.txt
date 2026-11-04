cmake_minimum_required(VERSION 3.20)
project(lockcore VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

option(LOCKCORE_SANITIZE "Build with ASan + UBSan" OFF)

add_library(lockcore
  src/bot.cpp
  src/components.cpp
  src/events.cpp
  src/json.cpp
  src/lockfile.cpp
  src/registry.cpp
  src/replay.cpp
  src/session.cpp
  src/families/builtin.cpp
  src/families/pin_tumbler.cpp
  src/families/wafer.cpp
)
target_include_directories(lockcore PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(lockcore PRIVATE -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wno-sign-conversion)
  # No float in the simulation; keep FP contraction off anyway (TECH.md spike 5).
  target_compile_options(lockcore PUBLIC -ffp-contract=off)
elseif(MSVC)
  target_compile_options(lockcore PRIVATE /W4)
endif()

if(LOCKCORE_SANITIZE)
  target_compile_options(lockcore PUBLIC -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(lockcore PUBLIC -fsanitize=address,undefined)
endif()

