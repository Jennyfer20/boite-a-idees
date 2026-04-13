import 'package:cloud_firestore/cloud_firestore.dart';

class Idea {
  final String id;
  final String title;
  final String description;
  final String category;
  final String statut;
  final bool isAnonymous;
  final String realAuthorId;
  final String realAuthorName;
  final String displayAuthor;
  final int likesCount;
  final String prioriteAdmin;
  final String notesAdmin;
  final DateTime createdAt;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    this.category = '',
    this.statut = 'Nouvelle',
    this.isAnonymous = false,
    required this.realAuthorId,
    required this.realAuthorName,
    required this.displayAuthor,
    this.likesCount = 0,
    this.prioriteAdmin = '',
    this.notesAdmin = '',
    required this.createdAt,
  });

  factory Idea.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Idea(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      statut: data['statut'] ?? 'Nouvelle',
      isAnonymous: data['isAnonymous'] ?? false,
      realAuthorId: data['realAuthorId'] ?? '',
      realAuthorName: data['realAuthorName'] ?? '',
      displayAuthor: data['displayAuthor'] ?? 'Anonyme',
      likesCount: data['likesCount'] ?? 0,
      prioriteAdmin: data['prioriteAdmin'] ?? '',
      notesAdmin: data['notesAdmin'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'statut': statut,
        'isAnonymous': isAnonymous,
        'realAuthorId': realAuthorId,
        'realAuthorName': realAuthorName,
        'displayAuthor': displayAuthor,
        'likesCount': likesCount,
        'prioriteAdmin': prioriteAdmin,
        'notesAdmin': notesAdmin,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
