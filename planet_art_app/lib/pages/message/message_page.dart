import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:planet_art_app/pages/message/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessagePage extends StatefulWidget {
  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void searchUsers(String query) async {
    final result = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .get();
    setState(() {
      filteredUsers = result.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Store the user document ID
        return data;
      }).toList();
    });
  }

  void _startConversation(String userId) async {
    // Check if conversation exists, if not create one
    final conversation = await _firestore
        .collection('conversations')
        .where('users', arrayContains: userId)
        .limit(1)
        .get();

    if (conversation.docs.isEmpty) {
      final newConversation = await _firestore.collection('conversations').add({
        'users': [userId],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(userId: userId, conversationId: newConversation.id),
        ),
      ).then((_) {
        setState(() {}); // Refresh state when returning from ChatScreen
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
              userId: userId, conversationId: conversation.docs.first.id),
        ),
      ).then((_) {
        setState(() {}); // Refresh state when returning from ChatScreen
      });
    }
  }

  Widget _buildConversationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('conversations')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: Text("No messages yet"));
        }
        var conversations = snapshot.data!.docs;
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            var conversation = conversations[index];
            var conversationData = conversation.data() as Map<String, dynamic>;
            if (!conversationData.containsKey('users')) {
              return ListTile(title: Text('Invalid conversation data'));
            }
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('users')
                  .doc(conversationData['users'][0])
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return ListTile(title: Text('Loading...'));
                }
                var user = userSnapshot.data!;
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(user['profileImageUrl'] ?? ''),
                      ),
                      title: Text(
                        user['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        conversationData['lastMessage'],
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                conversationId: conversation.id,
                                userId: user.id),
                          ),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                    ),
                    Divider(color: Colors.grey),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(filteredUsers[index]['profileImageUrl'] ?? ''),
              ),
              title: Text(
                filteredUsers[index]['name'],
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                _startConversation(filteredUsers[index]['id']);
              },
            ),
            Divider(color: Colors.grey),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 53, 48, 115),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Color.fromARGB(255, 53, 48, 115),
          flexibleSpace: Column(
            children: [
              SizedBox(height: 40.0),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      margin: EdgeInsets.only(right: 16.0),
                      child: CachedNetworkImage(
                        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/planet-art-app.appspot.com/o/app%2Ficons8-planet-48%20(1).png?alt=media&token=e4297794-f47d-4b68-ab82-9a39f3049ed5',
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search users',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          ),
                          style: TextStyle(color: Colors.black),
                          onChanged: (value) {
                            searchUsers(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 29.0,
                    color: Color.fromARGB(255, 194, 189, 251),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildUserList()
                : _buildConversationList(),
          ),
        ],
      ),
    );
  }
}
