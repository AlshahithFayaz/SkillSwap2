class MessageModel {
  final String id;
  final String requestId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? senderName;
  final String? imageBase64;

  MessageModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.senderName,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'imageBase64': imageBase64,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['timestamp'];
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

    return MessageModel(
      id: documentId ?? map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedDate,
      senderName: map['senderName'],
      imageBase64: map['imageBase64'],
    );
  }
}
