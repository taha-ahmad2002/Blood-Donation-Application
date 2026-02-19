import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatUsersScreen extends StatefulWidget {
  ChatUsersScreen({Key? key}) : super(key: key);

  @override
  State<ChatUsersScreen> createState() => _ChatUsersScreenState();
}

class _ChatUsersScreenState extends State<ChatUsersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser!.uid;
    double screenWidth = MediaQuery.of(context).size.width;
    double avatarRadius = screenWidth * 0.08;
    double horizontalPadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chatUsers = snapshot.data!.docs;

          if (chatUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Messages Yet",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start a conversation with someone",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Go Back"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(horizontalPadding),
            itemCount: chatUsers.length,
            itemBuilder: (context, index) {
              var chatUser = chatUsers[index];

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: screenWidth * 0.025,
                  ),
                  leading: FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('users')
                        .doc(chatUser['chatWith'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;

                      final profilePicUrl = userData?['profileImage'];

                      return CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (profilePicUrl != null &&
                                profilePicUrl.toString().isNotEmpty)
                            ? NetworkImage(profilePicUrl)
                            : null,
                        child: (profilePicUrl == null ||
                                profilePicUrl.toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                  title: Text(
                    chatUser['chatWithName'] ?? 'Unknown User',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  subtitle: chatUser['lastMessage'] != null
                      ? Text(
                          chatUser['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: screenWidth * 0.035,
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey),
                      const SizedBox(height: 5),
                      if ((chatUser['unreadCount'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatUser['unreadCount'].toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await _firestore
                        .collection('users')
                        .doc(currentUserId)
                        .collection('chats')
                        .doc(chatUser.id)
                        .update({'unreadCount': 0});

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: chatUser['chatWith'],
                          receiverName: chatUser['chatWithName'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
