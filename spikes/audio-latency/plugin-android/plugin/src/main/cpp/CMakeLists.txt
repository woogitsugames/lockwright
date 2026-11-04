cmake_minimum_required(VERSION 3.22)
project(lwaudio CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Oboe (Apache 2.0, docs/ASSETS.md), built from source and linked statically: no extra .so in the APK.
include(FetchContent)
FetchContent_Declare(oboe GIT_REPOSITORY https://github.com/google/oboe.git GIT_TAG 1.9.3 GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(oboe)

add_library(lwaudio SHARED click_engine.cpp jni_bridge.cpp)
target_link_libraries(lwaudio PRIVATE oboe log OpenSLES)
target_compile_options(lwaudio PRIVATE -Wall -Wextra -O2)
