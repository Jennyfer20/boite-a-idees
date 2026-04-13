import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/idea.dart';
import '../services/auth_service.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final _service = IdeaService();
  final _auth = AuthService();
  String _search = '';
  String _selectedCategory = 'Toutes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcourir les idées')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher une idée...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          StreamBuilder(
            stream: _service.getIdeas(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final ideas = snap.data!;
              final categories = ['Toutes', ...{...ideas.where((i) => i.category.isNotEmpty).map((i) => i.category)}];
              return SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final selected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500),
                        checkmarkColor: Colors.white,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: _service.getIdeas(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var ideas = snap.data!;

                if (_search.length >= 2) {
                  ideas = ideas.where((i) =>
                    i.title.toLowerCase().contains(_search.toLowerCase()) ||
                    i.description.toLowerCase().contains(_search.toLowerCase())
                  ).toList();
                }
                if (_selectedCategory != 'Toutes') {
                  ideas = ideas.where((i) => i.category == _selectedCategory).toList();
                }

                if (ideas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('Aucune idée trouvée', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ideas.length,
                    itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: IdeaCard(
                            idea: ideas[i],
                            service: _service,
                            auth: _auth,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class IdeaCard extends StatelessWidget {
  final Idea idea;
  final IdeaService service;
  final AuthService auth;

  const IdeaCard({super.key, required this.idea, required this.service, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(idea: idea))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(idea.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  _StatusBadge(statut: idea.statut),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                idea.description.length > 120 ? '${idea.description.substring(0, 120)}...' : idea.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (idea.category.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(idea.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(idea.displayAuthor, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(timeago.format(idea.createdAt, locale: 'fr'), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const Spacer(),
                  _LikeButton(idea: idea, service: service, auth: auth),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final Idea idea;
  final IdeaService service;
  final AuthService auth;

  const _LikeButton({required this.idea, required this.service, required this.auth});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool? _liked;

  @override
  void initState() {
    super.initState();
    widget.service.hasLiked(widget.idea.id, widget.auth.currentUserId).then((v) {
      if (mounted) setState(() => _liked = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final newVal = !(_liked ?? false);
        setState(() => _liked = newVal);
        await widget.service.toggleLike(widget.idea.id, widget.auth.currentUserId);
      },
      child: Row(
        children: [
          Icon(_liked == true ? Icons.favorite : Icons.favorite_border, color: AppColors.liked, size: 20),
          const SizedBox(width: 4),
          Text('${widget.idea.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.liked)),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(statut, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}
