import 'package:flutter/material.dart';

import '../models/filter_meta.dart';
import '../models/job_filters.dart';
import '../utils/constants.dart';
import 'custom_button.dart';

/// Bottom-sheet that exposes the section 5.1 facets not shown in the search
/// bar: categories, job types, work experience, salary minimum, benefits and
/// internship. It is a pure view widget: it edits a copy of [current] and
/// returns the updated [JobFilters] via `Navigator.pop`.
class FilterBottomSheet extends StatefulWidget {
  final JobFilters current;
  final FilterMeta meta;

  const FilterBottomSheet({
    super.key,
    required this.current,
    required this.meta,
  });

  /// Opens the sheet and resolves with the new filters, or `null` if dismissed.
  static Future<JobFilters?> show(
    BuildContext context, {
    required JobFilters current,
    required FilterMeta meta,
  }) {
    return showModalBottomSheet<JobFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(current: current, meta: meta),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _categories;
  late Set<String> _jobTypes;
  late Set<String> _workExperiences;
  late Set<String> _benefits;
  late int? _salaryMin;
  late bool _internship;

  @override
  void initState() {
    super.initState();
    final f = widget.current;
    _categories = f.jobCategories.toSet();
    _jobTypes = f.jobTypes.toSet();
    _workExperiences = f.workExperiences.toSet();
    _benefits = f.benefits.toSet();
    _salaryMin = f.salaryMin;
    _internship = f.internship;
  }

  void _toggle(Set<String> set, String value, bool selected) {
    setState(() {
      if (selected) {
        set.add(value);
      } else {
        set.remove(value);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _categories = {};
      _jobTypes = {};
      _workExperiences = {};
      _benefits = {};
      _salaryMin = null;
      _internship = false;
    });
  }

  void _apply() {
    // Preserve the facets owned by the search bar (keyword, location, sort,
    // remote); replace the ones this sheet controls.
    final result = JobFilters(
      keywords: widget.current.keywords,
      locations: widget.current.locations,
      remote: widget.current.remote,
      sortBy: widget.current.sortBy,
      jobCategories: _categories.toList(),
      jobTypes: _jobTypes.toList(),
      workExperiences: _workExperiences.toList(),
      benefits: _benefits,
      salaryMin: _salaryMin,
      internship: _internship,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _MultiSelectSection(
                      title: AppStrings.category,
                      options: meta.categories,
                      selected: _categories,
                      onToggle: (v, s) => _toggle(_categories, v, s),
                    ),
                    _MultiSelectSection(
                      title: AppStrings.jobType,
                      options: meta.jobTypes,
                      selected: _jobTypes,
                      onToggle: (v, s) => _toggle(_jobTypes, v, s),
                    ),
                    _MultiSelectSection(
                      title: AppStrings.experience,
                      options: meta.workExperiences,
                      selected: _workExperiences,
                      onToggle: (v, s) => _toggle(_workExperiences, v, s),
                    ),
                    _buildSalarySection(),
                    _MultiSelectSection(
                      title: AppStrings.benefits,
                      options: meta.benefits.map((b) => b.label).toList(),
                      selected: _benefits
                          .map((key) => _labelForBenefit(key))
                          .whereType<String>()
                          .toSet(),
                      onToggle: _onBenefitToggle,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                      title: const Text(AppStrings.internship),
                      value: _internship,
                      onChanged: (v) => setState(() => _internship = v),
                    ),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  String? _labelForBenefit(String key) {
    for (final b in widget.meta.benefits) {
      if (b.key == key) return b.label;
    }
    return null;
  }

  void _onBenefitToggle(String label, bool selected) {
    final match =
        widget.meta.benefits.where((b) => b.label == label).toList();
    if (match.isEmpty) return;
    _toggle(_benefits, match.first.key, selected);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Text(
            AppStrings.filters,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearAll,
            child: const Text(
              AppStrings.clearFilters,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            AppStrings.minSalary,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text(AppStrings.anyOption),
              selected: _salaryMin == null,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              onSelected: (_) => setState(() => _salaryMin = null),
            ),
            ...widget.meta.salaryRanges.map(
              (range) => ChoiceChip(
                label: Text(range.label),
                selected: _salaryMin == range.value,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _salaryMin = range.value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: CustomButton(
        label: AppStrings.applyFilters,
        icon: Icons.check,
        onPressed: _apply,
      ),
    );
  }
}

/// A titled group of multi-select [FilterChip]s.
class _MultiSelectSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(String value, bool selected) onToggle;

  const _MultiSelectSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              onSelected: (value) => onToggle(option, value),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
