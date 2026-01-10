// Modèle Utilisateur
class User {
  final int idUtilisateur;
  final String nom;
  final String prenom;
  final String email;
  final String typeUser;
  final DateTime? dateCreation;
  final bool estActif;

  User({
    required this.idUtilisateur,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.typeUser,
    this.dateCreation,
    this.estActif = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUtilisateur: json['id_utilisateur'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      typeUser: json['type_user'] ?? 'etudiant',
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'])
          : null,
      estActif: json['est_actif'] == 1 || json['est_actif'] == true,
    );
  }

  String get nomComplet => '$prenom $nom';
  bool get estEnseignant => typeUser == 'enseignant';
}
