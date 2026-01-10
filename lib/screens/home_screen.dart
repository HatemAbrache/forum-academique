import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import '../models/matiere.dart';
import 'login_screen.dart';
import 'question_detail_screen.dart';
import 'create_question_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Question> _questions = [];
  List<Matiere> _matieres = [];
  bool _isLoading = true;
  Matiere? _selectedMatiere;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Rafraîchissement automatique toutes les 5 secondes (LIVE)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDataSilent();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Chargement silencieux (sans indicateur de chargement)
  Future<void> _loadDataSilent() async {
    try {
      final questions = await _apiService.getQuestions(
        idMatiere: _selectedMatiere?.idMatiere,
      );
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      // Ignorer les erreurs silencieuses
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final matieres = await _apiService.getMatieres();
      final questions = await _apiService.getQuestions(
        idMatiere: _selectedMatiere?.idMatiere,
      );
      setState(() {
        _matieres = matieres;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Académique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nomComplet ?? 'Utilisateur',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      user?.estEnseignant == true ? 'Enseignant' : 'Étudiant',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                onTap: _logout,
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre par matière
          if (_matieres.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: FilterChip(
                      label: const Text('Toutes'),
                      selected: _selectedMatiere == null,
                      onSelected: (selected) {
                        setState(() => _selectedMatiere = null);
                        _loadData();
                      },
                    ),
                  ),
                  ..._matieres.map((matiere) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: FilterChip(
                          label: Text(matiere.nomMatiere),
                          selected: _selectedMatiere?.idMatiere == matiere.idMatiere,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMatiere = selected ? matiere : null;
                            });
                            _loadData();
                          },
                        ),
                      )),
                ],
              ),
            ),

          // Liste des questions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.question_answer_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune question',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Soyez le premier à poser une question !',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return _QuestionCard(
                              question: question,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuestionDetailScreen(
                                      questionId: question.idQuestion,
                                    ),
                                  ),
                                );
                                _loadData();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuestionScreen(matieres: _matieres),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Question'),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec matière et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      question.nomMatiere ?? 'Matière',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (question.estResolue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Résolue',
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

              // Titre
              Text(
                question.titre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description (aperçu)
              Text(
                question.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Métadonnées
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    question.auteurComplet,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${question.nombreReponses}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${question.nombreVues}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
