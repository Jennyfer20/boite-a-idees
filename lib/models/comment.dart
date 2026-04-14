import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String ideaId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      ideaId: data['ideaId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Utilisateur',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
