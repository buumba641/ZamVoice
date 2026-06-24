import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Native C function signatures (how the C functions look in the .so)
// ---------------------------------------------------------------------------
typedef _BridgeInitC = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef _BridgeInferC = Pointer<Utf8> Function(
    Pointer<Void> ctx,
    Pointer<Float> samples,
    Int32 nSamples,
    Int32 translate,
);
typedef _BridgeFreeC = Void Function(Pointer<Void> ctx);

// ---------------------------------------------------------------------------
// Dart-side callable signatures
// ---------------------------------------------------------------------------
typedef _BridgeInitDart = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef _BridgeInferDart = Pointer<Utf8> Function(
    Pointer<Void> ctx,
    Pointer<Float> samples,
    int nSamples,
    int translate,
);
typedef _BridgeFreeDart = void Function(Pointer<Void> ctx);

/// Dart FFI bindings for the three `bridge_*` functions exported by
/// `libwhisper_bridge.so`.
class WhisperFfiBindings {
  WhisperFfiBindings() {
    final lib = DynamicLibrary.open('libwhisper_bridge.so');

    init = lib.lookupFunction<_BridgeInitC, _BridgeInitDart>('bridge_init');
    infer = lib.lookupFunction<_BridgeInferC, _BridgeInferDart>('bridge_infer');
    free = lib.lookupFunction<_BridgeFreeC, _BridgeFreeDart>('bridge_free');
  }

  late final _BridgeInitDart init;
  late final _BridgeInferDart infer;
  late final _BridgeFreeDart free;
}
