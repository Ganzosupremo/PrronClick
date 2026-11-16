cmake_minimum_required(VERSION 3.16)
project(latency_probe LANGUAGES C CXX)

set(THIRD_PARTY "${CMAKE_CURRENT_LIST_DIR}/../../third_party")
include("${THIRD_PARTY}/link/AbletonLinkConfig.cmake")

add_executable(latency_probe probe.cpp "${THIRD_PARTY}/miniaudio/miniaudio.c")
set_target_properties(latency_probe PROPERTIES CXX_STANDARD 17)
target_include_directories(latency_probe PRIVATE "${THIRD_PARTY}/miniaudio")
target_link_libraries(latency_probe PRIVATE Ableton::Link)
link_pin_win32_winnt(latency_probe)
