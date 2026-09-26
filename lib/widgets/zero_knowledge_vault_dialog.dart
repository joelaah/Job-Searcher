import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../models/job_model.dart';
import '../models/local_credential.dart';
import '../theme/app_colors.dart';

class ZeroKnowledgeVaultDialog extends StatefulWidget {
  const ZeroKnowledgeVaultDialog({super.key});

  @override
  State<ZeroKnowledgeVaultDialog> createState() => _ZeroKnowledgeVaultDialogState();
}

class _ZeroKnowledgeVaultDialogState extends State<ZeroKnowledgeVaultDialog> {
  final TextEditingController _csvController = TextEditingController();
  final Set<int> _revealedPasswords = {};
  JobModel? _selectedJobForApply;

  static const String _sampleCsv = '''platform,username_or_email,password,resume_path
greenhouse.io,candidate.alex@dev.io,SafePassGreen#92,C:/Resumes/Alex_Vance_Resume.pdf
lever.co,candidate.alex@dev.io,SafePassLever!44,C:/Resumes/Alex_Vance_Resume.pdf
ashbyhq.com,candidate.alex@dev.io,SafePassAshby@11,C:/Resumes/Alex_Vance_Resume.pdf
workday.com,candidate.alex@dev.io,WorkdaySec789!,C:/Resumes/Alex_Vance_Resume.pdf''';

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _loadSampleCsv() {
    setState(() {
      _csvController.text = _sampleCsv;
    });
  }

  void _parseAndImportCsv() {
    final text = _csvController.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length < 2) return;

    // Header parse
    final headerParts = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final List<LocalCredential> imported = [];

    for (int i = 1; i < lines.length; i++) {
      final rowParts = lines[i].split(',').map((p) => p.trim()).toList();
      final Map<String, String> rowMap = {};
      for (int h = 0; h < headerParts.length && h < rowParts.length; h++) {
        rowMap[headerParts[h]] = rowParts[h];
      }
      imported.add(LocalCredential.fromMap(rowMap));
    }

    if (imported.isNotEmpty) {
      context.read<JobBloc>().add(ImportLocalCredentials(imported));
      _csvController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Imported ${imported.length} credentials into zero-knowledge local memory.'),
          backgroundColor: AppColors.matchHigh,
        ),
      );
    }
  }

  Future<void> _launchApplicationWithCredentials(JobModel job, List<LocalCredential> creds) async {
    // Find matching credential
    LocalCredential? matched;
    final jobUrlLower = job.applicationUrl.toLowerCase();
    for (final c in creds) {
      if (jobUrlLower.contains(c.platform.toLowerCase())) {
        matched = c;
        break;
      }
    }
    matched ??= creds.isNotEmpty ? creds.first : null;

    if (matched != null) {
      await Clipboard.setData(
        ClipboardData(
          text: 'User: ${matched.usernameOrEmail}\nPass: ${matched.password}\nResume: ${matched.resumePath}',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📋 Copied login credentials for ${matched.platform} to clipboard!'),
            backgroundColor: AppColors.cyanAccent,
          ),
        );
      }
    }

    final uri = Uri.parse(job.applicationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final credentials = state.localCredentials;
        if (_selectedJobForApply == null && state.allJobs.isNotEmpty) {
          _selectedJobForApply = state.allJobs.first;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            width: 820,
            constraints: const BoxConstraints(maxHeight: 760),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.matchHigh.withAlpha(80), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.matchHigh.withAlpha(25),
                  blurRadius: 35,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.matchHigh.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.matchHigh.withAlpha(90)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.matchHigh, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zero-Knowledge Local Credential Vault',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Auto-login and auto-submit without backend servers or databases ever seeing your credentials',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.surfaceBorder, height: 1),

                // Privacy Guarantee Badge
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.matchHigh.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.matchHigh.withAlpha(60)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, size: 16, color: AppColors.matchHigh),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Zero-Knowledge Guarantee: Plaintext passwords remain strictly in client memory. Never transmitted over the network or saved to remote databases.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CSV Input Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Import Accounts via .CSV',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _loadSampleCsv,
                              icon: const Icon(Icons.auto_fix_high, size: 14, color: AppColors.cyanAccent),
                              label: const Text(
                                'Paste Example CSV',
                                style: TextStyle(fontSize: 11, color: AppColors.cyanAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _csvController,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'platform,username_or_email,password,resume_path\ngreenhouse.io,me@mail.com,pass123,C:/resume.pdf',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (credentials.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  context.read<JobBloc>().add(ClearLocalCredentials());
                                },
                                child: const Text(
                                  'Clear Vault',
                                  style: TextStyle(fontSize: 11, color: AppColors.accentRed),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _parseAndImportCsv,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cyanAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.file_download_done, size: 16),
                              label: const Text(
                                'Import to Local Vault',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(color: AppColors.surfaceBorder, height: 1),
                        const SizedBox(height: 14),

                        // Stored Credentials
                        Row(
                          children: [
                            const Text(
                              'Stored Local Accounts',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cyanAccent.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${credentials.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyanAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (credentials.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withAlpha(80),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'No local credentials stored. Paste a CSV above or click "Paste Example CSV".',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: List.generate(credentials.length, (index) {
                              final cred = credentials[index];
                              final isRevealed = _revealedPasswords.contains(index);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surfaceBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanAccent.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cred.platform,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.cyanAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cred.usernameOrEmail,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                isRevealed ? cred.password : '••••••••••••',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (isRevealed) {
                                                      _revealedPasswords.remove(index);
                                                    } else {
                                                      _revealedPasswords.add(index);
                                                    }
                                                  });
                                                },
                                                child: Icon(
                                                  isRevealed ? Icons.visibility_off : Icons.visibility,
                                                  size: 14,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed),
                                      onPressed: () {
                                        context.read<JobBloc>().add(DeleteLocalCredential(index));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 18),
                        const Divider(color: AppColors.surfaceBorder, height: 1),
                        const SizedBox(height: 14),

                        // Auto-Apply Assistant Launcher
                        const Text(
                          '1-Click Assisted Auto-Apply',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (state.allJobs.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select target role to launch with zero-knowledge credentials:',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<JobModel>(
                                  value: _selectedJobForApply ?? state.allJobs.first,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceElevated,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                    ),
                                  ),
                                  items: state.allJobs.take(15).map((job) {
                                    return DropdownMenuItem(
                                      value: job,
                                      child: Text(
                                        '${job.title} — ${job.company}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedJobForApply = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _selectedJobForApply == null
                                            ? null
                                            : () => _launchApplicationWithCredentials(
                                                  _selectedJobForApply!,
                                                  credentials,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.matchHigh,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.rocket_launch, size: 16),
                                        label: const Text(
                                          'Launch Portal & Copy Credentials',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Desktop Local Python runner command box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(90),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.terminal, size: 14, color: AppColors.cyanAccent),
                                  SizedBox(width: 6),
                                  Text(
                                    'Native Desktop Runner (100% Offline):',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cyanAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Expanded(
                                    child: SelectableText(
                                      'python backend/local_auto_apply.py --csv credentials.csv --url <JOB_URL>',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                                    onPressed: () {
                                      Clipboard.setData(
                                        const ClipboardData(
                                          text: 'python backend/local_auto_apply.py --csv credentials.csv --url <JOB_URL>',
                                        ),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Command copied to clipboard!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: AppColors.surfaceBorder, height: 1),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stored in Local RAM Only',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
