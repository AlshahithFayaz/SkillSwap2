enum RequestStatus {
  pending,
  accepted,
  rejected;

  static RequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }

  String get value => name;
}

class ExchangeRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final RequestStatus status;
  final DateTime createdAt;
  final String? fromUserName;
  final String? toUserName;
  final String? fromUserDept;
  final String? toUserDept;

  ExchangeRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    this.fromUserName,
    this.toUserName,
    this.fromUserDept,
    this.toUserDept,
  });

  ExchangeRequestModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    RequestStatus? status,
    DateTime? createdAt,
    String? fromUserName,
    String? toUserName,
    String? fromUserDept,
    String? toUserDept,
  }) {
    return ExchangeRequestModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserDept: fromUserDept ?? this.fromUserDept,
      toUserDept: toUserDept ?? this.toUserDept,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserDept': fromUserDept,
      'toUserDept': toUserDept,
    };
  }

  factory ExchangeRequestModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
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

    return ExchangeRequestModel(
      id: documentId ?? map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      status: RequestStatus.fromString(map['status'] ?? 'pending'),
      createdAt: parsedDate,
      fromUserName: map['fromUserName'],
      toUserName: map['toUserName'],
      fromUserDept: map['fromUserDept'],
      toUserDept: map['toUserDept'],
    );
  }
}
