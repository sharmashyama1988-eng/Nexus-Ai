
import 'package:flutter/material.dart';
import 'package:nexus_ai/services/storage_service.dart';
import 'package:nexus_ai/ui/home_screen.dart';
import 'package:nexus_ai/utils/constants.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _unlock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await StorageService().unlockOrInitialize(_passwordController.text);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _error = "Invalid Password. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.glassGradient),
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.sidebar.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.lock, size: 48, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  "Nexus AI Security",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: "Master Password",
                    errorText: _error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Unlock Dashboard"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
