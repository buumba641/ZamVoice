import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import 'tts_settings_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final isRecording = state.status == AppState.recording;
    final isProcessing = state.status == AppState.processingWhisper ||
      state.status == AppState.uploading ||
      state.status == AppState.processingTts ||
      state.status == AppState.playingAudio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZamVoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TtsSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const _DomainWarningCard(),
          if (state.processingText != null)
            _ProcessingBanner(text: state.processingText!),
          Expanded(
            child: state.messages.isEmpty
                ? Center(
                    child: Text(
                      'Ready to record or upload audio.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          _ActionBar(
            isRecording: isRecording,
            isProcessing: isProcessing,
            translateMode: state.translateMode,
            onTranslateModeChanged: controller.setTranslateMode,
            onRecordStart: controller.startRecording,
            onRecordStop: controller.stopRecording,
            onUpload: controller.uploadAudio,
          ),
        ],
      ),
    );
  }
}

class _DomainWarningCard extends StatelessWidget {
  const _DomainWarningCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domain & Accuracy Notice',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'This model is trained on conversational speech and may produce '
              'artifacts outside that domain. Please verify outputs.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingBanner extends StatelessWidget {
  const _ProcessingBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.type == ChatMessageType.system;
    final isUserAudio = message.type == ChatMessageType.userAudio ||
        message.type == ChatMessageType.uploadedAudio;
    final isResult = message.type == ChatMessageType.translation ||
        message.type == ChatMessageType.transcription;
    final bubbleColor = isSystem
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final title = _titleForMessage(message);
    final time = _formatTime(message.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isSystem ? Alignment.center : Alignment.centerLeft,
        child: InkWell(
          onTap: isResult
              ? () async {
                  await Clipboard.setData(ClipboardData(text: message.text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard.')),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (isUserAudio && message.duration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatDuration(message.duration!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (isResult)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Tap to copy',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForMessage(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.userAudio:
        return 'Recorded audio';
      case ChatMessageType.uploadedAudio:
        return 'Uploaded audio';
      case ChatMessageType.translation:
        return 'Translation';
      case ChatMessageType.transcription:
        return 'Transcription';
      case ChatMessageType.tts:
        return 'TTS';
      case ChatMessageType.system:
        return message.isError ? 'Error' : 'System';
    }
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isRecording,
    required this.isProcessing,
    required this.translateMode,
    required this.onTranslateModeChanged,
    required this.onRecordStart,
    required this.onRecordStop,
    required this.onUpload,
  });

  final bool isRecording;
  final bool isProcessing;
  final bool translateMode;
  final ValueChanged<bool> onTranslateModeChanged;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: isProcessing || isRecording ? null : onUpload,
              icon: const Icon(Icons.upload_file),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Translate'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Transcribe'),
                ),
              ],
              selected: {translateMode},
              onSelectionChanged: isProcessing
                  ? null
                  : (value) {
                      onTranslateModeChanged(value.first);
                    },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IgnorePointer(
                ignoring: isProcessing,
                child: GestureDetector(
                  onLongPressStart: (_) => onRecordStart(),
                  onLongPressEnd: (_) => onRecordStop(),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isRecording
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        isProcessing
                            ? 'Processing...'
                            : isRecording
                                ? 'Release to stop'
                                : 'Hold to record',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
