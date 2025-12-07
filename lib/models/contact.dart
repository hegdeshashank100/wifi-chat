class Contact {
  final String id; // Device ID
  final String name;
  final String? avatarPath;
  final String? bio;
  final DateTime lastSeen;
  final bool isOnline;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    this.avatarPath,
    this.bio,
    required this.lastSeen,
    this.isOnline = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'bio': bio,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isOnline': isOnline ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarPath: map['avatarPath'] as String?,
      bio: map['bio'] as String?,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int),
      isOnline: (map['isOnline'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Contact copyWith({
    String? name,
    String? avatarPath,
    String? bio,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt,
    );
  }
}
