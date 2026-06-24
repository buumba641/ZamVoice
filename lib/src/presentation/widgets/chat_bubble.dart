import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/chat_message.dart';

/// A single chat bubble in the message list.
///
/// User-side audio entries are right-aligned with a green tint.
/// Translation/transcription results are left-aligned on a white card.
/// System/error messages are centered with a red tint.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  // ── colour constants ────────────────────────────────────────────────
  static const _cardColor = Color(0xFF1A1A1A);
  static const _accentGreen = Color(0xFF00C853);
  static const _userBubbleColor = Color(0x2600C853); // 15 % opacity green
  static const _errorColor = Color(0x33FF5252);

  @override
  Widget build(BuildContext context) {
    final isSystem = message.type == ChatMessageType.system;
    final isUser = message.type == ChatMessageType.userAudio ||
        message.type == ChatMessageType.uploadedAudio;
    final isResult = message.type == ChatMessageType.translation ||
        message.type == ChatMessageType.transcription;

    // Alignment
    final alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    // Colours
    final Color bgColor;
    if (message.isError) {
      bgColor = _errorColor;
    } else if (isUser) {
      bgColor = _userBubbleColor;
    } else {
      bgColor = _cardColor;
    }

    // Title text
    final title = _titleFor(message.type, message.isError);
    final time = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isSystem ? Alignment.center : alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GestureDetector(
            onTap: isResult ? () => _copyText(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: isUser
                    ? Border.all(color: _accentGreen.withValues(alpha: 0.25))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── header row ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isError)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.error_outline,
                              size: 14, color: Color(0xFFFF5252)),
                        ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── body text ──
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isError
                          ? const Color(0xFFFF8A80)
                          : Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
                  ),

                  // ── duration badge (audio bubbles) ──
                  if (isUser && message.duration != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 12,
                              color: _accentGreen.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(message.duration!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── copy hint (results) ──
                  if (isResult)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Tap to copy',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF616161),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _titleFor(ChatMessageType type, bool isError) {
    switch (type) {
      case ChatMessageType.userAudio:
        return 'RECORDED';
      case ChatMessageType.uploadedAudio:
        return 'UPLOADED';
      case ChatMessageType.translation:
        return 'TRANSLATION';
      case ChatMessageType.transcription:
        return 'TRANSCRIPTION';
      case ChatMessageType.tts:
        return 'TTS';
      case ChatMessageType.system:
        return isError ? 'ERROR' : 'SYSTEM';
    }
  }

  static String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }
}
