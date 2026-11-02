import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Envoyer une demande d'ami
  Future<void> sendFriendRequest({
    required String senderId,
    required String senderUsername,
    String? senderPhotoUrl,
    required String receiverId,
  }) async {
    final id = _uuid.v4();
    final request = FriendRequestModel(
      id: id,
      senderId: senderId,
      senderUsername: senderUsername,
      senderPhotoUrl: senderPhotoUrl,
      receiverId: receiverId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('friend_requests')
        .doc(id)
        .set(request.toMap());
  }

  // Accepter une demande
  Future<void> acceptFriendRequest(String requestId) async {
    final doc = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
    final request = FriendRequestModel.fromMap(doc.data()!);

    final batch = _firestore.batch();

    // Mettre à jour le statut
    batch.update(
      _firestore.collection('friend_requests').doc(requestId),
      {'status': 'accepted'},
    );

    // Ajouter dans la liste d'amis des deux users
    batch.update(
      _firestore.collection('users').doc(request.senderId),
      {
        'friends': FieldValue.arrayUnion([request.receiverId])
      },
    );
    batch.update(
      _firestore.collection('users').doc(request.receiverId),
      {
        'friends': FieldValue.arrayUnion([request.senderId])
      },
    );

    await batch.commit();
  }

  // Refuser une demande
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // Supprimer un ami
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'friends': FieldValue.arrayRemove([friendId])
      },
    );
    batch.update(
      _firestore.collection('users').doc(friendId),
      {
        'friends': FieldValue.arrayRemove([userId])
      },
    );
    await batch.commit();
  }

  // Vérifier le statut d'amitié
  Future<String> getFriendStatus({
    required String currentUserId,
    required String otherUserId,
  }) async {
    // Vérifier si déjà amis
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final friends =
        List<String>.from(userDoc.data()?['friends'] ?? []);
    if (friends.contains(otherUserId)) return 'friends';

    // Vérifier demande envoyée
    final sentQuery = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: otherUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (sentQuery.docs.isNotEmpty) return 'sent';

    // Vérifier demande reçue
    final receivedQuery = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (receivedQuery.docs.isNotEmpty) return 'received';

    return 'none';
  }

  // Stream des demandes reçues
  Stream<List<FriendRequestModel>> getPendingRequestsStream(
      String userId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FriendRequestModel.fromMap(doc.data()))
            .toList());
  }

  // Stream de la liste d'amis
  Stream<List<UserModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      final friends =
          List<String>.from(doc.data()?['friends'] ?? []);
      if (friends.isEmpty) return [];

      final users = await Future.wait(
        friends.map((friendId) => _firestore
            .collection('users')
            .doc(friendId)
            .get()),
      );
      return users
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!))
          .toList();
    });
  }
}