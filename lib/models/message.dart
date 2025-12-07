enum MessageType {
  text,
  image,
  file,
  voice,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String chatId; // Contact ID
  final String senderId;
  final String receiverId;
  final String content; // Text or file path
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isMe;
  final String? fileName;
  final int? fileSize;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.isMe,
    this.fileName,
    this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isMe': isMe ? 1 : 0,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      type: MessageType.values[map['type'] as int],
      status: MessageStatus.values[map['status'] as int],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isMe: (map['isMe'] as int) == 1,
      fileName: map['fileName'] as String?,
      fileSize: map['fileSize'] as int?,
    );
  }

  Message copyWith({
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      isMe: isMe,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  // For network transfer
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      type: MessageType.values[json['type'] as int],
      status: MessageStatus.sent,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isMe: false,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }
}
