// Modèle Réponse
class Reponse {
  final int idReponse;
  final String contenu;
  final int idQuestion;
  final int idAuteur;
  final DateTime? dateReponse;
  final bool estValidee;
  final int? valideePar;
  final DateTime? dateValidation;
  final String? nomAuteur;
  final String? prenomAuteur;
  final String? typeAuteur;
  final String? nomValidateur;
  final String? prenomValidateur;
  final int nombreReactions;
  // Détail des réactions par type
  final int nombreLikes;
  final int nombreHearts;
  final int nombreStars;
  final int nombreBulbs;
  // Réaction de l'utilisateur actuel
  final int? userReactionType;

  Reponse({
    required this.idReponse,
    required this.contenu,
    required this.idQuestion,
    required this.idAuteur,
    this.dateReponse,
    this.estValidee = false,
    this.valideePar,
    this.dateValidation,
    this.nomAuteur,
    this.prenomAuteur,
    this.typeAuteur,
    this.nomValidateur,
    this.prenomValidateur,
    this.nombreReactions = 0,
    this.nombreLikes = 0,
    this.nombreHearts = 0,
    this.nombreStars = 0,
    this.nombreBulbs = 0,
    this.userReactionType,
  });

  factory Reponse.fromJson(Map<String, dynamic> json) {
    return Reponse(
      idReponse: json['id_reponse'] ?? 0,
      contenu: json['contenu'] ?? '',
      idQuestion: json['id_question'] ?? 0,
      idAuteur: json['id_auteur'] ?? 0,
      dateReponse: json['date_reponse'] != null
          ? DateTime.tryParse(json['date_reponse'])
          : null,
      estValidee: json['est_validee'] == 1 || json['est_validee'] == true,
      valideePar: json['validee_par'],
      dateValidation: json['date_validation'] != null
          ? DateTime.tryParse(json['date_validation'])
          : null,
      nomAuteur: json['nom_auteur'],
      prenomAuteur: json['prenom_auteur'],
      typeAuteur: json['type_auteur'],
      nomValidateur: json['nom_validateur'],
      prenomValidateur: json['prenom_validateur'],
      nombreReactions: int.tryParse(json['nombre_reactions']?.toString() ?? '0') ?? 0,
      nombreLikes: int.tryParse(json['nombre_likes']?.toString() ?? '0') ?? 0,
      nombreHearts: int.tryParse(json['nombre_hearts']?.toString() ?? '0') ?? 0,
      nombreStars: int.tryParse(json['nombre_stars']?.toString() ?? '0') ?? 0,
      nombreBulbs: int.tryParse(json['nombre_bulbs']?.toString() ?? '0') ?? 0,
      userReactionType: json['user_reaction_type'],
    );
  }

  String get auteurComplet => '$prenomAuteur $nomAuteur';
  bool get auteurEstEnseignant => typeAuteur == 'enseignant';
}
