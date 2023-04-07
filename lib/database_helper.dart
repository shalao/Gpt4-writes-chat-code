import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "ChatDatabase.db";
  static final _databaseVersion = 1;

  static final tableMessages = "messages";
  static final columnId = "id";
  static final columnContent = "content";
  static final columnIsUser = "is_user";
  static final columnTimestamp = "timestamp";

  // Singleton instance.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database reference.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // Create the database.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMessages (
        $columnId INTEGER PRIMARY KEY,
        $columnContent TEXT NOT NULL,
        $columnIsUser INTEGER NOT NULL,
        $columnTimestamp TEXT NOT NULL
      )
      ''');
  }

  // Insert a message.
  Future<int> insert(Message message) async {
    Database db = await instance.database;
    return await db.insert(tableMessages, message.toMap());
  }

  // Load messages.
  Future<List<Message>> loadMessages() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps =
        await db.query(tableMessages, orderBy: '$columnTimestamp ASC');
    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  Future<int?> getUserMessageCount() async {
    Database db = await instance.database;
    int? count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $tableMessages WHERE $columnIsUser = 1'));
    return count;
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    Database db = await instance.database;
    return await db.query(tableMessages, orderBy: '$columnId ASC');
  }
}

class Message {
  final int? id;
  final String content;
  final bool isUser;
  final String timestamp;

  List<Message> _messages = [];
  Message({
    this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: map['timestamp'],
    );
  }
}
