import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Générer un ID de conversation unique entre deux users
  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Envoyer un message
  Future<void> sendMessage({
    required String senderId,
    required String senderUsername,
    String? senderPhotoUrl,
    required String receiverId,
    required String text,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final id = _uuid.v4();

    final message = MessageModel(
      id: id,
      senderId: senderId,
      senderUsername: senderUsername,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
    );

    final batch = _firestore.batch();

    // Ajouter le message
    batch.set(
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(id),
      message.toMap(),
    );

    // Mettre à jour le dernier message
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'chatId': chatId,
        'participants': [senderId, receiverId],
        'lastMessage': text,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastSenderId': senderId,
        'unreadCount_$receiverId': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // Stream des messages
  Stream<List<MessageModel>> getMessagesStream(
      String userId1, String userId2) {
    final chatId = getChatId(userId1, userId2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // Stream des conversations
  Stream<List<Map<String, dynamic>>> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => doc.data()).toList());
  }

  // Marquer les messages comme lus
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount_$userId': 0,
    });
  }
}