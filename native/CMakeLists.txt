cmake_minimum_required(VERSION 3.16)
project(prronclick_native LANGUAGES C CXX)

set(THIRD_PARTY ${CMAKE_CURRENT_LIST_DIR}/../third_party)
include(${THIRD_PARTY}/link/AbletonLinkConfig.cmake)

add_library(prronclick_engine SHARED
  engine.cpp
  ${THIRD_PARTY}/miniaudio/miniaudio.c
)
set_target_properties(prronclick_engine PROPERTIES CXX_STANDARD 17)
target_include_directories(prronclick_engine PRIVATE ${THIRD_PARTY}/miniaudio)
target_link_libraries(prronclick_engine PRIVATE Ableton::Link)
link_pin_win32_winnt(prronclick_engine)
