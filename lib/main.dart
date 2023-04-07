import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'database_helper.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textEditingController = TextEditingController();

  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Map<String, dynamic> jsonResponseDecoder(dynamic data) {
    return json.decode(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(hintText: 'Send a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_textEditingController.text);
                    _textEditingController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: message.isUser
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: MarkdownBody(
                          data: message.content,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context))
                                  .copyWith(
                            p: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .apply(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: MarkdownBody(
                          data: message.content,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _loadMessages() async {
    final dbHelper = DatabaseHelper.instance;
    final messages =
        await dbHelper.loadMessages(); // 使用 loadMessages() 代替 getAllMessages()
    setState(() {
      _messages = messages;
    });
  }

  void _sendMessage(String content) async {
    if (content.trim().isEmpty) {
      return;
    }
    final dbHelper = DatabaseHelper.instance;
    final userMessageCount = await dbHelper.getUserMessageCount() ?? 0;
    if (userMessageCount >= 10) {
      await _showSubscriptionRequiredDialog(context);
      return;
    }

    await dbHelper.insert(Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now().toIso8601String(),
    ));

    _loadMessages();

    HttpClient client = HttpClient();
    Uri url = Uri.parse('');
    HttpClientRequest request = await client.getUrl(url);

// Send request and get response.
    HttpClientResponse response = await request.close();

    response
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .transform(json.decoder)
        .listen((dynamic jsonObject) {
      _handleResponse(jsonObject as Map<String, dynamic>);
    }, onError: (error) {
      // Handle errors.
    }, onDone: () {
      // Clean up when the stream is done.
      client.close();
    });
  }

  void _handleResponse(Map<String, dynamic> jsonObject) {
    if (jsonObject.containsKey('content')) {
      String content = jsonObject['content'];
// Handle content.
      DatabaseHelper.instance.insert(Message(
        content: content,
        isUser: false,
        timestamp: DateTime.now().toIso8601String(),
      ));
      _loadMessages();
    }
    if (jsonObject.containsKey('event')) {
      String event = jsonObject['event'];
      if (event == 'done') {
// Handle stream completion.
      }
    }
    if (jsonObject.containsKey('tip')) {
      String tip = jsonObject['tip'];
// Handle tip.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('提示'),
          content: Text(tip),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showSubscriptionRequiredDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('订阅提示'),
          content: Text('您已经发送了 10 条消息，需要订阅以继续使用'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
// TODO: Implement subscription flow.
              },
              child: Text('订阅'),
            ),
          ],
        );
      },
    );
  }
}
