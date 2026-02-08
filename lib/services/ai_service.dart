
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:nexus_ai/models/chat_message.dart';
import 'package:nexus_ai/services/storage_service.dart';

enum AiProvider { openAI, claude, gemini }

class AiService {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  AiService() {
    _dio.options.validateStatus = (status) => true; // Handle errors manually
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 40);
  }

  Future<String> sendMessage(String message, String model, List<ChatMessage> history) async {
    // Determine provider based on model string
    if (model.toLowerCase().contains('gpt')) {
      return _callOpenAI(message, model, history);
    } else if (model.toLowerCase().contains('claude')) {
      return _callClaude(message, model, history);
    } else if (model.toLowerCase().contains('gemini')) {
      return _callGemini(message, model, history);
    }
    throw Exception("Unknown model provider for $model");
  }

  // --- OpenAI ---
  Future<String> _callOpenAI(String message, String model, List<ChatMessage> history) async {
    final apiKey = _storage.getApiKey('openai');
    if (apiKey == null || apiKey.isEmpty) throw Exception("OpenAI API Key not found");

    final messages = history.map((msg) => {
      "role": msg.role,
      "content": msg.content
    }).toList();
    messages.add({"role": "user", "content": message});

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        "model": model,
        "messages": messages,
      },
    );

    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'];
    } else {
      throw Exception("OpenAI Error: ${response.statusCode} - ${response.data}");
    }
  }

  // --- Claude (Anthropic) ---
  Future<String> _callClaude(String message, String model, List<ChatMessage> history) async {
    final apiKey = _storage.getApiKey('claude');
    if (apiKey == null || apiKey.isEmpty) throw Exception("Claude API Key not found");

    // Claude expects "user" and "assistant" roles. System prompt separate.
    final messages = history.where((m) => m.role != 'system').map((msg) => {
      "role": msg.role,
      "content": msg.content
    }).toList();
    messages.add({"role": "user", "content": message});

    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      }),
      data: {
        "model": model,
        "max_tokens": 1024,
        "messages": messages,
      },
    );

    if (response.statusCode == 200) {
      return response.data['content'][0]['text'];
    } else {
      throw Exception("Claude Error: ${response.statusCode} - ${response.data}");
    }
  }

  // --- Gemini (Google) ---
  Future<String> _callGemini(String message, String model, List<ChatMessage> history) async {
    final apiKey = _storage.getApiKey('gemini');
    if (apiKey == null || apiKey.isEmpty) throw Exception("Gemini API Key not found");

    // Gemini format: contents: [{role: "user", parts: [{text: "..."}]}]
    final contents = history.map((msg) => {
      "role": msg.role == 'assistant' ? 'model' : 'user',
      "parts": [{"text": msg.content}]
    }).toList();
    contents.add({
      "role": "user",
      "parts": [{"text": message}]
    });

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        "contents": contents,
      },
    );

    if (response.statusCode == 200) {
      // Gemini structure is slightly deep
      final candidates = response.data['candidates'] as List;
      if (candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        return parts.map((p) => p['text']).join('\n');
      }
      return "";
    } else {
      throw Exception("Gemini Error: ${response.statusCode} - ${response.data}");
    }
  }
}
