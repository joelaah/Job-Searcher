import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../models/job_model.dart';
import '../theme/app_colors.dart';

class CustomScraperDialog extends StatefulWidget {
  const CustomScraperDialog({super.key});

  @override
  State<CustomScraperDialog> createState() => _CustomScraperDialogState();
}

class _CustomScraperDialogState extends State<CustomScraperDialog> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://jobs.ashbyhq.com/linear',
  );
  bool _isLoading = false;
  String? _errorMessage;
  List<JobModel> _scrapedJobs = [];
  String _sourceStatus = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runScraper() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid website or ATS careers link.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scrapedJobs = [];
      _sourceStatus = 'Connecting to scraper engine...';
    });

    try {
      // 1. Try local FastAPI backend endpoint
      const backendUrl = 'http://127.0.0.1:8000/api/scrape-url';
      bool backendSuccess = false;

      try {
        final resp = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'url': rawUrl, 'max_jobs': 40}),
            )
            .timeout(const Duration(seconds: 12));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final rawList = data['jobs'] as List? ?? [];
          final jobs = rawList
              .map((j) => JobModel.fromScrapedJson(j as Map<String, dynamic>))
              .toList();

          setState(() {
            _scrapedJobs = jobs;
            _sourceStatus = 'Scraped via Python FastAPI Engine (${jobs.length} jobs found)';
            _isLoading = false;
          });
          backendSuccess = true;
        } else if (resp.statusCode == 429) {
          setState(() {
            _errorMessage = 'Rate limit reached (Too many requests). Please wait a moment before scraping again.';
            _sourceStatus = 'Rate limit exceeded (HTTP 429)';
            _isLoading = false;
          });
          return;
        }
      } catch (_) {
        // Backend not currently running on 8000; will use smart direct browser client fallback
      }

      if (!backendSuccess) {
        // 2. Direct client-side fallback for public ATS APIs
        setState(() {
          _sourceStatus = 'Connecting directly to public ATS API...';
        });

        final jobs = await _directPublicAtsScrape(rawUrl);
        setState(() {
          _scrapedJobs = jobs;
          _sourceStatus = 'Scraped directly via public ATS API (${jobs.length} jobs found)';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Scraping error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<JobModel>> _directPublicAtsScrape(String url) async {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Direct Ashby API
    if (host.contains('ashbyhq.com') && segments.isNotEmpty) {
      final board = segments.first;
      final apiUrl = 'https://api.ashbyhq.com/posting-api/job-board/$board';
      final resp = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['jobs'] as List? ?? [];
        return list.map((item) {
          return JobModel.fromScrapedJson({
            'title': item['title'] ?? 'Role',
            'company': board.toUpperCase(),
            'location': item['location'] ?? 'Remote',
            'is_remote': item['isRemote'] ?? true,
            'description': item['descriptionHtml'] ?? '',
            'job_url': item['jobUrl'] ?? url,
            'source': 'ashby',
            'tags': [item['department'] ?? 'Engineering'],
          });
        }).toList();
      }
    }

    // Direct Greenhouse API
    if (host.contains('greenhouse.io') && segments.isNotEmpty) {
      String board = segments.first;
      if (board == 'embed' && segments.length > 1) board = segments[1];
      final apiUrl = 'https://boards-api.greenhouse.io/v1/boards/$board/jobs?content=true';
      final resp = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['jobs'] as List? ?? [];
        return list.map((item) {
          return JobModel.fromScrapedJson({
            'title': item['title'] ?? 'Role',
            'company': board.toUpperCase(),
            'location': item['location']?['name'] ?? 'Remote',
            'is_remote': true,
            'description': item['content'] ?? '',
            'job_url': item['absolute_url'] ?? url,
            'source': 'greenhouse',
            'tags': ['Greenhouse Live'],
          });
        }).toList();
      }
    }

    throw Exception(
      'Could not connect directly. Start the local Python server (`python backend/server.py`) for generic URL scraping.',
    );
  }

  void _importJobs() {
    if (_scrapedJobs.isEmpty) return;
    context.read<JobBloc>().add(AddScrapedJobs(_scrapedJobs));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully imported ${_scrapedJobs.length} live scraped jobs into your matrix!',
        ),
        backgroundColor: AppColors.matchHigh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 740, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyanAccent.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyanAccent.withAlpha(30),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Color(0x60000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyanAccent.withAlpha(90)),
                    ),
                    child: const Icon(Icons.travel_explore, color: AppColors.cyanAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Custom Career URL Scraper',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Scrape open positions from any Greenhouse, Lever, Ashby, or career page',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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

            // URL Input & Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Presets
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      const Text(
                        'Quick Links: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      _presetChip('Linear (Ashby)', 'https://jobs.ashbyhq.com/linear'),
                      _presetChip('Figma (Greenhouse)', 'https://boards.greenhouse.io/figma'),
                      _presetChip('Vercel (Greenhouse)', 'https://boards.greenhouse.io/vercel'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Input row (responsive)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 460;
                      final inputField = TextField(
                        controller: _urlController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://company.com/careers or ATS link',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.link, size: 18, color: AppColors.cyanAccent),
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cyanAccent, width: 1.5),
                          ),
                        ),
                      );

                      final scrapeButton = ElevatedButton.icon(
                        onPressed: _isLoading ? null : _runScraper,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.bolt, size: 18),
                        label: Text(
                          _isLoading ? 'Scraping...' : 'Scrape Jobs',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            inputField,
                            const SizedBox(height: 10),
                            scrapeButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: inputField),
                          const SizedBox(width: 12),
                          scrapeButton,
                        ],
                      );
                    },
                  ),

                  if (_sourceStatus.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 13, color: AppColors.matchHigh),
                        const SizedBox(width: 6),
                        Text(
                          _sourceStatus,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.matchHigh,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentRed.withAlpha(70)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: AppColors.accentRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 11, color: AppColors.accentRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: AppColors.surfaceBorder, height: 1),

            // Results List
            Expanded(
              child: _scrapedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search,
                            size: 48,
                            color: AppColors.textMuted.withAlpha(80),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Enter a career page URL and click "Scrape Jobs"',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Works with Greenhouse, Ashby, Lever, or custom website career links',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _scrapedJobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final job = _scrapedJobs[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated.withAlpha(120),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.cyanAccent.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    job.company.isNotEmpty ? job.company[0].toUpperCase() : 'J',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.cyanAccent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          job.company,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.cyanAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•  ${job.location}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (job.tags.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBorder.withAlpha(120),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    job.tags.first,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(color: AppColors.surfaceBorder, height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Text(
                    _scrapedJobs.isNotEmpty
                        ? '${_scrapedJobs.length} live positions extracted'
                        : 'Ready to crawl',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _scrapedJobs.isEmpty ? null : _importJobs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.matchHigh,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.playlist_add_check, size: 18),
                        label: Text(
                          'Add ${_scrapedJobs.length} Jobs to Matrix',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
        });
        _runScraper();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.cyanAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
