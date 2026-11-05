cmake_minimum_required(VERSION 3.20)
project(lockcore VERSION 0.2.0 LANGUAGES CXX)

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
  src/families/warded.cpp
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
  # UB is fatal so that ctest fails on it (v0.2).
  target_compile_options(lockcore PUBLIC -fsanitize=address,undefined -fno-sanitize-recover=undefined -fno-omit-frame-pointer)
  target_link_options(lockcore PUBLIC -fsanitize=address,undefined)
endif()

if(LOCKCORE_BUILD_TOOLS)
  add_executable(verify_seeds tools/verify_seeds.cpp)
  target_link_libraries(verify_seeds PRIVATE lockcore)
  add_executable(replay_tool tools/replay_tool.cpp)
  target_link_libraries(replay_tool PRIVATE lockcore)
  add_executable(check_locks tools/check_locks.cpp)
  target_link_libraries(check_locks PRIVATE lockcore)
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
    tests/test_warded.cpp
    tests/test_replay.cpp
    tests/test_fuzz.cpp
  )
  target_link_libraries(lockcore_tests PRIVATE lockcore)
  target_compile_definitions(lockcore_tests PRIVATE LOCKCORE_GOLDEN_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/golden")
  add_test(NAME lockcore_unit COMMAND lockcore_tests)
  # Light fuzzing, 100k random steps per family; the timeout catches hangs.
  add_test(NAME lockcore_fuzz COMMAND lockcore_tests fuzz:)
  set_tests_properties(lockcore_fuzz PROPERTIES TIMEOUT 300)
  # No floating point anywhere in the library sources (determinism, D-07).
  add_test(NAME lockcore_no_float
    COMMAND ${CMAKE_COMMAND} -DDIRS=${CMAKE_CURRENT_SOURCE_DIR}/src;${CMAKE_CURRENT_SOURCE_DIR}/include
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/no_float.cmake)
  if(LOCKCORE_BUILD_TOOLS)
    add_test(NAME verify_seeds_smoke COMMAND verify_seeds --seeds 200 --feel 50)
    # A run that checks nothing, or a bad argument, must not pass (T25-10/11).
    add_test(NAME verify_seeds_rejects_zero COMMAND verify_seeds --seeds 0)
    add_test(NAME verify_seeds_rejects_text COMMAND verify_seeds --seeds 12x)
    add_test(NAME verify_seeds_rejects_family COMMAND verify_seeds --seeds 1 --family does_not_exist)
    add_test(NAME verify_seeds_rejects_tier COMMAND verify_seeds --seeds 1 --tier 999)
    add_test(NAME verify_seeds_rejects_csv COMMAND verify_seeds --seeds 1 --family wafer --tier 1 --csv /nonexistent-dir/x.csv)
    set_tests_properties(verify_seeds_rejects_zero verify_seeds_rejects_text verify_seeds_rejects_family
                         verify_seeds_rejects_tier verify_seeds_rejects_csv PROPERTIES WILL_FAIL TRUE)
    # play compares hash, steps and open (T25-09): a golden with a wrong step count fails.
    add_test(NAME replay_tool_play_golden COMMAND replay_tool play ${CMAKE_CURRENT_SOURCE_DIR}/tests/golden/wafer_t2_s77.replay.json)
    add_test(NAME replay_tool_play_bad_steps COMMAND ${CMAKE_COMMAND} -DTOOL=$<TARGET_FILE:replay_tool>
             -DIN=${CMAKE_CURRENT_SOURCE_DIR}/tests/golden/wafer_t2_s77.replay.json -DOUT=${CMAKE_CURRENT_BINARY_DIR}/bad_steps.replay.json
             -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/play_bad_steps.cmake)
    # Authored practice locks: parse, no ignored keys, scripted bot opens each one.
    file(GLOB LOCKCORE_PRACTICE ${CMAKE_CURRENT_SOURCE_DIR}/practice/*.json)
    add_test(NAME practice_locks COMMAND check_locks --feel 20 ${LOCKCORE_PRACTICE})
    add_test(NAME replay_tool_record_bad_path COMMAND replay_tool record wafer 2 77 /nonexistent-dir/x.replay.json)
    set_tests_properties(replay_tool_record_bad_path PROPERTIES WILL_FAIL TRUE)
  endif()
endif()
