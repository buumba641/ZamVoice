cmake_minimum_required(VERSION 3.10)
project(whisper_bridge C CXX)

set(CMAKE_CXX_STANDARD 17)

include(FetchContent)

# ---------- Auto-download whisper.cpp ----------
# If WHISPER_SRC_DIR is not provided (i.e. Gradle CMake integration),
# download whisper.cpp automatically via FetchContent.
if(NOT DEFINED WHISPER_SRC_DIR)
    set(WHISPER_TAG "v1.7.4")
    FetchContent_Declare(
        whisper_src
        GIT_REPOSITORY "https://github.com/ggml-org/whisper.cpp.git"
        GIT_TAG        "${WHISPER_TAG}"
        GIT_SHALLOW    TRUE
    )
    FetchContent_GetProperties(whisper_src)
    if(NOT whisper_src_POPULATED)
        FetchContent_Populate(whisper_src)
    endif()
    set(WHISPER_SRC_DIR "${whisper_src_SOURCE_DIR}")
    message(STATUS "whisper.cpp downloaded to: ${WHISPER_SRC_DIR}")
endif()

# ---------- Source files ----------
set(SOURCE_FILES
    ${WHISPER_SRC_DIR}/src/whisper.cpp
    ${CMAKE_SOURCE_DIR}/whisper_bridge.c
)

find_library(LOG_LIB log)

# ---------- Build shared library ----------
add_library(whisper_bridge SHARED ${SOURCE_FILES})

target_compile_definitions(whisper_bridge PUBLIC GGML_USE_CPU)

# Extract version string from the upstream CMakeLists.txt so that the
# WHISPER_VERSION macro is defined (avoids the "undeclared identifier" error
# that broke whisper_ggml_plus).
file(READ "${WHISPER_SRC_DIR}/CMakeLists.txt" _MAIN_CMAKE)
string(REGEX MATCH "project\\(\"whisper\\.cpp\" VERSION ([0-9]+\\.[0-9]+\\.[0-9]+)\\)"
       _VERSION_MATCH "${_MAIN_CMAKE}")
if(CMAKE_MATCH_1)
    set(_WHISPER_VER ${CMAKE_MATCH_1})
else()
    set(_WHISPER_VER "unknown")
endif()
target_compile_definitions(whisper_bridge PRIVATE WHISPER_VERSION="${_WHISPER_VER}")

# ARM v8.2 fp16 intrinsics for faster inference on modern devices.
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(whisper_bridge PRIVATE -march=armv8.2-a+fp16)
endif()

# ---------- Release optimisations ----------
if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    target_compile_options(whisper_bridge PRIVATE
        -O3
        -fvisibility=hidden
        -fvisibility-inlines-hidden
        -ffunction-sections
        -fdata-sections
    )
    target_link_options(whisper_bridge PRIVATE
        -Wl,--gc-sections
        -Wl,--exclude-libs,ALL
        -flto
    )
endif()

# ---------- Pull in ggml (tensor library used by whisper.cpp) ----------
FetchContent_Declare(ggml SOURCE_DIR ${WHISPER_SRC_DIR}/ggml)
FetchContent_MakeAvailable(ggml)
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(ggml PRIVATE -march=armv8.2-a+fp16)
endif()

target_link_libraries(whisper_bridge ${LOG_LIB} android ggml)

# ---------- Include paths ----------
target_include_directories(whisper_bridge PRIVATE
    ${WHISPER_SRC_DIR}
    ${WHISPER_SRC_DIR}/src
    ${WHISPER_SRC_DIR}/include
    ${WHISPER_SRC_DIR}/ggml/include
    ${WHISPER_SRC_DIR}/ggml/src
    ${WHISPER_SRC_DIR}/ggml/src/ggml-cpu
)
