class JobModel {
  final String id;
  final String title;
  final String company;
  final String? companyLogo;
  final String location;
  final bool isRemote;
  final int salaryMin;
  final int salaryMax;
  final String currency;
  final List<String> tags;
  final int matchScore; // 0 to 100
  final List<String> whyItFits;
  final List<String> skillGaps;
  final String tailoredPitch;
  final String recruiterMessage;
  final String fullDescription;
  final String postedTimeAgo;
  final String applicationUrl;
  bool isSaved;
  bool isApplied;
  bool isDismissed;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.isRemote,
    required this.salaryMin,
    required this.salaryMax,
    this.currency = '\$',
    required this.tags,
    required this.matchScore,
    required this.whyItFits,
    required this.skillGaps,
    required this.tailoredPitch,
    required this.recruiterMessage,
    required this.fullDescription,
    required this.postedTimeAgo,
    required this.applicationUrl,
    this.isSaved = false,
    this.isApplied = false,
    this.isDismissed = false,
  });

  String get formattedSalary {
    if (salaryMin == 0 && salaryMax == 0) return 'Competitive';
    return '$currency${(salaryMin / 1000).toStringAsFixed(0)}k - $currency${(salaryMax / 1000).toStringAsFixed(0)}k / yr';
  }

  JobModel copyWith({
    bool? isSaved,
    bool? isApplied,
    bool? isDismissed,
  }) {
    return JobModel(
      id: id,
      title: title,
      company: company,
      companyLogo: companyLogo,
      location: location,
      isRemote: isRemote,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      currency: currency,
      tags: tags,
      matchScore: matchScore,
      whyItFits: whyItFits,
      skillGaps: skillGaps,
      tailoredPitch: tailoredPitch,
      recruiterMessage: recruiterMessage,
      fullDescription: fullDescription,
      postedTimeAgo: postedTimeAgo,
      applicationUrl: applicationUrl,
      isSaved: isSaved ?? this.isSaved,
      isApplied: isApplied ?? this.isApplied,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  factory JobModel.fromScrapedJson(Map<String, dynamic> json, {int matchScore = 85}) {
    final rawTags = json['tags'];
    final List<String> parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : ['Live Scraped'];
    if (parsedTags.isEmpty) parsedTags.add('Live Scraped');

    return JobModel(
      id: 'scraped_${DateTime.now().microsecondsSinceEpoch}_${(json['title'] ?? 'job').toString().hashCode.abs()}',
      title: json['title'] ?? 'Unknown Position',
      company: json['company'] ?? 'Target Company',
      location: json['location'] ?? 'Remote',
      isRemote: json['is_remote'] ?? true,
      salaryMin: json['salary_min'] ?? 0,
      salaryMax: json['salary_max'] ?? 0,
      currency: '\$',
      tags: parsedTags,
      matchScore: matchScore,
      whyItFits: [
        'Live extracted from ${json['source'] ?? 'custom URL'}',
        'Direct alignment with live career pipeline',
      ],
      skillGaps: ['Review live job posting requirements'],
      tailoredPitch:
          'Excited to apply for this role discovered directly via company career portal crawling.',
      recruiterMessage:
          'Hello! I noticed your recent opening for ${json['title']} and wanted to connect regarding my relevant engineering background.',
      fullDescription: json['description'] ?? 'No description provided.',
      postedTimeAgo: json['posted_at']?.toString().isNotEmpty == true
          ? 'Recently'
          : 'Live API',
      applicationUrl: json['job_url'] ?? '',
      isSaved: false,
      isApplied: false,
      isDismissed: false,
    );
  }
}

