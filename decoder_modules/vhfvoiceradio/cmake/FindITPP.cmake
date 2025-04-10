# - Try to find ITPP
# Once done this will define
#
#  ITPP_FOUND - System has ITPP
#  ITPP_INCLUDE_DIR - The ITPP include directory
#  ITPP_LIBRARY - The library needed to use ITPP
#

# 首先检查环境变量SDR_KIT_ROOT，这是Android构建环境中设置的变量
if(DEFINED ENV{SDR_KIT_ROOT})
  set(SDR_KIT_ROOT $ENV{SDR_KIT_ROOT})
  set(ANDROID_ABI $ENV{ANDROID_ABI})
  message(STATUS "Using SDR_KIT_ROOT: ${SDR_KIT_ROOT}/${ANDROID_ABI}")
  
  # 在SDR_KIT_ROOT中查找
  find_path(ITPP_INCLUDE_DIR itpp/itcomm.h
    PATHS
    ${SDR_KIT_ROOT}/${ANDROID_ABI}/include
    NO_DEFAULT_PATH
  )
  
  find_library(ITPP_LIBRARY
    NAMES itpp libitpp
    PATHS
    ${SDR_KIT_ROOT}/${ANDROID_ABI}/lib
    NO_DEFAULT_PATH
  )
endif()

# 如果环境变量中没找到，继续尝试系统路径
if(NOT ITPP_INCLUDE_DIR OR NOT ITPP_LIBRARY)
  # 常规搜索路径
  find_path(ITPP_INCLUDE_DIR itpp/itcomm.h
    PATHS
    /opt/homebrew/include
    /usr/local/include
    /usr/include
  )
  
  set(ITPP_NAMES ${ITPP_NAMES} itpp libitpp libitpp.dll)
  find_library(ITPP_LIBRARY
    NAMES ${ITPP_NAMES}
    PATHS
    /opt/homebrew/lib
    /usr/local/lib
    /usr/lib
  )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ITPP DEFAULT_MSG ITPP_LIBRARY ITPP_INCLUDE_DIR)

# 打印发现的库和头文件位置，便于调试
if(ITPP_FOUND)
  message(STATUS "Found ITPP include: ${ITPP_INCLUDE_DIR}")
  message(STATUS "Found ITPP library: ${ITPP_LIBRARY}")
else()
  message(STATUS "Could NOT find ITPP")
endif()

# 标记为高级变量
mark_as_advanced(ITPP_INCLUDE_DIR ITPP_LIBRARY)
