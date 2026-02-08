
import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final String role; // 'user' or 'assistant'

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String model;

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
    required this.model,
  });
}
