class Chat {
  final String id; // Contact ID
  final String contactName;
  final String? contactAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  Chat({
    required this.id,
    required this.contactName,
    this.contactAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  Chat copyWith({
    String? contactName,
    String? contactAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
  }) {
    return Chat(
      id: id,
      contactName: contactName ?? this.contactName,
      contactAvatar: contactAvatar ?? this.contactAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
