import 'package:flutter/material.dart';
import '../models/job_alert.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Contract for job alerts screen
abstract class JobAlertsView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showAlerts(List<JobAlert> alerts);
  void showAlertMeta(AlertMeta meta);
  void onAlertCreated(JobAlert alert);
  void onAlertDeleted(String alertId);
  void onAlertUpdated(JobAlert alert);
  BuildContext getContext(); // Add this to get context for SnackBar
}

/// Presenter for managing job alerts
class JobAlertPresenter {
  final JobAlertsView _view;
  final ApiService _api;

  JobAlertPresenter(this._view, this._api);

  Future<void> loadAlerts() async {
    _view.showLoading();
    try {
      final alerts = await _api.getJobAlerts();
      _view.showAlerts(alerts);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> loadAlertMeta() async {
    try {
      final meta = await _api.getJobAlertMeta();
      _view.showAlertMeta(meta);
    } catch (_) {
      // Non-critical, ignore
    }
  }

  Future<void> createAlert(JobAlert alert) async {
    _view.showLoading();
    try {
      final newAlert = await _api.createJobAlert(alert);
      _view.onAlertCreated(newAlert);
      ScaffoldMessenger.of(_view.getContext()).showSnackBar(
        const SnackBar(content: Text('هشدار شغلی با موفقیت ایجاد شد')),
      );
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ایجاد هشدار');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    _view.showLoading();
    try {
      await _api.deleteJobAlert(alertId);
      _view.onAlertDeleted(alertId);
      ScaffoldMessenger.of(_view.getContext()).showSnackBar(
        const SnackBar(content: Text('هشدار با موفقیت حذف شد')),
      );
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در حذف هشدار');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> toggleAlert(String alertId, bool isActive) async {
    try {
      await _api.toggleJobAlert(alertId, isActive);
      await loadAlerts(); // Refresh list
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در تغییر وضعیت هشدار');
    }
  }
}