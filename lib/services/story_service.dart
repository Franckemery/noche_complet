import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Créer une story
  Future<void> createStory({
    required String userId,
    required String username,
    String? userPhotoUrl,
    String? imageUrl,
    String? text,
    String? textBackground,
    required int duration,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final story = StoryModel(
      id: id,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      imageUrl: imageUrl,
      text: text,
      textBackground: textBackground,
      duration: duration,
      createdAt: now,
      expiresAt: now.add(Duration(hours: duration)),
      viewedBy: [],
    );

    await _firestore.collection('stories').doc(id).set(story.toMap());
  }

  // Récupérer les stories actives
  Stream<List<StoryModel>> getActiveStoriesStream() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snap) {
      final stories = snap.docs
          .map((doc) => StoryModel.fromMap(doc.data()))
          .where((story) => !story.isExpired)
          .toList();
      return stories;
    });
  }

  // Récupérer les stories groupées par user
  Stream<Map<String, List<StoryModel>>> getGroupedStoriesStream() {
    return getActiveStoriesStream().map((stories) {
      final Map<String, List<StoryModel>> grouped = {};
      for (final story in stories) {
        if (!grouped.containsKey(story.userId)) {
          grouped[story.userId] = [];
        }
        grouped[story.userId]!.add(story);
      }
      return grouped;
    });
  }

  // Marquer une story comme vue
  Future<void> markAsViewed(String storyId, String userId) async {
    await _firestore.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Supprimer les stories expirées
  Future<void> deleteExpiredStories() async {
    final snap = await _firestore
        .collection('stories')
        .where('expiresAt',
            isLessThan: DateTime.now().toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Supprimer une story
  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }

  // Republier une story
  Future<void> reshareStory({
    required StoryModel story,
    required String userId,
    required String username,
    String? userPhotoUrl,
    required int duration,
  }) async {
    await createStory(
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      imageUrl: story.imageUrl,
      text: story.text,
      textBackground: story.textBackground,
      duration: duration,
    );
  }
}