#include <whisper.h>
#include <string.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for Dart
typedef struct {
    whisper_context* ctx;
} WhisperHandle;

/// Initialize whisper from a model file.
/// Returns an opaque pointer to be used in subsequent calls.
WhisperHandle* whisper_ffi_init_from_file(const char* model_path) {
    if (!model_path) {
        return NULL;
    }
    
    struct whisper_context* ctx = whisper_init_from_file(model_path);
    if (!ctx) {
        return NULL;
    }
    
    WhisperHandle* handle = (WhisperHandle*)malloc(sizeof(WhisperHandle));
    if (!handle) {
        whisper_free(ctx);
        return NULL;
    }
    
    handle->ctx = ctx;
    return handle;
}

/// Run transcription on audio file with optional translation.
/// Returns a pointer to the transcribed text (must be freed by caller).
char* whisper_ffi_transcribe(
    WhisperHandle* handle,
    const char* audio_path,
    int translate_flag,
    const char* language
) {
    if (!handle || !handle->ctx || !audio_path) {
        return NULL;
    }
    
    struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    
    // Set language
    if (language && language[0] != '\0') {
        params.language = language;
    } else {
        params.language = "auto";
    }
    
    // Set translation mode
    params.translate = translate_flag ? true : false;
    
    params.print_progress = 0;
    params.print_special = 0;
    params.print_realtime = 0;
    params.print_timestamps = 0;
    
    // Run the full transcription
    int result = whisper_full_from_file(handle->ctx, params, audio_path);
    if (result != 0) {
        return NULL;
    }
    
    // Get the result
    int n_segments = whisper_full_n_segment(handle->ctx);
    size_t total_length = 1; // for null terminator
    
    // Calculate total length needed
    for (int i = 0; i < n_segments; i++) {
        const char* text = whisper_full_get_segment_text(handle->ctx, i);
        if (text) {
            total_length += strlen(text);
        }
    }
    
    // Allocate and build result string
    char* result_text = (char*)malloc(total_length);
    if (!result_text) {
        return NULL;
    }
    
    result_text[0] = '\0';
    for (int i = 0; i < n_segments; i++) {
        const char* text = whisper_full_get_segment_text(handle->ctx, i);
        if (text) {
            strcat(result_text, text);
        }
    }
    
    return result_text;
}

/// Free a transcription result string.
void whisper_ffi_free_string(char* str) {
    if (str) {
        free(str);
    }
}

/// Free a whisper handle and its context.
void whisper_ffi_free_handle(WhisperHandle* handle) {
    if (handle) {
        if (handle->ctx) {
            whisper_free(handle->ctx);
        }
        free(handle);
    }
}

#ifdef __cplusplus
}
#endif
