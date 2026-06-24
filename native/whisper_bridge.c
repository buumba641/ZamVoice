/**
 * whisper_bridge.c — Thin C bridge for Dart FFI access to whisper.cpp.
 *
 * Exposes three simple functions so that Dart never needs to deal with the
 * complex whisper_full_params struct:
 *   bridge_init(model_path)   → opaque context pointer
 *   bridge_infer(ctx, samples, n, translate) → result text (static buffer)
 *   bridge_free(ctx)          → cleanup
 */

#include "whisper.h"
#include <stdlib.h>
#include <string.h>
#include <android/log.h>

#define LOG_TAG "WhisperBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

/* Ensure symbols survive -fvisibility=hidden in Release builds. */
#define BRIDGE_API __attribute__((visibility("default")))

/* ------------------------------------------------------------------ */

BRIDGE_API void *bridge_init(const char *model_path) {
    struct whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu   = false;
    cparams.flash_attn = false;

    LOGI("Loading model: %s", model_path);
    struct whisper_context *ctx =
        whisper_init_from_file_with_params(model_path, cparams);

    if (ctx == NULL) {
        LOGI("Failed to initialise whisper context");
    } else {
        LOGI("Whisper context ready");
    }
    return (void *)ctx;
}

/* ------------------------------------------------------------------ */

/* 16 KiB static buffer — safe because the app processes one task at a
   time through the serial WhisperQueue. */
static char result_buffer[16384];

BRIDGE_API const char *bridge_infer(void *ctx_ptr,
                                    const float *samples,
                                    int n_samples,
                                    int translate) {
    struct whisper_context *ctx = (struct whisper_context *)ctx_ptr;
    if (ctx == NULL) return "";

    struct whisper_full_params params =
        whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

    params.translate        = translate ? true : false;
    params.language         = "auto";
    params.n_threads        = 4;
    params.print_special    = false;
    params.print_progress   = false;
    params.print_realtime   = false;
    params.print_timestamps = false;
    params.no_context       = true;
    params.single_segment   = false;

    LOGI("Inference: %d samples, translate=%d", n_samples, translate);

    if (whisper_full(ctx, params, samples, n_samples) != 0) {
        LOGI("whisper_full() failed");
        return "";
    }

    /* Concatenate every segment into result_buffer. */
    result_buffer[0] = '\0';
    const int n_segments = whisper_full_n_segments(ctx);
    LOGI("Segments: %d", n_segments);

    size_t offset = 0;
    for (int i = 0; i < n_segments; i++) {
        const char *text = whisper_full_get_segment_text(ctx, i);
        if (text) {
            size_t len = strlen(text);
            if (offset + len < sizeof(result_buffer) - 1) {
                memcpy(result_buffer + offset, text, len);
                offset += len;
            }
        }
    }
    result_buffer[offset] = '\0';
    return result_buffer;
}

/* ------------------------------------------------------------------ */

BRIDGE_API void bridge_free(void *ctx_ptr) {
    struct whisper_context *ctx = (struct whisper_context *)ctx_ptr;
    if (ctx != NULL) {
        whisper_free(ctx);
        LOGI("Whisper context freed");
    }
}
