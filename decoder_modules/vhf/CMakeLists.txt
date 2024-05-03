cmake_minimum_required(VERSION 3.13)
project(vhfvoiceradio)

file(GLOB_RECURSE SRC "src/*.cpp")

set(CMAKE_INSTALL_PREFIX "/usr/")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake/")

include(${SDRPP_MODULE_CMAKE})

find_package(MBE REQUIRED)
find_package(ITPP REQUIRED)

target_link_libraries(vhfvoiceradio PRIVATE ${ITPP_LIBRARY} ${MBE_LIBRARY})
target_include_directories(vhfvoiceradio PRIVATE "src/" ${MBE_INCLUDE_DIR} ${ITPP_INCLUDE_DIR})