import 'dart:io';
import 'package:cross_file/cross_file.dart';
import '../models/resume.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../models/api_response.dart';

/// Contract for the resume screen
abstract class ResumeView {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void showResume(Resume resume);
  void onResumeUpdated(Resume resume);
  void onScoreUpdated(int score);
  void onResumeLink(String link);
  void onResumesLoaded(List<Resume> resumes);
  void onTranslationLoaded(Map<String, dynamic> translation);
}

/// Manages resume/CV builder operations
class ResumePresenter {
  final ResumeView _view;
  final ApiService _api;

  ResumePresenter(this._view, this._api);

  Future<void> loadResume() async {
    _view.showLoading();
    try {
      final resume = await _api.getResume();
      _view.showResume(resume);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  /// Loads a specific resume by id (used when editing one of several resumes).
  Future<void> loadResumeById(String cvId) async {
    _view.showLoading();
    try {
      final resume = await _api.getResumeById(cvId);
      _view.showResume(resume);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError(AppStrings.networkError);
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> createResume(Resume resume) async {
    _view.showLoading();
    try {
      final newResume = await _api.createResume(resume);
      _view.onResumeUpdated(newResume);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ایجاد رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateResume(Resume resume) async {
    _view.showLoading();
    try {
      final updated = await _api.updateResume(resume);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در به‌روزرسانی رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updatePersonalInfo(Map<String, dynamic> personalInfo) async {
    _view.showLoading();
    try {
      final updated = await _api.updatePersonalInfo(personalInfo);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در به‌روزرسانی اطلاعات شخصی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> addEducation(Education education) async {
    _view.showLoading();
    try {
      final updated = await _api.addEducation(education);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در افزودن سابقه تحصیلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateEducation(String educationId, Education education) async {
    _view.showLoading();
    try {
      final updated = await _api.updateEducation(educationId, education);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ویرایش سابقه تحصیلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteEducation(String educationId) async {
    _view.showLoading();
    try {
      await _api.deleteEducation(educationId);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در حذف سابقه تحصیلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> addExperience(WorkExperience experience) async {
    _view.showLoading();
    try {
      final updated = await _api.addExperience(experience);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در افزودن سابقه شغلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateExperience(String experienceId, WorkExperience experience) async {
    _view.showLoading();
    try {
      final updated = await _api.updateExperience(experienceId, experience);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در ویرایش سابقه شغلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteExperience(String experienceId) async {
    _view.showLoading();
    try {
      await _api.deleteExperience(experienceId);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در حذف سابقه شغلی');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateLanguages(List<Language> languages) async {
    _view.showLoading();
    try {
      final updated = await _api.updateLanguages(languages);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در به‌روزرسانی زبان‌ها');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> updateSkills(List<String> skills) async {
    _view.showLoading();
    try {
      final updated = await _api.updateSkills(skills);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در به‌روزرسانی مهارت‌ها');
    } finally {
      _view.hideLoading();
    }
  }

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

  Future<void> loadTranslation(String lang) async {
    _view.showLoading();
    try {
      final translation = await _api.getResumeTranslation(lang);
      _view.onTranslationLoaded(translation);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در دریافت ترجمه رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> loadResumeLink() async {
    _view.showLoading();
    try {
      final link = await _api.getResumeLink();
      _view.onResumeLink(link);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در دریافت لینک رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> getResumeScore() async {
    try {
      final score = await _api.getResumeScore();
      _view.onScoreUpdated(score);
    } catch (_) {
      // Ignore score errors
    }
  }

  Future<void> togglePublicity(bool isPublic) async {
    try {
      await _api.togglePublicity(isPublic);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در تغییر وضعیت عمومی');
    }
  }

  Future<void> toggleSearchStatus(bool isSearchable) async {
    try {
      await _api.toggleSearchStatus(isSearchable);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در تغییر وضعیت جستجو');
    }
  }

  Future<void> updateSlug(String cvId, String slug) async {
    _view.showLoading();
    try {
      final updated = await _api.updateResumeSlug(cvId, slug);
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در به‌روزرسانی آدرس رزومه');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> uploadAvatar(String cvId, XFile imageFile) async {
    _view.showLoading();
    try {
      await _api.uploadCvAvatar(cvId, imageFile);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در آپلود تصویر پروفایل');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> uploadCvFile(File file) async {
    _view.showLoading();
    try {
      await _api.uploadResumeFile(file);
      final updated = await _api.getResume();
      _view.onResumeUpdated(updated);
    } on ApiException catch (e) {
      _view.showError(e.message);
    } catch (_) {
      _view.showError('خطا در آپلود فایل رزومه');
    } finally {
      _view.hideLoading();
    }
  }
}