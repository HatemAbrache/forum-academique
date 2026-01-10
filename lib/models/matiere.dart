// Modèle Matière
class Matiere {
  final int idMatiere;
  final String nomMatiere;
  final String? codeMatiere;
  final String? description;
  final int? idEnseignant;
  final String? nomEnseignant;
  final String? prenomEnseignant;

  Matiere({
    required this.idMatiere,
    required this.nomMatiere,
    this.codeMatiere,
    this.description,
    this.idEnseignant,
    this.nomEnseignant,
    this.prenomEnseignant,
  });

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      idMatiere: json['id_matiere'] ?? 0,
      nomMatiere: json['nom_matiere'] ?? '',
      codeMatiere: json['code_matiere'],
      description: json['description'],
      idEnseignant: json['id_enseignant'],
      nomEnseignant: json['nom_enseignant'],
      prenomEnseignant: json['prenom_enseignant'],
    );
  }

  String get enseignantComplet =>
      nomEnseignant != null ? '$prenomEnseignant $nomEnseignant' : 'Non assigné';
}
