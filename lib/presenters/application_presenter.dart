import 'dart:io';

import '../models/application.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/api_response.dart';

/// Contract for the applications screen
abstract class ApplicationsView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showApplications(List<JobApplication> applications);
  void onApplicationCancelled(String applicationId);
  void onCoverLetterUpdated(String applicationId);
}

/// Contract for application detail screen
abstract class ApplicationDetailView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showApplication(JobApplication application);
  void onCoverLetterUploaded(JobApplication application);
  void onApplicationCancelled();
}

/// Presenter for managing job applications
class ApplicationsPresenter {
  final ApplicationsView _view;
  final ApiService _api;

  ApplicationsPresenter(this._view, this._api);

  Future<void> loadApplications() async {
    _view.showLoading();
    try {
      final applications = await _api.getApplications();
      _view.showApplications(applications);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> cancelApplication(String applicationId) async {
    _view.showLoading();
    try {
      await _api.cancelApplication(applicationId);
      _view.onApplicationCancelled(applicationId);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در لغو درخواست');
    } finally {
      _view.hideLoading();
    }
  }
}

/// Presenter for application detail
class ApplicationDetailPresenter {
  final ApplicationDetailView _view;
  final ApiService _api;

  ApplicationDetailPresenter(this._view, this._api);

  Future<void> loadApplication(String applicationId) async {
    _view.showLoading();
    try {
      final application = await _api.getApplicationDetail(applicationId);
      _view.showApplication(application);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> uploadCoverLetter(String applicationId, String content) async {
    _view.showLoading();
    try {
      final updated = await _api.uploadCoverLetter(applicationId, content);
      _view.onCoverLetterUploaded(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در آپلود کاورلتر');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateCoverLetter(String applicationId, String content) async {
    _view.showLoading();
    try {
      final updated = await _api.updateCoverLetter(applicationId, content);
      _view.onCoverLetterUploaded(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ویرایش کاورلتر');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> uploadCoverLetterFile(String applicationId, File file) async {
    _view.showLoading();
    try {
      final updated = await _api.uploadCoverLetterFile(applicationId, file);
      _view.onCoverLetterUploaded(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در آپلود فایل کاورلتر');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> cancelApplication(String applicationId) async {
    _view.showLoading();
    try {
      await _api.cancelApplication(applicationId);
      _view.onApplicationCancelled();
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در لغو درخواست');
    } finally {
      _view.hideLoading();
    }
  }
}