import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_transitions.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

final chatsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) {
  return ChatService().getChatsStream(userId);
});

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final chatsAsync = ref.watch(chatsStreamProvider(currentUserId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chat_bubble_2,
                      size: 64, color: AppColors.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commence à chatter avec tes amis !',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants =
                  List<String>.from(chat['participants'] ?? []);
              final friendId = participants
                  .firstWhere((id) => id != currentUserId);
              final unreadCount =
                  chat['unreadCount_$currentUserId'] ?? 0;
              final lastMessage = chat['lastMessage'] ?? '';
              final lastMessageTime = chat['lastMessageTime'] != null
                  ? DateTime.parse(chat['lastMessageTime'])
                  : DateTime.now();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final friend = UserModel.fromMap(
                      snapshot.data!.data() as Map<String, dynamic>);

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppTransitions.slideRight(
                          ChatScreen(friend: friend),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      backgroundImage: friend.photoUrl != null
                          ? CachedNetworkImageProvider(friend.photoUrl!)
                          : null,
                      child: friend.photoUrl == null
                          ? Text(
                              friend.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      friend.username,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textDark,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: unreadCount > 0
                            ? AppColors.primary
                            : AppColors.textGrey,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeago.format(lastMessageTime, locale: 'fr'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}