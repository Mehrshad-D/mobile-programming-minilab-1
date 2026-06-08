/// Sort options supported by `GET /jobs` (`sort_by` parameter).
enum JobSort {
  publishedAtDesc,
  salaryDesc;

  /// The exact string the API expects.
  String get apiValue =>
      this == JobSort.salaryDesc ? 'salary_desc' : 'published_at_desc';

  /// Short Persian label for the UI.
  String get label =>
      this == JobSort.salaryDesc ? 'بیشترین حقوق' : 'جدیدترین';

  static JobSort fromApi(String? value) =>
      value == 'salary_desc' ? JobSort.salaryDesc : JobSort.publishedAtDesc;
}

/// Immutable representation of every `GET /jobs` query parameter from
/// section 5.1. Within a single facet (e.g. locations) values are OR-ed;
/// across facets they are AND-ed, which is the standard faceted-search rule.
class JobFilters {
  final List<String> keywords; // filters[keywords][0..]
  final List<String> locations; // filters[locations][0..31]
  final List<String> jobCategories; // filters[job_categories][0..47]
  final List<String> jobTypes; // filters[job_types][0..3]
  final bool remote; // filters[remote]
  final bool internship; // filters[internship]
  final Set<String> benefits; // filters[has_*]
  final int? salaryMin; // filters[sal_min][0..14]
  final List<String> workExperiences; // filters[w_e][]
  final JobSort sortBy; // sort_by
  final int page; // page

  const JobFilters({
    this.keywords = const [],
    this.locations = const [],
    this.jobCategories = const [],
    this.jobTypes = const [],
    this.remote = false,
    this.internship = false,
    this.benefits = const {},
    this.salaryMin,
    this.workExperiences = const [],
    this.sortBy = JobSort.publishedAtDesc,
    this.page = 1,
  });

  JobFilters copyWith({
    List<String>? keywords,
    List<String>? locations,
    List<String>? jobCategories,
    List<String>? jobTypes,
    bool? remote,
    bool? internship,
    Set<String>? benefits,
    int? salaryMin,
    List<String>? workExperiences,
    JobSort? sortBy,
    int? page,
  }) {
    return JobFilters(
      keywords: keywords ?? this.keywords,
      locations: locations ?? this.locations,
      jobCategories: jobCategories ?? this.jobCategories,
      jobTypes: jobTypes ?? this.jobTypes,
      remote: remote ?? this.remote,
      internship: internship ?? this.internship,
      benefits: benefits ?? this.benefits,
      salaryMin: salaryMin ?? this.salaryMin,
      workExperiences: workExperiences ?? this.workExperiences,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }

  /// Builds the exact query map the real Jobinja `GET /jobs` expects.
  /// Kept so the same filters can drive a real HTTP client later.
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    for (var i = 0; i < keywords.length; i++) {
      params['filters[keywords][$i]'] = keywords[i];
    }
    for (var i = 0; i < locations.length; i++) {
      params['filters[locations][$i]'] = locations[i];
    }
    for (var i = 0; i < jobCategories.length; i++) {
      params['filters[job_categories][$i]'] = jobCategories[i];
    }
    for (var i = 0; i < jobTypes.length; i++) {
      params['filters[job_types][$i]'] = jobTypes[i];
    }
    if (remote) params['filters[remote]'] = '1';
    if (internship) params['filters[internship]'] = '1';
    for (final benefit in benefits) {
      params['filters[has_$benefit]'] = '1';
    }
    if (salaryMin != null) {
      params['filters[sal_min][0]'] = salaryMin.toString();
    }
    for (var i = 0; i < workExperiences.length; i++) {
      params['filters[w_e][$i]'] = workExperiences[i];
    }
    params['sort_by'] = sortBy.apiValue;
    params['page'] = page.toString();

    return params;
  }
}
