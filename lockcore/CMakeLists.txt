cmake_minimum_required(VERSION 3.20)
project(lockcore VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

option(LOCKCORE_BUILD_TESTS "Build lockcore tests" ON)
option(LOCKCORE_BUILD_TOOLS "Build lockcore tools" ON)
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
  src/families/lever.cpp
  src/families/pin_tumbler.cpp
  src/families/ring_combo.cpp
  src/families/wafer.cpp
  src/families/wooden_pin.cpp
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

if(LOCKCORE_BUILD_TOOLS)
  add_executable(verify_seeds tools/verify_seeds.cpp)
  target_link_libraries(verify_seeds PRIVATE lockcore)
  add_executable(replay_tool tools/replay_tool.cpp)
  target_link_libraries(replay_tool PRIVATE lockcore)
endif()

if(LOCKCORE_BUILD_TESTS)
  enable_testing()
  add_executable(lockcore_tests
    tests/test_main.cpp
    tests/test_core.cpp
    tests/test_json.cpp
    tests/test_pin_tumbler.cpp
    tests/test_wafer.cpp
    tests/test_wooden_pin.cpp
    tests/test_lever.cpp
    tests/test_ring_combo.cpp
    tests/test_replay.cpp
    tests/test_fuzz.cpp
  )
  target_link_libraries(lockcore_tests PRIVATE lockcore)
  target_compile_definitions(lockcore_tests PRIVATE LOCKCORE_GOLDEN_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/golden")
  add_test(NAME lockcore_unit COMMAND lockcore_tests)
  # No floating point anywhere in the library sources (determinism, D-07).
  add_test(NAME lockcore_no_float
    COMMAND ${CMAKE_COMMAND} -DDIRS=${CMAKE_CURRENT_SOURCE_DIR}/src;${CMAKE_CURRENT_SOURCE_DIR}/include
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/no_float.cmake)
  if(LOCKCORE_BUILD_TOOLS)
    add_test(NAME verify_seeds_smoke COMMAND verify_seeds --seeds 200 --feel 50)
  endif()
endif()
