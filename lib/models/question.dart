// Modèle Question
class Question {
  final int idQuestion;
  final String titre;
  final String description;
  final int idMatiere;
  final int idAuteur;
  final DateTime? datePublication;
  final bool estResolue;
  final int nombreVues;
  final String? nomAuteur;
  final String? prenomAuteur;
  final String? typeAuteur;
  final String? nomMatiere;
  final int nombreReponses;

  Question({
    required this.idQuestion,
    required this.titre,
    required this.description,
    required this.idMatiere,
    required this.idAuteur,
    this.datePublication,
    this.estResolue = false,
    this.nombreVues = 0,
    this.nomAuteur,
    this.prenomAuteur,
    this.typeAuteur,
    this.nomMatiere,
    this.nombreReponses = 0,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      idQuestion: json['id_question'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      idMatiere: json['id_matiere'] ?? 0,
      idAuteur: json['id_auteur'] ?? 0,
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'])
          : null,
      estResolue: json['est_resolue'] == 1 || json['est_resolue'] == true,
      nombreVues: json['nombre_vues'] ?? 0,
      nomAuteur: json['nom_auteur'],
      prenomAuteur: json['prenom_auteur'],
      typeAuteur: json['type_auteur'],
      nomMatiere: json['nom_matiere'],
      nombreReponses: int.tryParse(json['nombre_reponses']?.toString() ?? '0') ?? 0,
    );
  }

  String get auteurComplet => '$prenomAuteur $nomAuteur';
}
