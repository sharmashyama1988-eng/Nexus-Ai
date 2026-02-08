
import 'package:flutter/material.dart';
import 'package:nexus_ai/services/storage_service.dart';
import 'package:nexus_ai/utils/constants.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final _openAIController = TextEditingController();
  final _geminiController = TextEditingController();
  final _claudeController = TextEditingController();
  final _elevenLabsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() {
    _openAIController.text = _storage.getApiKey('openai') ?? '';
    _geminiController.text = _storage.getApiKey('gemini') ?? '';
    _claudeController.text = _storage.getApiKey('claude') ?? '';
    _elevenLabsController.text = _storage.getApiKey('elevenlabs') ?? '';
  }

  Future<void> _saveKeys() async {
    setState(() => _isLoading = true);
    
    await _storage.saveApiKey('openai', _openAIController.text.trim());
    await _storage.saveApiKey('gemini', _geminiController.text.trim());
    await _storage.saveApiKey('claude', _claudeController.text.trim());
    await _storage.saveApiKey('elevenlabs', _elevenLabsController.text.trim());

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Keys Encrypted & Saved Successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
            )
          ],
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.settings, size: 32, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              "API Keys Management",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              "Keys are encrypted locally with your Master Password.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _ApiKeyField(controller: _openAIController, label: "OpenAI API Key", icon: LucideIcons.key),
                  _ApiKeyField(controller: _geminiController, label: "Google Gemini API Key", icon: LucideIcons.gem),
                  _ApiKeyField(controller: _claudeController, label: "Anthropic Claude API Key", icon: LucideIcons.brain),
                  _ApiKeyField(controller: _elevenLabsController, label: "ElevenLabs API Key", icon: LucideIcons.mic),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveKeys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save & Encrypt"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _ApiKeyField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.black26,
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.eye, color: AppColors.textSecondary),
            onPressed: () {
              // Toggle visibility logic requires stateful widget, keeping it simple (always hidden) or adding later.
              // For now simpler to keep obscured for security visual.
            }, 
            tooltip: "Show needs implementation",
          ),
        ),
      ),
    );
  }
}
