import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/notice.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class KnowledgeUseCase {
  KnowledgeUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<List<KnowledgeArticle>>> fetchArticles({
    String? language,
    String? keyword,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final articles = await _adapter.fetchKnowledge(
        _site, auth,
        language: language,
        keyword: keyword,
      );
      return Success(articles);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<KnowledgeArticle>> fetchDetail({required int id}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final article = await _adapter.fetchKnowledgeDetail(_site, auth, id);
      return Success(article);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
