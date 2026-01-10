// Service API - Connexion au backend PHP
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/matiere.dart';
import '../models/question.dart';
import '../models/reponse.dart';

class ApiService {
  // URL de l'API - localhost pour Chrome, 10.0.2.2 pour émulateur Android
  static const String baseUrl = 'http://localhost/forum-api/api.php/api';

  String? _token;

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _token != null;

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'mot_de_passe': motDePasse,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return {
        'success': true,
        'user': User.fromJson(data['user']),
        'message': data['message'],
      };
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Erreur de connexion',
      };
    }
  }

  // INSCRIPTION
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String typeUser,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': motDePasse,
        'type_user': typeUser,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      return {
        'success': true,
        'user': User.fromJson(data['user']),
        'message': data['message'],
      };
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Erreur d\'inscription',
      };
    }
  }

  // MATIERES
  Future<List<Matiere>> getMatieres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/matieres'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> matieresJson = data['matieres'] ?? [];
      return matieresJson.map((json) => Matiere.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createMatiere({
    required String nomMatiere,
    String? codeMatiere,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matieres'),
      headers: _headers,
      body: jsonEncode({
        'nom_matiere': nomMatiere,
        if (codeMatiere != null) 'code_matiere': codeMatiere,
        if (description != null) 'description': description,
      }),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201,
      'id_matiere': data['id_matiere'],
      'error': data['error'],
    };
  }

  // QUESTIONS
  Future<List<Question>> getQuestions({
    int? idMatiere,
    int? idAuteur,
    bool? resolue,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (idMatiere != null) 'id_matiere': idMatiere.toString(),
      if (idAuteur != null) 'id_auteur': idAuteur.toString(),
      if (resolue != null) 'resolue': resolue ? '1' : '0',
    };

    final uri = Uri.parse('$baseUrl/questions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> questionsJson = data['questions'] ?? [];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    }
    return [];
  }

  Future<Question?> getQuestion(int idQuestion) async {
    final response = await http.get(
      Uri.parse('$baseUrl/questions/$idQuestion'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Question.fromJson(data);
    }
    return null;
  }

  Future<Map<String, dynamic>> createQuestion({
    required String titre,
    required String description,
    required int idMatiere,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/questions'),
      headers: _headers,
      body: jsonEncode({
        'titre': titre,
        'description': description,
        'id_matiere': idMatiere,
      }),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201,
      'id_question': data['id_question'],
      'error': data['error'],
    };
  }

  Future<bool> updateQuestion(int idQuestion, {String? titre, String? description, bool? estResolue}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/questions/$idQuestion'),
      headers: _headers,
      body: jsonEncode({
        if (titre != null) 'titre': titre,
        if (description != null) 'description': description,
        if (estResolue != null) 'est_resolue': estResolue,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteQuestion(int idQuestion) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/questions/$idQuestion'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  // REPONSES
  Future<List<Reponse>> getReponses(int idQuestion) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reponses?id_question=$idQuestion'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> reponsesJson = data['reponses'] ?? [];
      return reponsesJson.map((json) => Reponse.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createReponse({
    required String contenu,
    required int idQuestion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reponses'),
      headers: _headers,
      body: jsonEncode({
        'contenu': contenu,
        'id_question': idQuestion,
      }),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201,
      'id_reponse': data['id_reponse'],
      'error': data['error'],
    };
  }

  Future<bool> validerReponse(int idReponse, bool estValidee) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reponses/$idReponse'),
      headers: _headers,
      body: jsonEncode({'est_validee': estValidee}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteReponse(int idReponse) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reponses/$idReponse'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  // REACTIONS
  Future<bool> addReaction({
    required int idReponse,
    required int idTypeReaction,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reactions'),
      headers: _headers,
      body: jsonEncode({
        'id_reponse': idReponse,
        'id_type_reaction': idTypeReaction,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> removeReaction(int idReponse) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reactions?id_reponse=$idReponse'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }
}
