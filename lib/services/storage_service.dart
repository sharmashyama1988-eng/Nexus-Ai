
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus_ai/models/chat_message.dart'; // Will be created
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Box? _secureBox;
  Box? _chatBox;
  bool _isUnlocked = false;

  bool get isUnlocked => _isUnlocked;

  Future<void> init() async {
    await Hive.initFlutter();
    // Register Adapter
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(ChatMessageAdapter());
    }
  }

  // Attempt to unlock storage with Master Password
  Future<bool> unlockOrInitialize(String password) async {
    // Derive 32-byte key from password
    var key = sha256.convert(utf8.encode(password)).bytes; 
    var encryptionCipher = HiveAesCipher(key);
    
    try {
      _secureBox = await Hive.openBox('secure_storage', encryptionCipher: encryptionCipher);
      
      // If successful, open chat box (can be unencrypted or same key)
      // For performance, chat history is unencrypted but could be encrypted if desired. 
      // User specifically requested API keys encryption. 
      _chatBox = await Hive.openBox('chat_history');
      
      _isUnlocked = true;
      return true;
    } catch (e) {
      print("Failed to unlock: $e");
      return false;
    }
  }

  Future<void> saveApiKey(String provider, String key) async {
    if (_secureBox == null) return;
    await _secureBox!.put('api_key_$provider', key);
  }

  String? getApiKey(String provider) {
    if (_secureBox == null) return null;
    return _secureBox!.get('api_key_$provider');
  }

  Future<void> saveChatHistory(List<ChatMessage> history) async {
    if (_chatBox == null) return;
    // Clearing and re-saving or appending. 
    // Simplified: Save as list under a key, or use Hive List directly.
    await _chatBox!.put('current_chat', history);
  }

  List<ChatMessage> getChatHistory() {
    if (_chatBox == null) return [];
    var data = _chatBox!.get('current_chat');
    if (data is List) {
      return data.cast<ChatMessage>();
    }
    return [];
  }
  
  // Export logic helpers
  Future<String> exportChatJson() async {
    final history = getChatHistory();
    final List<Map<String, dynamic>> jsonList = history.map((msg) => {
      'role': msg.role,
      'content': msg.content,
      'model': msg.model,
      'timestamp': msg.timestamp.toIso8601String()
    }).toList();
    
    return jsonEncode(jsonList);
  }
}

// Placeholder Adapter until generated
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage(
      content: reader.readString(),
      role: reader.readString(),
      timestamp: DateTime.parse(reader.readString()),
      model: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeString(obj.content);
    writer.writeString(obj.role);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.model);
  }
}
