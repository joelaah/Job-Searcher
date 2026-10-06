import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists job interaction state (saved, applied, dismissed) to browser
/// localStorage via SharedPreferences. This gives JOB SeArCh session
/// persistence without requiring authentication — interactions survive
/// page refresh, browser restart, and PWA reinstalls.
///
/// Storage format:
///   - Key: 'job_interactions'
///   - Value: JSON map of { jobId: { "saved": bool, "applied": bool, "dismissed": bool } }
class JobPersistenceService {
  static const String _interactionsKey = 'job_interactions';
  static const String _scrapedJobsKey = 'scraped_jobs_cache';

  final SharedPreferences _prefs;

  JobPersistenceService(this._prefs);

  // ──────────────────────────────────────────
  // Job Interaction State (Saved/Applied/Dismissed)
  // ──────────────────────────────────────────

  /// Load all persisted interaction states.
  /// Returns a map of jobId → {saved, applied, dismissed}.
  Map<String, Map<String, bool>> loadInteractions() {
    final raw = _prefs.getString(_interactionsKey);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final interaction = value as Map<String, dynamic>;
        return MapEntry(key, {
          'saved': interaction['saved'] as bool? ?? false,
          'applied': interaction['applied'] as bool? ?? false,
          'dismissed': interaction['dismissed'] as bool? ?? false,
        });
      });
    } catch (_) {
      return {};
    }
  }

  /// Persist the current interaction state for a single job.
  Future<void> saveInteraction(
    String jobId, {
    required bool isSaved,
    required bool isApplied,
    required bool isDismissed,
  }) async {
    final current = loadInteractions();
    current[jobId] = {
      'saved': isSaved,
      'applied': isApplied,
      'dismissed': isDismissed,
    };
    await _prefs.setString(_interactionsKey, jsonEncode(current));
  }

  /// Batch-persist all interaction states (used on initial hydration).
  Future<void> saveAllInteractions(
    Map<String, Map<String, bool>> interactions,
  ) async {
    await _prefs.setString(_interactionsKey, jsonEncode(interactions));
  }

  // ──────────────────────────────────────────
  // Scraped Jobs Cache
  // ──────────────────────────────────────────

  /// Cache scraped jobs so they survive page refresh.
  Future<void> cacheScrapedJobs(List<Map<String, dynamic>> jobs) async {
    await _prefs.setString(_scrapedJobsKey, jsonEncode(jobs));
  }

  /// Load cached scraped jobs.
  List<Map<String, dynamic>> loadCachedScrapedJobs() {
    final raw = _prefs.getString(_scrapedJobsKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear all persisted data.
  Future<void> clearAll() async {
    await _prefs.remove(_interactionsKey);
    await _prefs.remove(_scrapedJobsKey);
  }
}
