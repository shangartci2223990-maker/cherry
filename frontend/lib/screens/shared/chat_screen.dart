import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final int appointmentId;
  final String otherPersonLabel;

  const ChatScreen({
    super.key,
    required this.appointmentId,
    required this.otherPersonLabel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> messages = [];
  bool isLoading = true;
  bool _connected = false;
  String? _bannerMessage;
  bool _bannerIsError = false;

  WebSocketChannel? _channel;
  bool _disposed = false;

  late final String myWallet;

  // Voice
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  int? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    myWallet = AuthService().state.value.wallet ?? '';
    _connectWebSocket();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingId = null);
    });
  }

  void _setBanner(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() { _bannerMessage = message; _bannerIsError = isError; });
  }

  void _clearBanner() {
    if (!mounted) return;
    setState(() => _bannerMessage = null);
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.wsUrl}/messages/ws/${widget.appointmentId}'),
    );

    _channel!.ready.then((_) {
      if (!mounted) return;
      setState(() { isLoading = false; _connected = true; });
      _clearBanner();
    }).catchError((_) {
      _setBanner('Could not connect', isError: true);
      if (mounted) setState(() => isLoading = false);
    });

    _channel!.stream.listen(
      (data) {
        final message = jsonDecode(data as String);
        if (message.containsKey('error')) {
          _setBanner(message['error'], isError: true);
          return;
        }
        setState(() {
          messages.add(message);
          isLoading = false;
        });
        scrollToBottom();
      },
      onError: (_) => _setBanner('Connection error', isError: true),
      onDone: () {
        final code = _channel?.closeCode;
        if (mounted) setState(() => _connected = false);
        if (code == 4004) {
          _setBanner('Session not found', isError: true);
        } else {
          _setBanner('Reconnecting...');
          _scheduleReconnect();
        }
      },
    );
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (_disposed || !mounted) return;
      setState(() { messages = []; isLoading = true; });
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      _channel?.sink.add(jsonEncode({
        'sender_wallet': myWallet,
        'content': text,
      }));
    } catch (e) {
      _setBanner('Failed to send message', isError: true);
      Future.delayed(const Duration(seconds: 3), () {
        if (_bannerMessage == 'Failed to send message') _clearBanner();
      });
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _setBanner('Microphone permission denied', isError: true);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null || !_connected) return;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/messages/upload-audio');
      final request = http.MultipartRequest('POST', uri)
        ..fields['appointment_id'] = widget.appointmentId.toString()
        ..fields['sender_wallet'] = myWallet
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          path,
          contentType: MediaType('audio', 'mp4'),
        ));
      await request.send();
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      _setBanner('Failed to send voice message', isError: true);
    }
  }

  Future<void> _togglePlay(int messageId, String fileUrl) async {
    if (_currentlyPlayingId == messageId) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource('${ApiConstants.baseUrl}$fileUrl'));
        setState(() => _currentlyPlayingId = messageId);
      } catch (_) {
        _setBanner('Could not play audio', isError: true);
      }
    }
  }

  String _formatTime(String raw) {
    final dt = DateTime.parse(raw.endsWith('Z') ? raw : '${raw}Z').toLocal();
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String shortenWallet(String wallet) {
    if (wallet.length < 10) return wallet;
    return '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}';
  }

  Widget _buildMessageBubble(dynamic message) {
    final isMe = message['sender_wallet'] == myWallet;
    if (message['media_type'] == 'voice') {
      return _buildVoiceBubble(message, isMe);
    }
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.chatMe : AppColors.chatOther,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : shortenWallet(message['sender_wallet']),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              message['content'] ?? '',
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['sent_at']),
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(dynamic message, bool isMe) {
    final id = message['id'] as int;
    final isPlaying = _currentlyPlayingId == id;
    final fileUrl = message['file_url'] as String;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.chatMe : AppColors.chatOther,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : shortenWallet(message['sender_wallet']),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _togglePlay(id, fileUrl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Voice',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['sent_at']),
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _isRecording ? 'Recording...' : 'Type a message...',
                hintStyle: TextStyle(
                  color: _isRecording ? AppColors.primary : const Color(0xFFAAAAAA),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          if (hasText)
            CircleAvatar(
              backgroundColor: _connected ? AppColors.primary : const Color(0xFFE8E8E8),
              child: IconButton(
                onPressed: _connected ? sendMessage : null,
                icon: Icon(
                  Icons.send,
                  color: _connected ? Colors.white : const Color(0xFFAAAAAA),
                  size: 18,
                ),
              ),
            )
          else
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecordingAndSend(),
              child: CircleAvatar(
                backgroundColor: _isRecording
                    ? Colors.red
                    : (_connected ? AppColors.primary : const Color(0xFFE8E8E8)),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: (_connected || _isRecording) ? Colors.white : const Color(0xFFAAAAAA),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shortenWallet(widget.otherPersonLabel),
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
            Text(
              'Session active',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [

          if (_bannerMessage != null)
            Container(
              width: double.infinity,
              color: (_bannerIsError ? AppColors.primary : AppColors.chatOther).withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                _bannerMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _bannerIsError ? AppColors.primary : AppColors.chatOther,
                  fontSize: 13,
                ),
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(fontSize: 16, color: AppColors.text),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessageBubble(messages[index]),
                      ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }
}
