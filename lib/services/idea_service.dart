import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/idea.dart';
import '../models/comment.dart';

class IdeaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _ideas => _db.collection('ideas');
  CollectionReference get _likes => _db.collection('likes');

  Stream<List<Idea>> getIdeas() {
    return _ideas
        .orderBy('likesCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Idea.fromFirestore(d)).toList());
  }

  Future<void> submitIdea({
    required String title,
    required String description,
    required String category,
    required bool isAnonymous,
    required String authorId,
    required String authorName,
  }) async {
    await _ideas.add({
      'title': title,
      'description': description,
      'category': category,
      'statut': 'Nouvelle',
      'isAnonymous': isAnonymous,
      'realAuthorId': authorId,
      'realAuthorName': authorName,
      'displayAuthor': isAnonymous ? 'Anonyme' : authorName,
      'likesCount': 0,
      'prioriteAdmin': '',
      'notesAdmin': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasLiked(String ideaId, String userId) async {
    final snap = await _likes
        .where('ideaId', isEqualTo: ideaId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> toggleLike(String ideaId, String userId) async {
    final snap = await _likes
        .where('ideaId', isEqualTo: ideaId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final ideaRef = _ideas.doc(ideaId);

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
      await ideaRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await _likes.add({
        'ideaId': ideaId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ideaRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  Future<void> updateAdminFields(String ideaId, {
    String? statut,
    String? prioriteAdmin,
    String? notesAdmin,
  }) async {
    final Map<String, dynamic> updates = {};
    if (statut != null) updates['statut'] = statut;
    if (prioriteAdmin != null) updates['prioriteAdmin'] = prioriteAdmin;
    if (notesAdmin != null) updates['notesAdmin'] = notesAdmin;
    if (updates.isNotEmpty) {
      await _ideas.doc(ideaId).update(updates);
    }
  }

  Stream<List<Idea>> getIdeasByDate() {
    return _ideas
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Idea.fromFirestore(d)).toList());
  }

  Stream<List<Idea>> getMyIdeas(String userId) {
    return _ideas
        .where('realAuthorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Idea.fromFirestore(d)).toList());
  }

  Future<int> getTotalIdeas() async {
    final snap = await _ideas.count().get();
    return snap.count ?? 0;
  }

  Future<int> getIdeasThisMonth() async {
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final snap = await _ideas
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .count()
        .get();
    return snap.count ?? 0;
  }

  // Commentaires
  CollectionReference get _comments => _db.collection('comments');

  Stream<List<Comment>> getComments(String ideaId) {
    return _comments
        .where('ideaId', isEqualTo: ideaId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  Future<void> addComment({
    required String ideaId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    await _comments.add({
      'ideaId': ideaId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _comments.doc(commentId).delete();
  }
}
