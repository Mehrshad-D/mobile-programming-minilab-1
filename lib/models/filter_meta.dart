/// Reference data used to populate the filter bottom-sheet. This mirrors the
/// kind of metadata the real Jobinja `job_search_meta` endpoint returns.
class FilterMeta {
  final List<String> categories;
  final List<String> jobTypes;
  final List<String> workExperiences;

  /// Salary thresholds: a human label paired with its minimum value (Toman).
  final List<({String label, int value})> salaryRanges;

  /// Benefits: the `has_*` key paired with a Persian label.
  final List<({String key, String label})> benefits;

  const FilterMeta({
    this.categories = const [],
    this.jobTypes = const [],
    this.workExperiences = const [],
    this.salaryRanges = const [],
    this.benefits = const [],
  });

  static const FilterMeta empty = FilterMeta();

  bool get isReady =>
      categories.isNotEmpty ||
      jobTypes.isNotEmpty ||
      workExperiences.isNotEmpty ||
      benefits.isNotEmpty;
}
