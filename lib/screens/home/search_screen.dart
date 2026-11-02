import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_transitions.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../profile/user_profile_screen.dart';

enum SearchFilter { all, users, posts }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  SearchFilter _filter = SearchFilter.all;
  bool _loading = false;
  List<UserModel> _users = [];
  List<PostModel> _posts = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    setState(() {
      _query = q;
      _loading = q.isNotEmpty;
      if (q.isEmpty) {
        _users = [];
        _posts = [];
      }
    });

    if (q.isEmpty) return;

    try {
      final futures = await Future.wait([
        // Recherche users
        if (_filter == SearchFilter.all || _filter == SearchFilter.users)
          FirebaseFirestore.instance
              .collection('users')
              .where('usernameLower', isGreaterThanOrEqualTo: q)
              .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
              .limit(20)
              .get(),

        // Recherche posts par caption
        if (_filter == SearchFilter.all || _filter == SearchFilter.posts)
          FirebaseFirestore.instance
              .collection('posts')
              .where('captionLower', isGreaterThanOrEqualTo: q)
              .where('captionLower', isLessThanOrEqualTo: '$q\uf8ff')
              .limit(20)
              .get(),

        // Recherche posts par username
        if (_filter == SearchFilter.all || _filter == SearchFilter.posts)
          FirebaseFirestore.instance
              .collection('posts')
              .where('usernameLower', isGreaterThanOrEqualTo: q)
              .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
              .limit(20)
              .get(),
      ]);

      final List<UserModel> users = [];
      final List<PostModel> posts = [];
      final Set<String> postIds = {};

      int idx = 0;

      if (_filter == SearchFilter.all || _filter == SearchFilter.users) {
        final userSnap = futures[idx++] as QuerySnapshot;
        users.addAll(userSnap.docs
            .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
      }

      if (_filter == SearchFilter.all || _filter == SearchFilter.posts) {
        final captionSnap = futures[idx++] as QuerySnapshot;
        for (final d in captionSnap.docs) {
          final post =
              PostModel.fromMap(d.data() as Map<String, dynamic>);
          if (!postIds.contains(post.id)) {
            postIds.add(post.id);
            posts.add(post);
          }
        }

        final usernameSnap = futures[idx++] as QuerySnapshot;
        for (final d in usernameSnap.docs) {
          final post =
              PostModel.fromMap(d.data() as Map<String, dynamic>);
          if (!postIds.contains(post.id)) {
            postIds.add(post.id);
            posts.add(post);
          }
        }
      }

      // Exclure soi-même des users
      final currentUserId =
          ref.read(authStateProvider).value?.uid ?? '';
      users.removeWhere((u) => u.uid == currentUserId);

      setState(() {
        _users = users;
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textGrey,
              ),
              prefixIcon: const Icon(CupertinoIcons.search,
                  color: AppColors.textGrey, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          color: AppColors.textGrey, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _search,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tout',
                  selected: _filter == SearchFilter.all,
                  onTap: () {
                    setState(() => _filter = SearchFilter.all);
                    if (_query.isNotEmpty) _search(_query);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Personnes',
                  icon: CupertinoIcons.person_fill,
                  selected: _filter == SearchFilter.users,
                  onTap: () {
                    setState(() => _filter = SearchFilter.users);
                    if (_query.isNotEmpty) _search(_query);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Posts',
                  icon: CupertinoIcons.photo,
                  selected: _filter == SearchFilter.posts,
                  onTap: () {
                    setState(() => _filter = SearchFilter.posts);
                    if (_query.isNotEmpty) _search(_query);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Résultats
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _query.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.search,
                                size: 64, color: AppColors.textGrey),
                            const SizedBox(height: 16),
                            Text(
                              'Recherche des users, posts...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textGrey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty && _posts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.xmark_circle,
                                    size: 64,
                                    color: AppColors.textGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun résultat pour "$_query"',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textGrey,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              // Section users
                              if (_users.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 8),
                                  child: Text(
                                    'Personnes',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                                ..._users.map((user) => ListTile(
                                      onTap: () => Navigator.push(
                                        context,
                                        AppTransitions.slideRight(
                                          UserProfileScreen(
                                              userId: user.uid),
                                        ),
                                      ),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary,
                                        backgroundImage: user.photoUrl !=
                                                null
                                            ? CachedNetworkImageProvider(
                                                user.photoUrl!)
                                            : null,
                                        child: user.photoUrl == null
                                            ? Text(
                                                user.username[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Poppins',
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        user.username,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textLight
                                              : AppColors.textDark,
                                        ),
                                      ),
                                      subtitle: user.bio != null &&
                                              user.bio!.isNotEmpty
                                          ? Text(
                                              user.bio!,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                color: AppColors.textGrey,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: const Icon(
                                          CupertinoIcons.chevron_right,
                                          color: AppColors.textGrey,
                                          size: 16),
                                    )),
                                const Divider(),
                              ],

                              // Section posts
                              if (_posts.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 12, 16, 8),
                                  child: Text(
                                    'Posts',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                                ..._posts.map((post) =>
                                    PostCard(post: post)),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}