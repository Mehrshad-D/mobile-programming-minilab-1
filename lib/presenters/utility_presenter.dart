import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/feedback.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Contract for utility screens
abstract class UtilityView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void onFeedbackSubmitted(FeedbackResult result);
  void onContactSubmitted(FeedbackResult result);
  void onEmailValidated(EmailValidationResult result);
  void onViolationReasonsLoaded(List<ViolationReason> reasons) {}
  void onViolationReported() {}
}

/// Presenter for utility operations
class UtilityPresenter {
  final UtilityView _view;
  final ApiService _api;

  UtilityPresenter(this._view, this._api);

  Future<void> submitFeedback(FeedbackRequest feedback) async {
    _view.showLoading();
    try {
      final result = await _api.submitFeedback(feedback);
      _view.onFeedbackSubmitted(result);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> submitContact(ContactRequest contact) async {
    _view.showLoading();
    try {
      final result = await _api.submitContact(contact);
      _view.onContactSubmitted(result);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> checkEmail(String email) async {
    _view.showLoading();
    try {
      final result = await _api.checkEmail(email);
      _view.onEmailValidated(result);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> loadViolationReasons() async {
    try {
      final reasons = await _api.getViolationReasons();
      _view.onViolationReasonsLoaded(reasons);
    } catch (_) {
      // Handle error silently
    }
  }

  Future<void> reportViolation(ViolationReport report) async {
    _view.showLoading();
    try {
      await _api.reportViolation(report);
      _view.onViolationReported();
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.genericError);
    } finally {
      _view.hideLoading();
    }
  }
}