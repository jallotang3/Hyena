import 'package:flutter/foundation.dart';

import '../core/models/commercial/notice.dart';
import '../core/result.dart';
import '../features/knowledge/knowledge_use_case.dart';

export '../core/models/commercial/notice.dart' show KnowledgeArticle;

/// KnowledgeController — 知识库的固定 API 边界
class KnowledgeController extends ChangeNotifier {
  KnowledgeController({required KnowledgeUseCase knowledgeUseCase})
      : _useCase = knowledgeUseCase;

  final KnowledgeUseCase _useCase;

  List<KnowledgeArticle> _articles = [];
  KnowledgeArticle? _currentArticle;
  bool _isLoading = false;
  String? _error;

  // ── 状态属性 ──
  List<KnowledgeArticle> get articles => _articles;
  KnowledgeArticle? get currentArticle => _currentArticle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── 操作方法 ──
  Future<void> fetchArticles({String? keyword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchArticles(keyword: keyword);
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _articles = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<void> fetchArticleDetail(int articleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchDetail(id: articleId);
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _currentArticle = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<void> search(String keyword) async {
    await fetchArticles(keyword: keyword);
  }
}
