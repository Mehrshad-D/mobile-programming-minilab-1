import 'package:flutter/material.dart';

import '../models/job.dart';
import '../presenters/job_presenter.dart';
import '../services/mock_api_service.dart';
import '../utils/constants.dart';
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
  String? _selectedLocation;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = JobListPresenter(this, MockApiService());
    _scrollController.addListener(_onScroll);
    _presenter.loadLocations();
    _presenter.loadJobs();
  }

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

  void _search() {
    FocusScope.of(context).unfocus();
    _presenter.loadJobs(
      keyword: _searchController.text.trim(),
      location: _selectedLocation,
    );
  }

  Future<void> _refresh() => _presenter.loadJobs(
        keyword: _searchController.text.trim(),
        location: _selectedLocation,
      );

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.jobsTitle),
        actions: [
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
                  onChanged: (value) =>
                      setState(() => _selectedLocation = value),
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
