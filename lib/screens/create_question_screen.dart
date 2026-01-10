import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/matiere.dart';

class CreateQuestionScreen extends StatefulWidget {
  final List<Matiere> matieres;

  const CreateQuestionScreen({super.key, required this.matieres});

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  Matiere? _selectedMatiere;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMatiere == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une matière')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _apiService.createQuestion(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        idMatiere: _selectedMatiere!.idMatiere,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question créée !')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Erreur')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle question'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélection de la matière
            DropdownButtonFormField<Matiere>(
              value: _selectedMatiere,
              decoration: const InputDecoration(
                labelText: 'Matière',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: widget.matieres
                  .map((matiere) => DropdownMenuItem(
                        value: matiere,
                        child: Text(matiere.nomMatiere),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedMatiere = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une matière';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Titre
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre de la question',
                hintText: 'Ex: Comment résoudre une équation du second degré ?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                if (value.trim().length < 10) {
                  return 'Le titre doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description détaillée',
                hintText: 'Décrivez votre question en détail...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 2000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez décrire votre question';
                }
                if (value.trim().length < 20) {
                  return 'La description doit contenir au moins 20 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Conseils
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Conseils pour une bonne question',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Soyez précis et clair dans votre titre\n'
                      '• Donnez le contexte de votre problème\n'
                      '• Expliquez ce que vous avez déjà essayé\n'
                      '• Incluez les détails pertinents',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
