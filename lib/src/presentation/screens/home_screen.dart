import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../screens/tts_settings_screen.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/recording_fab.dart';
import '../widgets/recording_indicator.dart';

/// Root screen for ZamVoice.
///
/// Dark theme (#0A0A0A bg), forest-green accent, chat list that scrolls
/// newest-at-bottom, centred hold-to-record FAB, inline recording indicator.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scroll = ScrollController();

  // Recording elapsed timer — driven locally so we don't pollute global state.
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  // ── recording timer ──────────────────────────────────────────────────

  void _startTimer() {
    _elapsed = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    setState(() => _elapsed = Duration.zero);
  }

  // ── auto-scroll ──────────────────────────────────────────────────────

  void _scrollToBottom() {
    // Schedule after the frame so the ListView has laid out the new item.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    final isRecording = state.status == AppState.recording;
    final isProcessing = state.status == AppState.processingWhisper ||
        state.status == AppState.uploading ||
        state.status == AppState.processingTts ||
        state.status == AppState.playingAudio;

    // Listen for new messages and auto-scroll.
    ref.listen<int>(
      appControllerProvider.select((s) => s.messages.length),
      (_, __) => _scrollToBottom(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'ZamVoice',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // ── Translate / Transcribe toggle ──
          _ModeChip(
            translateMode: state.translateMode,
            onChanged: isProcessing ? null : controller.setTranslateMode,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF9E9E9E)),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TtsSettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── recording indicator bar ──
          if (isRecording)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0D2E1A),
              child: RecordingIndicator(elapsed: _elapsed),
            ),

          // ── processing banner ──
          if (isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1A1A1A),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    state.processingText ?? 'Processing…',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),

          // ── chat list ──
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    // reverse: false → oldest at top, newest at bottom
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        key: ValueKey(state.messages[index].id),
                        message: state.messages[index],
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── centred action bar: upload + record FAB ──
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── upload button ──
          _ActionButton(
            icon: Icons.upload_file_rounded,
            label: 'Upload',
            onTap: isProcessing || isRecording
                ? null
                : controller.uploadAudio,
          ),
          const SizedBox(width: 20),
          // ── record FAB ──
          RecordingFab(
            isRecording: isRecording,
            isDisabled: isProcessing,
            onRecordStart: () {
              controller.startRecording();
              _startTimer();
            },
            onRecordStop: () {
              controller.stopRecording();
              _stopTimer();
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Small private widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Translate / Transcribe pill toggle in the app bar.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.translateMode, required this.onChanged});

  final bool translateMode;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChipSegment(
            label: 'Translate',
            selected: translateMode,
            onTap: onChanged == null ? null : () => onChanged!(true),
          ),
          _ChipSegment(
            label: 'Transcribe',
            selected: !translateMode,
            onTap: onChanged == null ? null : () => onChanged!(false),
          ),
        ],
      ),
    );
  }
}

class _ChipSegment extends StatelessWidget {
  const _ChipSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const _accent = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _accent : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}

/// Shown when the chat list is empty.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_none_rounded, size: 48, color: Color(0xFF2A2A2A)),
          SizedBox(height: 12),
          Text(
            'Hold the mic to record',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF616161),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'or upload an audio file',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small labelled icon button used alongside the recording FAB.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  static const _accent = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: _accent.withValues(alpha: enabled ? 0.3 : 0.12),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: enabled
                    ? _accent.withValues(alpha: 0.8)
                    : const Color(0xFF424242),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}
