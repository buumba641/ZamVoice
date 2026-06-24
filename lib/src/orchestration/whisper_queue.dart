import 'whisper_task.dart';

class WhisperQueue {
  final _queue = <WhisperTask>[];
  bool _isProcessing = false;
  Future<void> Function(WhisperTask task)? _handler;

  void setHandler(Future<void> Function(WhisperTask task) handler) {
    _handler = handler;
  }

  void enqueue(WhisperTask task) {
    _queue.add(task);
    _drain();
  }

  Future<void> _drain() async {
    if (_isProcessing || _queue.isEmpty || _handler == null) {
      return;
    }

    _isProcessing = true;
    final task = _queue.removeAt(0);
    await _handler!(task);
    _isProcessing = false;
    if (_queue.isNotEmpty) {
      await _drain();
    }
  }
}
