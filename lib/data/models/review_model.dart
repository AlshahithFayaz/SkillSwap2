class ReviewModel {
  final String id;
  final String requestId;
  final String reviewerId;
  final String revieweeId;
  final int stars; // 1 to 5
  final String comment;
  final DateTime createdAt;
  final String? reviewerName;

  ReviewModel({
    required this.id,
    required this.requestId,
    required this.reviewerId,
    required this.revieweeId,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'stars': stars,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'reviewerName': reviewerName,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['createdAt'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        try {
          parsedDate = (rawDate as dynamic).toDate();
        } catch (_) {}
      }
    }

    return ReviewModel(
      id: documentId ?? map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 5,
      comment: map['comment'] ?? '',
      createdAt: parsedDate,
      reviewerName: map['reviewerName'],
    );
  }
}
