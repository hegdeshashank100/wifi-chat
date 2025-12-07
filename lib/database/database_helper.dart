import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wifi_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Contacts table
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarPath TEXT,
        bio TEXT,
        lastSeen INTEGER NOT NULL,
        isOnline INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        isMe INTEGER NOT NULL,
        fileName TEXT,
        fileSize INTEGER,
        FOREIGN KEY (chatId) REFERENCES contacts (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_messages_chatId ON messages(chatId)');
    await db
        .execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
  }

  // Contact operations
  Future<Contact> insertContact(Contact contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return contact;
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final result = await db.query(
      'contacts',
      orderBy: 'name ASC',
    );
    return result.map((map) => Contact.fromMap(map)).toList();
  }

  Future<Contact?> getContact(String id) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Contact.fromMap(result.first);
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(String id) async {
    final db = await database;
    // Delete contact and all associated messages
    await db.delete('messages', where: 'chatId = ?', whereArgs: [id]);
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // Message operations
  Future<Message> insertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return message;
  }

  Future<List<Message>> getMessages(String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<Message?> getLastMessage(String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Message.fromMap(result.first);
  }

  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> getUnreadCount(String chatId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE chatId = ? AND isMe = 0 AND status < ?',
      [chatId, MessageStatus.read.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> markMessagesAsRead(String chatId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'status': MessageStatus.read.index},
      where: 'chatId = ? AND isMe = 0',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteAllMessages(String chatId) async {
    final db = await database;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
