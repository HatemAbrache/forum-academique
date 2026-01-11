# Forum Academique

```
    ___                                  _                _                _
   / __\___  _ __ _   _ _ __ ___        / \   ___ __ _  __| | ___ _ __ ___ (_) __ _ _   _  ___
  / _\/ _ \| '__| | | | '_ ` _ \      / _ \ / __/ _` |/ _` |/ _ \ '_ ` _ \| |/ _` | | | |/ _ \
 / / | (_) | |  | |_| | | | | | |    / ___ \ (_| (_| | (_| |  __/ | | | | | | (_| | |_| |  __/
 \/   \___/|_|   \__,_|_| |_| |_|   /_/   \_\___\__,_|\__,_|\___|_| |_| |_|_|\__, |\__,_|\___|
                                                                                |_|
```

> Une plateforme collaborative pour etudiants et enseignants - Posez des questions, partagez des reponses, validez les meilleures solutions.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)

---

## Apercu

Forum Academique est une application full-stack permettant aux etudiants de poser des questions sur differentes matieres et aux enseignants de valider les meilleures reponses. Le systeme inclut des reactions animees, un fil de discussion en temps reel et une gestion des roles utilisateurs.

### Fonctionnalites

| Fonctionnalite | Description |
|----------------|-------------|
| Authentification JWT | Connexion securisee avec tokens |
| Questions/Reponses | Systeme complet de Q&A par matiere |
| Reactions animees | Like, Coeur, Etoile, Ampoule avec animations |
| Validation enseignant | Les profs peuvent valider les bonnes reponses |
| Live refresh | Actualisation automatique toutes les 5 secondes |
| Multi-plateforme | Web, Android, iOS |

---

## Architecture

```
forum_app/
│
├── lib/                          # Application Flutter
│   ├── main.dart                 # Point d'entree
│   ├── models/                   # Modeles de donnees
│   │   ├── user.dart
│   │   ├── question.dart
│   │   ├── reponse.dart
│   │   └── matiere.dart
│   ├── providers/                # State management
│   │   └── auth_provider.dart
│   ├── screens/                  # Ecrans UI
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── question_detail_screen.dart
│   │   └── create_question_screen.dart
│   └── services/                 # Couche API
│       └── api_service.dart
│
├── backend/                      # API REST PHP
│   └── api.php                   # Endpoints API
│
├── database/                     # Base de donnees
│   └── forum_db.sql              # Dump MySQL
│
└── README.md
```

---

## Installation

### Pre-requis

- Flutter SDK >= 3.5.4
- PHP >= 7.4
- MySQL >= 8.0
- XAMPP / MAMP / Homebrew MySQL

### 1. Base de donnees

```bash
# Creer la base de donnees
mysql -u root -e "CREATE DATABASE forum_db;"

# Importer le schema
mysql -u root forum_db < database/forum_db.sql
```

### 2. Backend API

```bash
# Copier l'API dans votre serveur web
cp backend/api.php /chemin/vers/htdocs/forum-api/

# Configurer la connexion MySQL dans api.php (lignes 20-23)
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'forum_db');
define('DB_USER', 'root');
define('DB_PASS', '');
```

### 3. Application Flutter

```bash
# Installer les dependances
flutter pub get

# Lancer sur Chrome (dev)
flutter run -d chrome

# Build pour production
flutter build web
```

---

## API Endpoints

| Methode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| POST | `/api/login` | Connexion utilisateur | Non |
| POST | `/api/register` | Inscription | Non |
| GET | `/api/questions` | Liste des questions | Oui |
| POST | `/api/questions` | Creer une question | Oui |
| GET | `/api/reponses?id_question=X` | Reponses d'une question | Oui |
| POST | `/api/reponses` | Ajouter une reponse | Oui |
| POST | `/api/reactions` | Ajouter une reaction | Oui |
| PUT | `/api/reponses/:id` | Valider une reponse | Oui (enseignant) |

---

## Comptes de Test

### Enseignants

| Nom | Email | Mot de passe |
|-----|-------|--------------|
| Youssef Benani | `youssef.benani@edu.ma` | `password123` |
| Nadia El Fassi | `nadia.elfassi@edu.ma` | `password123` |
| Karim Alaoui | `karim.alaoui@edu.ma` | `password123` |
| Fatima Chraibi | `fatima.chraibi@edu.ma` | `password123` |

### Etudiants

| Nom | Email | Mot de passe |
|-----|-------|--------------|
| Omar Tazi | `omar.tazi@student.ma` | `password123` |
| Sara Benjelloun | `sara.benjelloun@student.ma` | `password123` |
| Amine Idrissi | `amine.idrissi@student.ma` | `password123` |
| Hajar Berrada | `hajar.berrada@student.ma` | `password123` |
| Mehdi Sqalli | `mehdi.sqalli@student.ma` | `password123` |
| Salma El Amrani | `salma.elamrani@student.ma` | `password123` |

> **Note:** Le mot de passe par defaut est `password123` pour tous les comptes de test.

---

## Screenshots

### Ecran de connexion
- Authentification avec email/mot de passe
- Lien vers l'inscription

### Page d'accueil
- Liste des questions filtrable par matiere
- Chips de filtre avec indicateur de selection
- Bouton flottant pour nouvelle question

### Detail d'une question
- Affichage complet de la question
- Liste des reponses avec reactions animees
- Zone de saisie pour repondre
- Badge "Resolue" si applicable

---

## Stack Technique

```
Frontend:     Flutter 3.5+ (Dart)
State:        Provider
Backend:      PHP 7.4+ (REST API)
Auth:         JWT (JSON Web Tokens)
Database:     MySQL 8.0
Animations:   Flutter AnimationController
```

---

## Fonctionnement des Reactions

Les reactions utilisent des animations personnalisees :

1. **Scale Animation** - Effet de rebond (1.0 -> 1.4 -> 0.9 -> 1.0)
2. **Color Animation** - Transition de gris vers la couleur finale
3. **Glow Effect** - Ombre coloree autour du bouton

| Reaction | Icone | Couleur |
|----------|-------|---------|
| J'aime | `thumb_up` | Bleu |
| Adore | `favorite` | Rouge |
| Utile | `star` | Jaune |
| Pertinent | `lightbulb` | Orange |

---

## Roles et Permissions

| Action | Etudiant | Enseignant |
|--------|----------|------------|
| Poser une question | Oui | Oui |
| Repondre | Oui | Oui |
| Reagir | Oui | Oui |
| Valider une reponse | Non | Oui |
| Creer une matiere | Non | Oui |
| Supprimer sa question | Oui | Oui |

---

## Contribuer

```bash
# Fork le projet
git clone https://github.com/votre-username/forum_app.git

# Creer une branche
git checkout -b feature/ma-fonctionnalite

# Commit
git commit -m "feat: ajout de ma fonctionnalite"

# Push
git push origin feature/ma-fonctionnalite
```

---

## Licence

Ce projet est realise dans le cadre du **Master EDTECH**.

---

<p align="center">
  <b>Built with mass of mass</b>
</p>
