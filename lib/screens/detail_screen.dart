import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/idea.dart';
import '../models/comment.dart';
import '../services/auth_service.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final Idea idea;
  const DetailScreen({super.key, required this.idea});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _service = IdeaService();
  final _auth = AuthService();
  final _commentCtrl = TextEditingController();
  bool? _liked;
  late int _likesCount;
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.idea.likesCount;
    _service.hasLiked(widget.idea.id, _auth.currentUserId).then((v) {
      if (mounted) setState(() => _liked = v);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked ?? false;
    setState(() {
      _liked = !wasLiked;
      _likesCount += wasLiked ? -1 : 1;
    });
    await _service.toggleLike(widget.idea.id, _auth.currentUserId);
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await _service.addComment(
        ideaId: widget.idea.id,
        authorId: _auth.currentUserId,
        authorName: _auth.currentUserName,
        text: text,
      );
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'idée'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(idea.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        _StatusBadge(statut: idea.statut),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _MetaChip(icon: Icons.person_outline, label: idea.displayAuthor),
                        _MetaChip(icon: Icons.access_time, label: timeago.format(idea.createdAt, locale: 'fr')),
                        if (idea.category.isNotEmpty)
                          _MetaChip(icon: Icons.label_outline, label: idea.category),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(idea.description,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bouton Like
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _liked == true
                              ? AppColors.liked.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _liked == true ? AppColors.liked : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _liked == true ? Icons.favorite : Icons.favorite_border,
                              color: _liked == true ? AppColors.liked : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _liked == true ? 'Vous aimez cette idée' : 'J\'aime cette idée',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _liked == true ? AppColors.liked : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text('$_likesCount',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.liked)),
                        const Text('like(s)', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section commentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Commentaires', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Comment>>(
                      stream: _service.getComments(idea.id),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        final comments = snap.data!;
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text('Aucun commentaire. Soyez le premier !',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ),
                          );
                        }
                        return Column(
                          children: comments.map((c) => _CommentTile(
                            comment: c,
                            currentUserId: _auth.currentUserId,
                            onDelete: () => _service.deleteComment(c.id),
                          )).toList(),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Ajouter un commentaire...'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _sendingComment
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                                onPressed: _sendComment,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback onDelete;

  const _CommentTile({required this.comment, required this.currentUserId, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(timeago.format(comment.createdAt, locale: 'fr'),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
              ],
            ),
          ),
          if (comment.authorId == currentUserId)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textLight),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14, color: AppColors.textSecondary),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({required this.statut});

  Color get _color => switch (statut) {
        'Nouvelle' => AppColors.statusNouvelle,
        'Lu' => AppColors.statusLu,
        'En cours d\'étude' => AppColors.statusEnCours,
        'Archivée' => AppColors.statusArchivee,
        _ => AppColors.textLight,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(statut,
          style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}
