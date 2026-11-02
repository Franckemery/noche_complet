import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

final postServiceProvider = Provider<PostService>((ref) => PostService());

// Stream des posts favoris
final favoritePostsStreamProvider =
    StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return ref.watch(postServiceProvider).getFavoritePostsStream(userId);
});

// Pagination state
class PostsPaginationNotifier
    extends StateNotifier<AsyncValue<List<PostModel>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _limit = 15;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  PostsPaginationNotifier() : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    _lastDocument = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    try {
      final query = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(_limit)
          .get();

      _lastDocument = query.docs.isNotEmpty ? query.docs.last : null;
      _hasMore = query.docs.length == _limit;

      final posts =
          query.docs.map((doc) => PostModel.fromMap(doc.data())).toList();

      state = AsyncValue.data(posts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    _isLoading = true;

    try {
      final query = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit)
          .get();

      _lastDocument = query.docs.isNotEmpty ? query.docs.last : null;
      _hasMore = query.docs.length == _limit;

      final newPosts =
          query.docs.map((doc) => PostModel.fromMap(doc.data())).toList();

      final currentPosts = state.value ?? [];
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e) {
      // garde les posts existants
    } finally {
      _isLoading = false;
    }
  }

  bool get hasMore => _hasMore;
}

final postsPaginationProvider =
    StateNotifierProvider<PostsPaginationNotifier, AsyncValue<List<PostModel>>>(
  (ref) => PostsPaginationNotifier(),
);

// Notifier pour les actions sur les posts
class PostNotifier extends StateNotifier<AsyncValue<void>> {
  final PostService _postService;

  PostNotifier(this._postService) : super(const AsyncValue.data(null));

  Future<void> toggleLike(String postId, String userId) async {
    try {
      await _postService.toggleLike(postId, userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createPost({
    required String userId,
    required String username,
    String? userPhotoUrl,
    required String imageUrl,
    List<String> imageUrls = const [],
    String? caption,
    String? textBackground,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _postService.createPost(
        userId: userId,
        username: username,
        userPhotoUrl: userPhotoUrl,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        caption: caption,
        textBackground: textBackground,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      rethrow;
    }
  }
}

final postNotifierProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<void>>(
  (ref) => PostNotifier(ref.watch(postServiceProvider)),
);

// Stream en temps réel pour un post spécifique
final postStreamProvider =
    StreamProvider.family<PostModel?, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? PostModel.fromMap(doc.data()!) : null);
});
