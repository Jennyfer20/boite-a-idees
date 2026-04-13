import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/idea_service.dart';
import '../theme/app_theme.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _auth = AuthService();
  final _service = IdeaService();

  bool _isAnonymous = false;
  bool _loading = false;

  final _categories = ['IT', 'RH', 'Organisation', 'Innovation', 'Autre'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.submitIdea(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        isAnonymous: _isAnonymous,
        authorId: _auth.currentUserId,
        authorName: _auth.currentUserName,
      );
      if (mounted) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _categoryCtrl.clear();
        setState(() => _isAnonymous = false);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            SizedBox(height: 16),
            Text('Idée envoyée !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Merci pour votre contribution', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Super !', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposer une idée')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Titre *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleCtrl,
                        maxLength: 255,
                        decoration: const InputDecoration(hintText: 'Un titre accrocheur...'),
                        validator: (v) => v!.isEmpty ? 'Le titre est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Description *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(hintText: 'Décrivez votre idée, son intérêt, comment la mettre en œuvre...'),
                        validator: (v) => v!.isEmpty ? 'La description est requise' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _categories.map((cat) => ChoiceChip(
                          label: Text(cat),
                          selected: _categoryCtrl.text == cat,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _categoryCtrl.text = cat),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soumettre anonymement', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Votre nom ne sera pas affiché publiquement', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isAnonymous = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isAnonymous)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Votre identité restera confidentielle pour les autres utilisateurs', style: TextStyle(fontSize: 12, color: AppColors.primary))),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: const Text('Envoyer l\'idée'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
