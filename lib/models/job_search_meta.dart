/// A single facet entry: a label paired with the number of jobs it matches.
class MetaFacet {
  final String name;
  final int count;

  const MetaFacet({required this.name, required this.count});

  factory MetaFacet.fromJson(Map<String, dynamic> json) {
    return MetaFacet(
      name: json['name'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'count': count};
}

/// Aggregated search metadata returned by `GET /api/v10/job_search_meta`
/// (section 5.2): facet lists with job counts plus the grand total.
class JobSearchMeta {
  final List<MetaFacet> jobCategories;
  final List<MetaFacet> companyCategories;
  final List<MetaFacet> locations;
  final List<MetaFacet> companySizes;
  final int total;

  const JobSearchMeta({
    required this.jobCategories,
    required this.companyCategories,
    required this.locations,
    required this.companySizes,
    required this.total,
  });

  factory JobSearchMeta.fromJson(Map<String, dynamic> json) {
    List<MetaFacet> parse(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .map((e) => MetaFacet.fromJson(e as Map<String, dynamic>))
            .toList();
    return JobSearchMeta(
      jobCategories: parse('job_categories'),
      companyCategories: parse('company_categories'),
      locations: parse('locations'),
      companySizes: parse('company_sizes'),
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_categories': jobCategories.map((e) => e.toJson()).toList(),
        'company_categories':
            companyCategories.map((e) => e.toJson()).toList(),
        'locations': locations.map((e) => e.toJson()).toList(),
        'company_sizes': companySizes.map((e) => e.toJson()).toList(),
        'total': total,
      };
}
