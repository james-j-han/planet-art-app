import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String? conversationId;

  const ChatScreen({Key? key, required this.userId, this.conversationId})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final message = {
      'message': _messageController.text.trim(),
      'senderId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (widget.conversationId != null) {
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(message);
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': message['message'],
        'timestamp': FieldValue.serverTimestamp()
      });
    } else {
      final conversation = await _firestore.collection('conversations').add({
        'users': [widget.userId],
        'lastMessage': message['message'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      await conversation.collection('messages').add(message);
    }

    _messageController.clear();
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var messages = snapshot.data!.docs;
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            var messageData = message.data() as Map<String, dynamic>;
            bool isMe = messageData['senderId'] == widget.userId;
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blueAccent : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  messageData['message'],
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 53, 48, 115), // Purple background
      appBar: AppBar(
        title: Text('Chat', style: TextStyle(color: Colors.white)), // White text
        backgroundColor: Color.fromARGB(255, 40, 36, 85), // Slightly darker purple
        iconTheme: IconThemeData(color: Colors.white), // White back icon
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      fillColor: Colors.white.withOpacity(0.2), // Translucent white
                      filled: true,
                      hintStyle: TextStyle(color: Colors.white), // White hint text
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.white, // White send icon
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//updating
