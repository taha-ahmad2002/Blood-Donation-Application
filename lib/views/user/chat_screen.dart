import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Responsive helper class
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 16;
    return 20;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.1;
    return desktopSize ?? mobileSize * 1.2;
  }

  static double getResponsiveImageSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.2;
    return desktopSize ?? mobileSize * 1.4;
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({Key? key, required this.receiverId, required this.receiverName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _receiverProfilePicUrl;
  bool _isLoading = true;

  void sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(widget.receiverId, _messageController.text.trim());
      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReceiverProfilePic();
  }

  Future<void> _fetchReceiverProfilePic() async {
    try {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      setState(() {
        _receiverProfilePicUrl = userSnapshot.data()?['profileImage'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching receiver profile picture: $e');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = (timestamp as Timestamp).toDate();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final appBarTitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 16, tabletSize: 18, desktopSize: 20);
    final messageFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 14, tabletSize: 15, desktopSize: 16);
    final timestampFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 11, tabletSize: 12, desktopSize: 13);
    final avatarRadius = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 20, tabletSize: 24, desktopSize: 28);
    final inputFieldPadding = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 12, tabletSize: 14, desktopSize: 16);
    final sendButtonRadius = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 24, tabletSize: 28, desktopSize: 32);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        titleSpacing: 0,
        title: Row(
          children: [
            _isLoading
                ? CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.deepPurple[200],
                    child: ClipOval(
                      child: _receiverProfilePicUrl != null &&
                          _receiverProfilePicUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _receiverProfilePicUrl!,
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: Colors.white),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
            SizedBox(width: responsivePadding * 0.5),
            Expanded(
              child: Text(
                widget.receiverName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: appBarTitleFontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.receiverId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  );
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsivePadding,
                    vertical: responsivePadding * 0.5,
                  ),
                  itemCount: messages.length,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSender =
                        message['senderId'] == _auth.currentUser!.uid;

                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: inputFieldPadding,
                          vertical: inputFieldPadding * 0.75,
                        ),
                        margin: EdgeInsets.symmetric(
                          vertical: responsivePadding * 0.3,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isSender
                              ? Colors.deepPurple[400]
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                Radius.circular(isSender ? 16 : 0),
                            bottomRight:
                                Radius.circular(isSender ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isSender
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: GoogleFonts.poppins(
                                color:
                                    isSender ? Colors.white : Colors.black87,
                                fontSize: messageFontSize,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: responsivePadding * 0.2),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: GoogleFonts.poppins(
                                color:
                                    isSender ? Colors.white70 : Colors.black54,
                                fontSize: timestampFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsivePadding * 0.75,
              vertical: responsivePadding * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: inputFieldPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: messageFontSize,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: messageFontSize * 0.9,
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: inputFieldPadding * 0.5,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: responsivePadding * 0.5),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  radius: sendButtonRadius,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: sendButtonRadius * 0.8,
                    ),
                    onPressed: sendMessage,
                    iconSize: sendButtonRadius * 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
