import '../models/job_skill.dart';
import '../services/api_service.dart';

/// Contract for the skill picker screen.
abstract class SkillSearchView {
  void showSkillSuggestions(List<JobSkill> suggestions);
}

/// Drives live skill suggestions for the resume skills screen
/// (`GET /api/v10/job/skills?query=`).
class SkillSearchPresenter {
  final SkillSearchView _view;
  final ApiService _api;

  SkillSearchPresenter(this._view, this._api);

  Future<void> search(String query) async {
    try {
      final results = await _api.searchSkills(query);
      _view.showSkillSuggestions(results);
    } catch (_) {
      // Suggestions are non-critical; fail silently and keep current list.
    }
  }
}
