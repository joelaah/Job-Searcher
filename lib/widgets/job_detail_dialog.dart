import 'package:flutter/material.dart';
import '../models/job_model.dart';
import 'diagnostic_dossier_modal.dart';

/// Legacy alias / wrapper delegating to [DiagnosticDossierModal].
/// Provides full backward compatibility across the codebase while rendering
/// the Cyber-Marine HUD Diagnostic Dossier cockpit.
class JobDetailDialog extends StatelessWidget {
  final JobModel job;

  const JobDetailDialog({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return DiagnosticDossierModal(job: job);
  }
}
