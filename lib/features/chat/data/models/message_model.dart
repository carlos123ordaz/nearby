class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isRead => readAt != null;

  MessageModel copyWith({DateTime? readAt}) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
