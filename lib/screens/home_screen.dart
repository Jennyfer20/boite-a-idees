import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/idea.dart';
import '../services/auth_service.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';
import 'submit_screen.dart';
import 'ideas_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _auth = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final admin = await _auth.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _HomeTab(),
      const SubmitScreen(),
      const IdeasScreen(),
      if (_isAdmin) const AdminScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          const NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Proposer'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Idées'),
          if (_isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _auth = AuthService();
  final _service = IdeaService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: Colors.white70, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Bonjour, ${_auth.currentUserName.split(' ').first} !',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Partagez vos idées avec l\'équipe',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(service: _service),
                const SizedBox(height: 24),
                const Text('Idées populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PopularIdeasList(service: _service, auth: _auth),
                const SizedBox(height: 24),
                const Text('Mes idées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _MyIdeasList(service: _service, auth: _auth),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final IdeaService service;
  const _StatsRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: service.getTotalIdeas(),
            builder: (_, snap) => _StatCard(
              label: 'Total idées',
              value: '${snap.data ?? 0}',
              icon: Icons.lightbulb_outline,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int>(
            future: service.getIdeasThisMonth(),
            builder: (_, snap) => _StatCard(
              label: 'Ce mois',
              value: '${snap.data ?? 0}',
              icon: Icons.calendar_today_outlined,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularIdeasList extends StatelessWidget {
  final IdeaService service;
  final AuthService auth;

  const _PopularIdeasList({required this.service, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.getIdeas(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final ideas = snap.data!.where((i) => i.likesCount > 0).take(5).toList();
        if (ideas.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.lightbulb_outline, size: 48, color: AppColors.textLight),
                  SizedBox(height: 8),
                  Text('Aucune idée pour l\'instant', style: TextStyle(color: AppColors.textSecondary)),
                  Text('Soyez le premier à proposer une idée !', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: ideas.map((idea) => _IdeaCardSmall(idea: idea, service: service, auth: auth)).toList(),
        );
      },
    );
  }
}

class _IdeaCardSmall extends StatelessWidget {
  final Idea idea;
  final IdeaService service;
  final AuthService auth;

  const _IdeaCardSmall({required this.idea, required this.service, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(idea: idea))),
        title: Text(idea.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(idea.displayAuthor, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: AppColors.liked, size: 18),
            const SizedBox(width: 4),
            Text('${idea.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.liked)),
          ],
        ),
      ),
    );
  }
}

class _MyIdeasList extends StatelessWidget {
  final IdeaService service;
  final AuthService auth;

  const _MyIdeasList({required this.service, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.getMyIdeas(auth.currentUserId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final ideas = snap.data!;
        if (ideas.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.edit_note, size: 48, color: AppColors.textLight),
                  SizedBox(height: 8),
                  Text('Vous n\'avez pas encore soumis d\'idée', style: TextStyle(color: AppColors.textSecondary)),
                  Text('Appuyez sur "Proposer" pour commencer !', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
          );
        }
        return AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50,
                child: FadeInAnimation(child: widget),
              ),
              children: ideas.map((idea) => _MyIdeaCard(idea: idea)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _MyIdeaCard extends StatelessWidget {
  final Idea idea;
  const _MyIdeaCard({required this.idea});

  Color get _statutColor => switch (idea.statut) {
        'Nouvelle' => AppColors.statusNouvelle,
        'Lu' => AppColors.statusLu,
        "En cours d'étude" => AppColors.statusEnCours,
        'Archivée' => AppColors.statusArchivee,
        _ => AppColors.textLight,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(idea: idea))),
        title: Text(idea.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _statutColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(idea.statut, style: TextStyle(fontSize: 11, color: _statutColor, fontWeight: FontWeight.w600)),
            ),
            if (idea.isAnonymous) ...[
              const SizedBox(width: 6),
              const Icon(Icons.visibility_off, size: 12, color: AppColors.textLight),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: AppColors.liked, size: 18),
            const SizedBox(width: 4),
            Text('${idea.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.liked)),
          ],
        ),
      ),
    );
  }
}
