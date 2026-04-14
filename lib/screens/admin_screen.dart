import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = IdeaService();
    return Scaffold(
      body: StreamBuilder(
        stream: service.getIdeasByDate(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final ideas = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Administration',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _AdminStat(
                                  label: 'Total',
                                  value: '${ideas.length}',
                                  icon: Icons.lightbulb_outline,
                                ),
                                const SizedBox(width: 16),
                                _AdminStat(
                                  label: 'Nouvelles',
                                  value: '${ideas.where((i) => i.statut == 'Nouvelle').length}',
                                  icon: Icons.new_releases_outlined,
                                ),
                                const SizedBox(width: 16),
                                _AdminStat(
                                  label: 'En cours',
                                  value: '${ideas.where((i) => i.statut == "En cours d'étude").length}',
                                  icon: Icons.loop,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (ideas.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Aucune idée à gérer')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AdminIdeaCard(idea: ideas[i], service: service),
                      childCount: ideas.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _AdminIdeaCard extends StatefulWidget {
  final Idea idea;
  final IdeaService service;
  const _AdminIdeaCard({required this.idea, required this.service});

  @override
  State<_AdminIdeaCard> createState() => _AdminIdeaCardState();
}

class _AdminIdeaCardState extends State<_AdminIdeaCard> {
  late String _statut;
  late String _priorite;
  late TextEditingController _notesCtrl;
  bool _expanded = false;

  static const _statuts = ['Nouvelle', 'Lu', 'En cours d\'étude', 'Archivée'];
  static const _priorites = ['', 'Intéressant', 'Prioritaire'];

  @override
  void initState() {
    super.initState();
    _statut = widget.idea.statut;
    _priorite = widget.idea.prioriteAdmin;
    _notesCtrl = TextEditingController(text: widget.idea.notesAdmin);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Color get _statutColor => switch (_statut) {
        'Nouvelle' => AppColors.statusNouvelle,
        'Lu' => AppColors.statusLu,
        'En cours d\'étude' => AppColors.statusEnCours,
        'Archivée' => AppColors.statusArchivee,
        _ => AppColors.textLight,
      };

  Color get _prioriteColor => switch (_priorite) {
        'Intéressant' => AppColors.prioriteInteressant,
        'Prioritaire' => AppColors.prioritePrioritaire,
        _ => AppColors.textLight,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.idea.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Par: ${widget.idea.realAuthorName}${widget.idea.isAnonymous ? ' (anonyme)' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  timeago.format(widget.idea.createdAt, locale: 'fr'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statutColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_statut, style: TextStyle(fontSize: 10, color: _statutColor, fontWeight: FontWeight.bold)),
                ),
                if (_priorite.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _prioriteColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_priorite,
                        style: TextStyle(fontSize: 10, color: _prioriteColor, fontWeight: FontWeight.bold)),
                  ),
                ],
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(widget.idea.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _statut,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: _statuts.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() => _statut = v);
                                await widget.service.updateAdminFields(widget.idea.id, statut: v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Priorité', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _priorite,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: _priorites.map((p) => DropdownMenuItem(value: p, child: Text(p.isEmpty ? '—' : p, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) async {
                                if (v == null) return;
                                setState(() => _priorite = v);
                                await widget.service.updateAdminFields(widget.idea.id, prioriteAdmin: v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Notes admin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Ajouter des notes internes...'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: AppColors.liked, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.idea.likesCount} like(s)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Sauvegarder les notes'),
                        onPressed: () async {
                          await widget.service.updateAdminFields(widget.idea.id, notesAdmin: _notesCtrl.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notes sauvegardées'), backgroundColor: AppColors.success),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
