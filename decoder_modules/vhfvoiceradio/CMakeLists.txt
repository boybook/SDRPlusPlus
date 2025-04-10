cmake_minimum_required(VERSION 3.13)
project(vhfvoiceradio)

# 分别收集C++和C源文件，排除头文件
file(GLOB_RECURSE CPP_SRC "src/*.cpp")
file(GLOB_RECURSE C_SRC "mbelib/*.c")

# 合并所有源文件，这将被sdrpp_module.cmake使用
set(SRC ${CPP_SRC} ${C_SRC})

# 添加config.h头文件
include_directories(${CMAKE_SOURCE_DIR}/core/src)

# 检查是否在Android环境下编译
if (ANDROID)
    message(STATUS "Building for Android platform with ANDROID_ABI: ${ANDROID_ABI}")
    
    # 硬编码ITPP头文件和库路径，参考airspy_source的做法
    set(ITPP_INCLUDE_DIR /sdr-kit/${ANDROID_ABI}/include)
    set(ITPP_LIBRARY /sdr-kit/${ANDROID_ABI}/lib/libitpp.so)
    
    # 同样硬编码FFTW3F和VOLK库路径
    set(FFTW3F_LIBRARY /sdr-kit/${ANDROID_ABI}/lib/libfftw3f.so)
    set(VOLK_LIBRARY /sdr-kit/${ANDROID_ABI}/lib/libvolk.so)
    
    message(STATUS "Using hardcoded library paths for Android:")
    message(STATUS "ITPP Include: ${ITPP_INCLUDE_DIR}")
    message(STATUS "ITPP Library: ${ITPP_LIBRARY}")
    message(STATUS "FFTW3F Library: ${FFTW3F_LIBRARY}")
    message(STATUS "VOLK Library: ${VOLK_LIBRARY}")
    
    # 添加Android特定的编译选项，禁用相关警告
    add_compile_options(
        -Wno-register 
        -Wno-error=register
        -Wno-format-security
        -Wno-format
    )
else()
    # 对于macOS和其他系统，使用之前的查找逻辑
    # 设置 CMAKE_MODULE_PATH 以便找到 FindITPP.cmake 文件
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")
    find_package(ITPP REQUIRED)
    # macOS环境特定的包含路径和链接目录
    include_directories(/opt/homebrew/include)
    link_directories(/usr/local/lib /opt/homebrew/lib)
    
    # 在 macOS 上，需要特别处理以确保 Accelerate 框架可以被找到
    if(APPLE)
        message(STATUS "Building for macOS, linking with Accelerate framework")
        find_library(ACCELERATE_FRAMEWORK Accelerate REQUIRED)
        if(ACCELERATE_FRAMEWORK)
            message(STATUS "Found Accelerate Framework: ${ACCELERATE_FRAMEWORK}")
        endif()
    endif()
endif()

# 引入SDK模块构建脚本，它会使用SRC变量创建库
include(${SDRPP_MODULE_CMAKE})

# 为C文件设置C标准而不是C++标准
set_source_files_properties(${C_SRC} PROPERTIES LANGUAGE C)
# 为C++文件保留C++17标准
set_source_files_properties(${CPP_SRC} PROPERTIES COMPILE_OPTIONS "${SDRPP_MODULE_COMPILER_FLAGS}")
# 为C文件设置C11标准
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    set_source_files_properties(${C_SRC} PROPERTIES COMPILE_OPTIONS "-std=c11")
else()
    set_source_files_properties(${C_SRC} PROPERTIES COMPILE_OPTIONS "-std=gnu11")
endif()

# 添加必要的头文件路径
target_include_directories(vhfvoiceradio PRIVATE 
    "src/" 
    "mbelib/"
    ${ITPP_INCLUDE_DIR}
    "${SDRPP_CORE_ROOT}" 
    "${SDRPP_CORE_ROOT}/imgui/"
)

# 确保mbelib的实现文件被正确编译和链接
target_sources(vhfvoiceradio PRIVATE 
    "mbelib/ambe3600x2400.c"
    "mbelib/ambe3600x2450.c"
    "mbelib/ecc.c"
    "mbelib/imbe7100x4400.c"
    "mbelib/imbe7200x4400.c"
    "mbelib/mbelib.c"
)

# 链接必要的库
if (ANDROID)
    # 对于Android，使用硬编码的库路径
    target_link_libraries(vhfvoiceradio PRIVATE ${FFTW3F_LIBRARY} ${VOLK_LIBRARY} ${ITPP_LIBRARY})
else()
    # 对于其他平台，使用系统库
    target_link_libraries(vhfvoiceradio PRIVATE fftw3f volk ${ITPP_LIBRARY})
    
    # 为 macOS 添加 Accelerate 框架
    if(APPLE)
        # 直接使用绝对路径链接 Accelerate 框架
        target_link_libraries(vhfvoiceradio PRIVATE "-framework Accelerate")
        
        # 设置正确的安装路径相关性和运行时搜索路径
        set_target_properties(vhfvoiceradio PROPERTIES
            INSTALL_RPATH "@loader_path/../Frameworks;@executable_path/../Frameworks;/System/Library/Frameworks"
            BUILD_WITH_INSTALL_RPATH TRUE
            INSTALL_NAME_DIR "@rpath"
        )
        
        # 添加针对 libitpp 库的修复
        add_custom_command(TARGET vhfvoiceradio POST_BUILD
            COMMAND install_name_tool -change @rpath/Accelerate /System/Library/Frameworks/Accelerate.framework/Accelerate ${CMAKE_BINARY_DIR}/decoder_modules/vhfvoiceradio/vhfvoiceradio.dylib
            COMMENT "Fixing Accelerate framework path in vhfvoiceradio.dylib"
        )
    endif()
endif()