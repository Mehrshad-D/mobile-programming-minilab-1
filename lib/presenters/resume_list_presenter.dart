import '../models/api_response.dart';
import '../models/resume.dart';
import '../services/api_service.dart';

/// Contract for the "My Resumes" manager screen.
abstract class ResumeListView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void onResumesLoaded(List<Resume> resumes);
  void onResumeCreated(Resume resume);
  void onResumeDeleted();
}

/// Handles listing, creating and deleting resumes (multi-resume support).
class ResumeListPresenter {
  final ResumeListView _view;
  final ApiService _api;

  ResumeListPresenter(this._view, this._api);

  Future<void> loadResumes() async {
    _view.showLoading();
    try {
      final resumes = await _api.getResumes();
      _view.onResumesLoaded(resumes);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در دریافت لیست رزومه‌ها');
    } finally {
      _view.hideLoading();
    }
  }

  /// Creates a new, empty resume. The mock fills name/email/slug defaults
  /// from the signed-in user when [name] is blank.
  Future<void> createResume(String name) async {
    _view.showLoading();
    try {
      final created = await _api.createResume(
        Resume(id: '', name: name.trim(), email: ''),
      );
      _view.onResumeCreated(created);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ایجاد رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteResume(String cvId) async {
    _view.showLoading();
    try {
      await _api.deleteResume(cvId);
      _view.onResumeDeleted();
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در حذف رزومه');
    } finally {
      _view.hideLoading();
    }
  }
}
