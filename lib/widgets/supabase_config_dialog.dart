import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../theme/app_colors.dart';

class SupabaseConfigDialog extends StatefulWidget {
  const SupabaseConfigDialog({super.key});

  @override
  State<SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends State<SupabaseConfigDialog> {
  late TextEditingController _urlController;
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    final state = context.read<JobBloc>().state;
    _urlController = TextEditingController(text: state.supabaseUrl ?? '');
    _keyController = TextEditingController(text: state.supabaseAnonKey ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_urlController.text.trim().isNotEmpty &&
        _keyController.text.trim().isNotEmpty) {
      context.read<JobBloc>().add(SupabaseConfigured(
            url: _urlController.text.trim(),
            anonKey: _keyController.text.trim(),
          ));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.matchHigh, size: 20),
              SizedBox(width: 10),
              Flexible(
                child: Text('Supabase connected!',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.matchHigh.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.matchHigh.withAlpha(80)),
                    ),
                    child: const Icon(Icons.storage,
                        color: AppColors.matchHigh, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect Supabase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Store resumes, pgvector embeddings & telemetry',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Project URL',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 5),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'https://xyzcompany.supabase.co',
                  prefixIcon:
                      Icon(Icons.link, size: 16, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Anon Public API Key',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 5),
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'eyJhbGciOi...',
                  prefixIcon:
                      Icon(Icons.key, size: 16, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: AppColors.cyanAccent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The app works with local mock data. Connect Supabase to persist and sync live.',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 14),
                    label:
                        const Text('Connect', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
