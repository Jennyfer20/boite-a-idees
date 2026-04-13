import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/idea.dart';
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
  bool? _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.idea.likesCount;
    _service.hasLiked(widget.idea.id, _auth.currentUserId).then((v) {
      if (mounted) setState(() => _liked = v);
    });
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked ?? false;
    setState(() {
      _liked = !wasLiked;
      _likesCount += wasLiked ? -1 : 1;
    });
    await _service.toggleLike(widget.idea.id, _auth.currentUserId);
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
                              _liked == true ? 'J\'aime cette idée' : 'J\'aime cette idée',
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
          ],
        ),
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
