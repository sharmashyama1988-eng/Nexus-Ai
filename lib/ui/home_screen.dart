
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_ai/models/chat_message.dart';
import 'package:nexus_ai/services/ai_service.dart';
import 'package:nexus_ai/services/audio_service.dart';
import 'package:nexus_ai/services/storage_service.dart';
import 'package:nexus_ai/ui/settings_screen.dart';
import 'package:nexus_ai/utils/constants.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final AudioService _audioService = AudioService();
  final StorageService _storage = StorageService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isVoiceEnabled = false;
  String _selectedModel = 'gpt-4'; // Default
  
  // Available models
  final List<String> _models = [
    'gpt-4',
    'gpt-3.5-turbo',
    'gemini-1.5-pro',
    'claude-3-opus',
    'claude-3-sonnet',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final history = _storage.getChatHistory();
    setState(() {
      _messages = history;
    });
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      content: text,
      role: 'user',
      timestamp: DateTime.now(),
      model: _selectedModel,
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Persist immediately
    _storage.saveChatHistory(_messages);

    try {
      final response = await _aiService.sendMessage(text, _selectedModel, _messages);
      
      final aiMsg = ChatMessage(
        content: response,
        role: 'assistant',
        timestamp: DateTime.now(),
        model: _selectedModel,
      );

      setState(() {
        _messages.add(aiMsg);
        _isLoading = false;
      });
      _scrollToBottom();
      _storage.saveChatHistory(_messages);

      if (_isVoiceEnabled) {
        await _audioService.playTextToSpeech(response);
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          content: "Error: $e",
          role: 'system',
          timestamp: DateTime.now(),
          model: 'system',
        ));
      });
    }
  }

  Future<void> _exportChat() async {
    try {
      final json = await _storage.exportChatJson();
      // On Windows desktop, save to Desktop?
      // Better: use user's explicit path or default Documents.
      // User requested "to the user's desktop".
      // We can try to get desktop path via environment vars.
      
      String? desktopPath;
      if (Platform.isWindows) {
         desktopPath = '${Platform.environment['USERPROFILE']}\\Desktop';
      } else {
         // Fallback
         final dir = await getApplicationDocumentsDirectory();
         desktopPath = dir.path;
      }
      
      final file = File('$desktopPath/nexus_chat_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exported to ${file.path}")));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Failed: $e")));
      }
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsScreen(),
    ).then((_) {
      // Refresh state if needed (e.g. keys updated)
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.sidebar,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nexus AI",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),
                _SidebarButton(
                  icon: LucideIcons.plusCircle,
                  label: "New Chat",
                  onTap: () {
                    setState(() {
                      _messages.clear();
                      _storage.saveChatHistory([]);
                    });
                  },
                ),
                _SidebarButton(
                  icon: LucideIcons.key,
                  label: "Keys Management",
                  onTap: _openSettings,
                ),
                _SidebarButton(
                  icon: LucideIcons.download,
                  label: "Export History",
                  onTap: _exportChat,
                ),
                const Spacer(),
                const Divider(color: Colors.white24),
                // System Health Widget
                ListTile(
                  leading: Icon(
                    _storage.getApiKey(_selectedModel.split('-')[0]) != null 
                    ? LucideIcons.checkCircle 
                    : LucideIcons.alertTriangle,
                    color: _storage.getApiKey(_selectedModel.split('-')[0]) != null 
                    ? AppColors.success 
                    : AppColors.error,
                  ),
                  title: const Text("System Status", style: TextStyle(fontSize: 12)),
                  subtitle: Text(_storage.getApiKey('openai') != null ? "Online" : "Missing Keys", style: const TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          // Chat Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: AppColors.sidebar.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Text("Model: "),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedModel,
                        dropdownColor: AppColors.sidebar,
                        underline: Container(),
                        items: _models.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(color: AppColors.text)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedModel = val);
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isVoiceEnabled ? LucideIcons.volume2 : LucideIcons.volumeX,
                          color: _isVoiceEnabled ? AppColors.accent : Colors.grey,
                        ),
                        onPressed: () => setState(() => _isVoiceEnabled = !_isVoiceEnabled),
                        tooltip: "Toggle Voice Synergy",
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 600),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primary.withOpacity(0.2) : AppColors.sidebar,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUser ? AppColors.primary.withOpacity(0.5) : Colors.white10,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUser ? LucideIcons.user : LucideIcons.bot,
                                    size: 16,
                                    color: isUser ? AppColors.primary : AppColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUser ? "You" : msg.model, // Show model used
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(
                                data: msg.content,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 14, color: AppColors.text),
                                  code: const TextStyle(backgroundColor: Colors.black26, fontFamily: 'monospace'),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const LinearProgressIndicator(color: AppColors.accent, backgroundColor: Colors.transparent),
                // Input Area
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.sidebar,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            filled: true,
                            fillColor: Colors.black12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        backgroundColor: AppColors.primary,
                        child: const Icon(LucideIcons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
