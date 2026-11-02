import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// Stream du profil user connecté
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) =>
              doc.exists ? UserModel.fromMap(doc.data()!) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Notifier pour modifier le profil
class UserNotifier extends StateNotifier<AsyncValue<void>> {
  UserNotifier() : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required String uid,
    String? username,
    String? bio,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<void>>(
  (ref) => UserNotifier(),
);