/// 公告
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imgUrl,
  });

  final int id;
  final String title;
  final String content;
  final String? imgUrl;
  final DateTime createdAt;
}

/// 知识库文章
class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.updatedAt,
    this.body,
    this.language,
  });

  final int id;
  final String title;
  final String category;
  final String? body;
  final String? language;
  final DateTime updatedAt;
}

/// 礼品卡预览
class GiftCardPreview {
  const GiftCardPreview({
    required this.code,
    required this.canRedeem,
    this.reason,
    this.rewardPreview = const [],
  });

  final String code;
  final bool canRedeem;
  final String? reason;
  final List<Map<String, dynamic>> rewardPreview;
}

/// 流量统计日志（单日）
class TrafficRecord {
  const TrafficRecord({
    required this.date,
    required this.uploadBytes,
    required this.downloadBytes,
  });

  final DateTime date;
  final int uploadBytes;
  final int downloadBytes;

  int get totalBytes => uploadBytes + downloadBytes;
}
