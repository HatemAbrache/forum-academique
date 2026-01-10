import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import '../models/reponse.dart';

class QuestionDetailScreen extends StatefulWidget {
  final int questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final ApiService _apiService = ApiService();
  final _reponseController = TextEditingController();
  Question? _question;
  List<Reponse> _reponses = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reponseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final question = await _apiService.getQuestion(widget.questionId);
      final reponses = await _apiService.getReponses(widget.questionId);
      setState(() {
        _question = question;
        _reponses = reponses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _sendReponse() async {
    if (_reponseController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final result = await _apiService.createReponse(
        contenu: _reponseController.text.trim(),
        idQuestion: widget.questionId,
      );

      if (result['success']) {
        _reponseController.clear();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Réponse envoyée !')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Erreur')),
          );
        }
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _validerReponse(Reponse reponse) async {
    final success = await _apiService.validerReponse(reponse.idReponse, !reponse.estValidee);
    if (success) {
      await _loadData();

      // Marquer la question comme résolue si une réponse est validée
      if (!reponse.estValidee && _question != null) {
        await _apiService.updateQuestion(_question!.idQuestion, estResolue: true);
        await _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Question non trouvée')),
      );
    }

    // Seuls les enseignants peuvent valider les réponses
    final canValidate = user?.estEnseignant == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (user?.idUtilisateur == _question!.idAuteur)
            PopupMenuButton(
              itemBuilder: (context) => [
                if (!_question!.estResolue)
                  PopupMenuItem(
                    onTap: () async {
                      await _apiService.updateQuestion(
                        _question!.idQuestion,
                        estResolue: true,
                      );
                      _loadData();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marquer résolue'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer ?'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer cette question ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _apiService.deleteQuestion(_question!.idQuestion);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Question
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _question!.nomMatiere ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_question!.estResolue)
                          Chip(
                            avatar: const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            label: const Text('Résolue'),
                            backgroundColor: Colors.green[50],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      _question!.titre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Auteur
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _question!.typeAuteur == 'enseignant'
                              ? Colors.orange[100]
                              : Colors.blue[100],
                          child: Icon(
                            _question!.typeAuteur == 'enseignant'
                                ? Icons.school
                                : Icons.person,
                            size: 18,
                            color: _question!.typeAuteur == 'enseignant'
                                ? Colors.orange[800]
                                : Colors.blue[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _question!.auteurComplet,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _question!.typeAuteur == 'enseignant'
                                  ? 'Enseignant'
                                  : 'Étudiant',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _question!.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_question!.nombreVues} vues',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 16),
                        Icon(Icons.comment, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_reponses.length} réponses',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),

                    const Divider(height: 32),

                    // Réponses
                    Text(
                      'Réponses (${_reponses.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_reponses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Aucune réponse pour le moment',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._reponses.map((reponse) => _ReponseCard(
                            reponse: reponse,
                            canValidate: canValidate,
                            onValidate: () => _validerReponse(reponse),
                            currentUserId: user?.idUtilisateur,
                            onDelete: () async {
                              await _apiService.deleteReponse(reponse.idReponse);
                              _loadData();
                            },
                            onReactionChanged: _loadData,
                          )),
                  ],
                ),
              ),
            ),
          ),

          // Zone de réponse
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reponseController,
                      decoration: const InputDecoration(
                        hintText: 'Écrire une réponse...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendReponse,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReponseCard extends StatefulWidget {
  final Reponse reponse;
  final bool canValidate;
  final VoidCallback onValidate;
  final int? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onReactionChanged;

  const _ReponseCard({
    required this.reponse,
    required this.canValidate,
    required this.onValidate,
    required this.currentUserId,
    required this.onDelete,
    required this.onReactionChanged,
  });

  @override
  State<_ReponseCard> createState() => _ReponseCardState();
}

class _ReponseCardState extends State<_ReponseCard> {
  final ApiService _apiService = ApiService();

  Future<void> _react(int typeReactionId) async {
    await _apiService.addReaction(
      idReponse: widget.reponse.idReponse,
      idTypeReaction: typeReactionId,
    );
    widget.onReactionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: widget.reponse.estValidee ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: widget.reponse.auteurEstEnseignant
                      ? Colors.orange[100]
                      : Colors.blue[100],
                  child: Icon(
                    widget.reponse.auteurEstEnseignant ? Icons.school : Icons.person,
                    size: 18,
                    color: widget.reponse.auteurEstEnseignant
                        ? Colors.orange[800]
                        : Colors.blue[800],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reponse.auteurComplet,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.reponse.auteurEstEnseignant ? 'Enseignant' : 'Étudiant',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (widget.reponse.estValidee)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Validée',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenu
            Text(
              widget.reponse.contenu,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Réactions
            Row(
              children: [
                _ReactionButton(
                  emoji: '👍',
                  label: 'J\'aime',
                  onTap: () => _react(1),
                ),
                const SizedBox(width: 8),
                _ReactionButton(
                  emoji: '❤️',
                  label: 'Adore',
                  onTap: () => _react(2),
                ),
                const SizedBox(width: 8),
                _ReactionButton(
                  emoji: '✨',
                  label: 'Utile',
                  onTap: () => _react(3),
                ),
                const SizedBox(width: 8),
                _ReactionButton(
                  emoji: '💡',
                  label: 'Pertinent',
                  onTap: () => _react(4),
                ),
                const Spacer(),
                if (widget.reponse.nombreReactions > 0)
                  Text(
                    '${widget.reponse.nombreReactions} réaction(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Actions (Valider / Supprimer)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.canValidate)
                  TextButton.icon(
                    onPressed: widget.onValidate,
                    icon: Icon(
                      widget.reponse.estValidee
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(widget.reponse.estValidee ? 'Invalider' : 'Valider'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          widget.reponse.estValidee ? Colors.grey : Colors.green,
                    ),
                  ),
                if (widget.currentUserId == widget.reponse.idAuteur)
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
