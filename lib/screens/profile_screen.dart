import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _service = IdeaService();
  final _nameCtrl = TextEditingController();
  bool _editingName = false;
  bool _loadingName = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _auth.currentUserName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loadingName = true);
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUserId)
          .update({'displayName': name});
      if (mounted) {
        setState(() => _editingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nom mis à jour'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingName = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + nom
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        _auth.currentUserName.isNotEmpty
                            ? _auth.currentUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_editingName)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(labelText: 'Nom affiché'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _loadingName
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.check_circle, color: AppColors.success),
                                  onPressed: _saveName,
                                ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.textLight),
                            onPressed: () => setState(() {
                              _editingName = false;
                              _nameCtrl.text = _auth.currentUserName;
                            }),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _auth.currentUserName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _editingName = true),
                          ),
                        ],
                      ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistiques
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mes statistiques', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: _service.getMyIdeas(_auth.currentUserId),
                      builder: (context, snap) {
                        final ideas = snap.data ?? [];
                        final totalLikes = ideas.fold<int>(0, (acc, i) => acc + i.likesCount);
                        return Row(
                          children: [
                            Expanded(child: _StatItem(label: 'Idées soumises', value: '${ideas.length}', icon: Icons.lightbulb_outline, color: AppColors.primary)),
                            Expanded(child: _StatItem(label: 'Likes reçus', value: '$totalLikes', icon: Icons.favorite_outline, color: AppColors.liked)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Déconnexion
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Se déconnecter', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: _confirmSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
