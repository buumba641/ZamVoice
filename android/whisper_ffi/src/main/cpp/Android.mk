LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := whisper
LOCAL_SRC_FILES := \
    whisper/ggml.c \
    whisper/ggml-quants.c \
    whisper/whisper.cpp

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/whisper \
    $(LOCAL_PATH)/whisper/include

LOCAL_CFLAGS := \
    -fPIC \
    -fvisibility=hidden \
    -O3 \
    -DNDEBUG

LOCAL_CPPFLAGS := \
    $(LOCAL_CFLAGS) \
    -std=c++17

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := whisper_ffi
LOCAL_SRC_FILES := whisper_ffi.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/whisper $(LOCAL_PATH)/whisper/include
LOCAL_STATIC_LIBRARIES := whisper
LOCAL_CFLAGS := -fvisibility=hidden
LOCAL_CPPFLAGS := -std=c++17

include $(BUILD_SHARED_LIBRARY)
