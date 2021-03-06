import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Socket socket;
  String otherSocketId = '';
  bool otherTyping = false;
  final message = [];

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    _connectToServer();
    _messageController.addListener(() {
      _sendTyping(true);
    });
    super.initState();
  }

  // Send update of user's typing status
  _sendTyping(bool typing) {
    socket.emit("typing", {
      "id": socket.id,
      "typing": typing,
    });
  }

  void _connectToServer() {
    try {
      socket = io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // connect to web socket
      socket.connect();

      // handle socket event
      socket.on('connect', (data) => print('hoan.dv: connect ${socket.id}'));
      socket.on('typing', (data) => _handleTyping(data));
      socket.on('message', (data) => _handleMessage(data));
    } catch (e) {
      print('hoan.dv: error is ${e.toString()}');
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final userSend = data['id'];
    final receiveMsg = data['message'];
    message.add(receiveMsg);
    setState(() {});
  }

  void _handleTyping(Map<String, dynamic> data) {
    print('hoan.dv: the user is typing');

    final userId = data['id'];
    if (userId != socket.id) {
      otherSocketId = userId;
      otherTyping = data['typing'] as bool;
      setState(() {});
    }
  }

  // Send a Message to the server
  _sendMessage(String message) {
    socket.emit(
      "message",
      {
        "id": socket.id,
        "message": message, // Message to be sent
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      socket.dispose();
    } else {
      socket.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: message.length,
                itemBuilder: (_, index) {
                  final msg = message[index];
                  return Text(msg);
                },
              ),
            ),
            SizedBox(
              height: 60,
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            // width: 0.0 produces a thin "hairline" border
                            borderSide:
                                BorderSide(color: Colors.grey, width: 0.5),
                          ),
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.green),
                        ),
                        controller: _messageController,
                        onEditingComplete: () {
                          _sendTyping(false);
                        }),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      // send message:
                      _sendMessage(_messageController.text);
                      _messageController.clear();
                    },
                    child: const Icon(
                      Icons.send,
                      size: 36,
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: otherTyping,
              child: Text('$otherSocketId is typing'),
            )
          ],
        ),
      ),
    );
  }
}
