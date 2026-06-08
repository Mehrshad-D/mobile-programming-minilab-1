import 'package:flutter/material.dart';

import '../models/filter_meta.dart';
import '../models/job.dart';
import '../models/job_filters.dart';
import '../presenters/job_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/job_card.dart';
import '../widgets/loading_widget.dart';
import 'job_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements JobListView {
  late final JobListPresenter _presenter;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Job> _jobs = [];
  List<String> _locations = [];
  FilterMeta _filterMeta = FilterMeta.empty;

  /// Single source of truth for the active query (everything except the
  /// keyword, which lives in the text field and is merged in at search time).
  JobFilters _filters = const JobFilters();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = JobListPresenter(this, MockApiService());
    _scrollController.addListener(_onScroll);
    _presenter.loadLocations();
    _presenter.loadFilterMeta();
    _presenter.loadJobs();
  }

  String? get _selectedLocation =>
      _filters.locations.isEmpty ? null : _filters.locations.first;

  bool get _hasSheetFilters =>
      _filters.jobCategories.isNotEmpty ||
      _filters.jobTypes.isNotEmpty ||
      _filters.workExperiences.isNotEmpty ||
      _filters.benefits.isNotEmpty ||
      _filters.salaryMin != null ||
      _filters.internship;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _presenter.loadMore();
    }
  }

  /// Merges the live keyword text into the stored filters before searching.
  JobFilters _currentFilters() {
    final keyword = _searchController.text.trim();
    return _filters.copyWith(
      keywords: keyword.isEmpty ? const [] : [keyword],
    );
  }

  void _search() {
    FocusScope.of(context).unfocus();
    _presenter.loadJobs(_currentFilters());
  }

  Future<void> _refresh() => _presenter.loadJobs(_currentFilters());

  Future<void> _openFilters() async {
    if (!_filterMeta.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.loading)),
      );
      return;
    }
    final result = await FilterBottomSheet.show(
      context,
      current: _currentFilters(),
      meta: _filterMeta,
    );
    if (result != null) {
      setState(() => _filters = result);
      _search();
    }
  }

  void _openJob(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
    );
  }

  // ---- JobListView ----
  @override
  void showLoading() => setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

  @override
  void hideLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void showError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  @override
  void showJobs(List<Job> jobs) {
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _errorMessage = null;
      });
    }
  }

  @override
  void showLoadingMore(bool isLoadingMore) {
    if (mounted) setState(() => _isLoadingMore = isLoadingMore);
  }

  @override
  void showLocations(List<String> locations) {
    if (mounted) setState(() => _locations = locations);
  }

  @override
  void showFilterMeta(FilterMeta meta) {
    if (mounted) setState(() => _filterMeta = meta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.jobsTitle),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasSheetFilters,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.tune),
            ),
            tooltip: AppStrings.filters,
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppStrings.profile,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedLocation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: const Text(AppStrings.allLocations),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.allLocations),
                    ),
                    ..._locations.map(
                      (loc) => DropdownMenuItem<String?>(
                        value: loc,
                        child: Text(loc),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(
                        locations: value == null ? const [] : [value],
                      );
                    });
                    _search();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                  ),
                  child: const Text(AppStrings.search),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              DropdownButton<JobSort>(
                value: _filters.sortBy,
                underline: const SizedBox.shrink(),
                items: JobSort.values
                    .map(
                      (sort) => DropdownMenuItem<JobSort>(
                        value: sort,
                        child: Text(sort.label),
                      ),
                    )
                    .toList(),
                onChanged: (sort) {
                  if (sort == null) return;
                  setState(() => _filters = _filters.copyWith(sortBy: sort));
                  _search();
                },
              ),
              const Spacer(),
              FilterChip(
                label: const Text(AppStrings.remote),
                selected: _filters.remote,
                onSelected: (selected) {
                  setState(
                    () => _filters = _filters.copyWith(remote: selected),
                  );
                  _search();
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }
    if (_errorMessage != null) {
      return AppErrorWidget(message: _errorMessage!, onRetry: _refresh);
    }
    if (_jobs.isEmpty) {
      return const EmptyStateWidget(
        message: AppStrings.noJobs,
        icon: Icons.search_off,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
        itemCount: _jobs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final job = _jobs[index];
          return JobCard(job: job, onTap: () => _openJob(job));
        },
      ),
    );
  }
}
