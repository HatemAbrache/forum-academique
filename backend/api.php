<?php
/**
 * API REST pour Forum Académique
 * Adapté aux entités métiers : utilisateurs, questions, réponses, matières, réactions
 * Inclut l'authentification JWT
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gérer les requêtes OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration de la base de données
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'forum_db');
define('DB_USER', 'root');
define('DB_PASS', '');
define('JWT_SECRET', 'ForumAcademique2026SecretKey_xyz789_MonProjet');// IMPORTANT : Changer en production !

// Connexion à la base de données
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch (PDOException $e) {
    respond(['error' => 'Erreur de connexion à la base de données'], 500);
}

// Récupérer la méthode HTTP et l'endpoint
$method = $_SERVER['REQUEST_METHOD'];
$request = $_SERVER['REQUEST_URI'];
$path = parse_url($request, PHP_URL_PATH);
$path = trim($path, '/');
$allSegments = explode('/', $path);

// Trouver la position de 'api' pour gérer les URLs comme /forum-api/api.php/api/login
$apiIndex = array_search('api', $allSegments);
if ($apiIndex !== false) {
    $segments = array_slice($allSegments, $apiIndex);
} else {
    $segments = $allSegments;
}
// Réindexer le tableau
$segments = array_values($segments);

// Récupérer le corps de la requête
$input = json_decode(file_get_contents('php://input'), true);

// Router principal
try {
    // Routes publiques (sans authentification)
    if ($method === 'POST' && $segments[0] === 'api' && $segments[1] === 'login') {
        login($pdo, $input);
    } elseif ($method === 'POST' && $segments[0] === 'api' && $segments[1] === 'register') {
        register($pdo, $input);
    }
    // Routes protégées (avec authentification)
    else {
        $user = authenticate($pdo);
        
        switch ($segments[1] ?? '') {
            // UTILISATEURS
            case 'users':
                handleUsers($pdo, $method, $segments, $input, $user);
                break;
            
            // MATIÈRES
            case 'matieres':
                handleMatieres($pdo, $method, $segments, $input, $user);
                break;
            
            // QUESTIONS
            case 'questions':
                handleQuestions($pdo, $method, $segments, $input, $user);
                break;
            
            // RÉPONSES
            case 'reponses':
                handleReponses($pdo, $method, $segments, $input, $user);
                break;
            
            // RÉACTIONS
            case 'reactions':
                handleReactions($pdo, $method, $segments, $input, $user);
                break;
            
            default:
                respond(['error' => 'Endpoint non trouvé'], 404);
        }
    }
} catch (Exception $e) {
    respond(['error' => $e->getMessage()], 500);
}

// ============================================
// FONCTIONS D'AUTHENTIFICATION
// ============================================

/**
 * Connexion utilisateur
 */
function login($pdo, $input) {
    if (!isset($input['email']) || !isset($input['mot_de_passe'])) {
        respond(['error' => 'Email et mot de passe requis'], 400);
    }
    
    $stmt = $pdo->prepare("SELECT * FROM utilisateur WHERE email = ? AND est_actif = 1");
    $stmt->execute([$input['email']]);
    $user = $stmt->fetch();
    
    if (!$user || !password_verify($input['mot_de_passe'], $user['mot_de_passe'])) {
        respond(['error' => 'Identifiants invalides'], 401);
    }
    
    // Mettre à jour la dernière connexion
    $stmt = $pdo->prepare("UPDATE utilisateur SET derniere_connexion = NOW() WHERE id_utilisateur = ?");
    $stmt->execute([$user['id_utilisateur']]);
    
    // Générer le token JWT
    $token = generateJWT($user);
    
    unset($user['mot_de_passe']);
    respond([
        'message' => 'Connexion réussie',
        'token' => $token,
        'user' => $user
    ]);
}

/**
 * Inscription d'un nouvel utilisateur
 */
function register($pdo, $input) {
    $required = ['nom', 'prenom', 'email', 'mot_de_passe', 'type_user'];
    foreach ($required as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            respond(['error' => "Le champ $field est requis"], 400);
        }
    }
    
    // Valider l'email
    if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
        respond(['error' => 'Email invalide'], 400);
    }
    
    // Valider le type d'utilisateur
    if (!in_array($input['type_user'], ['etudiant', 'enseignant'])) {
        respond(['error' => 'Type d\'utilisateur invalide'], 400);
    }
    
    // Vérifier si l'email existe déjà
    $stmt = $pdo->prepare("SELECT id_utilisateur FROM utilisateur WHERE email = ?");
    $stmt->execute([$input['email']]);
    if ($stmt->fetch()) {
        respond(['error' => 'Cet email est déjà utilisé'], 409);
    }
    
    // Hasher le mot de passe
    $hashedPassword = password_hash($input['mot_de_passe'], PASSWORD_DEFAULT);
    
    // Insérer l'utilisateur
    $stmt = $pdo->prepare("
        INSERT INTO utilisateur (nom, prenom, email, mot_de_passe, type_user) 
        VALUES (?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $input['nom'],
        $input['prenom'],
        $input['email'],
        $hashedPassword,
        $input['type_user']
    ]);
    
    $userId = $pdo->lastInsertId();
    
    // Récupérer l'utilisateur créé
    $stmt = $pdo->prepare("SELECT * FROM utilisateur WHERE id_utilisateur = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    unset($user['mot_de_passe']);
    
    // Générer le token
    $token = generateJWT($user);
    
    respond([
        'message' => 'Inscription réussie',
        'token' => $token,
        'user' => $user
    ], 201);
}

/**
 * Vérifier l'authentification JWT
 */
function authenticate($pdo) {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        respond(['error' => 'Token d\'authentification manquant'], 401);
    }
    
    $token = $matches[1];
    $user = verifyJWT($token);
    
    if (!$user) {
        respond(['error' => 'Token invalide ou expiré'], 401);
    }
    
    // Vérifier que l'utilisateur existe toujours
    $stmt = $pdo->prepare("SELECT * FROM utilisateur WHERE id_utilisateur = ? AND est_actif = 1");
    $stmt->execute([$user['id_utilisateur']]);
    $currentUser = $stmt->fetch();
    
    if (!$currentUser) {
        respond(['error' => 'Utilisateur non trouvé'], 401);
    }
    
    unset($currentUser['mot_de_passe']);
    return $currentUser;
}

/**
 * Générer un token JWT
 */
function generateJWT($user) {
    $header = base64_encode(json_encode(['typ' => 'JWT', 'alg' => 'HS256']));
    $payload = base64_encode(json_encode([
        'id_utilisateur' => $user['id_utilisateur'],
        'email' => $user['email'],
        'type_user' => $user['type_user'],
        'exp' => time() + (7 * 24 * 60 * 60) // 7 jours
    ]));
    
    $signature = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    
    return "$header.$payload.$signature";
}

/**
 * Vérifier un token JWT
 */
function verifyJWT($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    
    list($header, $payload, $signature) = $parts;
    
    $validSignature = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    
    if ($signature !== $validSignature) {
        return false;
    }
    
    $data = json_decode(base64_decode($payload), true);
    
    if (!$data || $data['exp'] < time()) {
        return false;
    }
    
    return $data;
}

// ============================================
// HANDLERS POUR CHAQUE RESSOURCE
// ============================================

/**
 * Gestion des utilisateurs
 */
function handleUsers($pdo, $method, $segments, $input, $user) {
    $userId = $segments[2] ?? null;
    
    switch ($method) {
        case 'GET':
            if ($userId) {
                // Récupérer un utilisateur spécifique
                $stmt = $pdo->prepare("SELECT id_utilisateur, nom, prenom, email, type_user, date_creation FROM utilisateur WHERE id_utilisateur = ?");
                $stmt->execute([$userId]);
                $targetUser = $stmt->fetch();
                
                if (!$targetUser) {
                    respond(['error' => 'Utilisateur non trouvé'], 404);
                }
                
                respond($targetUser);
            } else {
                // Lister tous les utilisateurs (avec pagination)
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 20;
                $offset = ($page - 1) * $limit;
                
                $stmt = $pdo->prepare("
                    SELECT id_utilisateur, nom, prenom, email, type_user, date_creation 
                    FROM utilisateur 
                    WHERE est_actif = 1
                    ORDER BY nom, prenom
                    LIMIT ? OFFSET ?
                ");
                $stmt->execute([$limit, $offset]);
                $users = $stmt->fetchAll();
                
                respond(['users' => $users, 'page' => $page]);
            }
            break;
        
        case 'PUT':
            if (!$userId) {
                respond(['error' => 'ID utilisateur requis'], 400);
            }
            
            // Seul l'utilisateur lui-même peut se modifier
            if ($user['id_utilisateur'] != $userId) {
                respond(['error' => 'Non autorisé'], 403);
            }
            
            $fields = [];
            $values = [];
            
            if (isset($input['nom'])) {
                $fields[] = 'nom = ?';
                $values[] = $input['nom'];
            }
            if (isset($input['prenom'])) {
                $fields[] = 'prenom = ?';
                $values[] = $input['prenom'];
            }
            if (isset($input['mot_de_passe'])) {
                $fields[] = 'mot_de_passe = ?';
                $values[] = password_hash($input['mot_de_passe'], PASSWORD_DEFAULT);
            }
            
            if (empty($fields)) {
                respond(['error' => 'Aucun champ à mettre à jour'], 400);
            }
            
            $values[] = $userId;
            $sql = "UPDATE utilisateur SET " . implode(', ', $fields) . " WHERE id_utilisateur = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($values);
            
            respond(['message' => 'Utilisateur mis à jour']);
            break;
        
        default:
            respond(['error' => 'Méthode non autorisée'], 405);
    }
}

/**
 * Gestion des matières
 */
function handleMatieres($pdo, $method, $segments, $input, $user) {
    $matiereId = $segments[2] ?? null;
    
    switch ($method) {
        case 'GET':
            if ($matiereId) {
                $stmt = $pdo->prepare("
                    SELECT m.*, u.nom as nom_enseignant, u.prenom as prenom_enseignant
                    FROM matiere m
                    LEFT JOIN utilisateur u ON m.id_enseignant = u.id_utilisateur
                    WHERE m.id_matiere = ?
                ");
                $stmt->execute([$matiereId]);
                $matiere = $stmt->fetch();
                
                if (!$matiere) {
                    respond(['error' => 'Matière non trouvée'], 404);
                }
                
                respond($matiere);
            } else {
                $stmt = $pdo->query("
                    SELECT m.*, u.nom as nom_enseignant, u.prenom as prenom_enseignant
                    FROM matiere m
                    LEFT JOIN utilisateur u ON m.id_enseignant = u.id_utilisateur
                    ORDER BY m.nom_matiere
                ");
                $matieres = $stmt->fetchAll();
                
                respond(['matieres' => $matieres]);
            }
            break;
        
        case 'POST':
            // Seuls les enseignants peuvent créer des matières
            if ($user['type_user'] !== 'enseignant') {
                respond(['error' => 'Seuls les enseignants peuvent créer des matières'], 403);
            }
            
            if (!isset($input['nom_matiere'])) {
                respond(['error' => 'Le nom de la matière est requis'], 400);
            }
            
            $stmt = $pdo->prepare("
                INSERT INTO matiere (nom_matiere, code_matiere, description, id_enseignant) 
                VALUES (?, ?, ?, ?)
            ");
            $stmt->execute([
                $input['nom_matiere'],
                $input['code_matiere'] ?? null,
                $input['description'] ?? null,
                $user['id_utilisateur']
            ]);
            
            $matiereId = $pdo->lastInsertId();
            
            respond(['message' => 'Matière créée', 'id_matiere' => $matiereId], 201);
            break;
        
        default:
            respond(['error' => 'Méthode non autorisée'], 405);
    }
}

/**
 * Gestion des questions
 */
function handleQuestions($pdo, $method, $segments, $input, $user) {
    $questionId = $segments[2] ?? null;
    
    switch ($method) {
        case 'GET':
            if ($questionId) {
                // Incrémenter le nombre de vues
                $stmt = $pdo->prepare("UPDATE question SET nombre_vues = nombre_vues + 1 WHERE id_question = ?");
                $stmt->execute([$questionId]);
                
                // Récupérer la question avec détails
                $stmt = $pdo->prepare("
                    SELECT q.*, 
                           u.nom as nom_auteur, u.prenom as prenom_auteur, u.type_user as type_auteur,
                           m.nom_matiere,
                           COUNT(DISTINCT r.id_reponse) as nombre_reponses
                    FROM question q
                    JOIN utilisateur u ON q.id_auteur = u.id_utilisateur
                    JOIN matiere m ON q.id_matiere = m.id_matiere
                    LEFT JOIN reponse r ON q.id_question = r.id_question
                    WHERE q.id_question = ?
                    GROUP BY q.id_question
                ");
                $stmt->execute([$questionId]);
                $question = $stmt->fetch();
                
                if (!$question) {
                    respond(['error' => 'Question non trouvée'], 404);
                }
                
                respond($question);
            } else {
                // Lister les questions avec filtres
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 20;
                $offset = ($page - 1) * $limit;
                $matiereId = $_GET['id_matiere'] ?? null;
                $auteurId = $_GET['id_auteur'] ?? null;
                $resolue = $_GET['resolue'] ?? null;
                
                $where = [];
                $params = [];
                
                if ($matiereId) {
                    $where[] = 'q.id_matiere = ?';
                    $params[] = $matiereId;
                }
                if ($auteurId) {
                    $where[] = 'q.id_auteur = ?';
                    $params[] = $auteurId;
                }
                if ($resolue !== null) {
                    $where[] = 'q.est_resolue = ?';
                    $params[] = $resolue;
                }
                
                $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';
                
                $stmt = $pdo->prepare("
                    SELECT q.*, 
                           u.nom as nom_auteur, u.prenom as prenom_auteur,
                           m.nom_matiere,
                           COUNT(DISTINCT r.id_reponse) as nombre_reponses
                    FROM question q
                    JOIN utilisateur u ON q.id_auteur = u.id_utilisateur
                    JOIN matiere m ON q.id_matiere = m.id_matiere
                    LEFT JOIN reponse r ON q.id_question = r.id_question
                    $whereClause
                    GROUP BY q.id_question
                    ORDER BY q.date_publication DESC
                    LIMIT ? OFFSET ?
                ");
                $params[] = $limit;
                $params[] = $offset;
                $stmt->execute($params);
                $questions = $stmt->fetchAll();
                
                respond(['questions' => $questions, 'page' => $page]);
            }
            break;
        
        case 'POST':
            $required = ['titre', 'description', 'id_matiere'];
            foreach ($required as $field) {
                if (!isset($input[$field]) || empty($input[$field])) {
                    respond(['error' => "Le champ $field est requis"], 400);
                }
            }
            
            $stmt = $pdo->prepare("
                INSERT INTO question (titre, description, id_matiere, id_auteur) 
                VALUES (?, ?, ?, ?)
            ");
            $stmt->execute([
                $input['titre'],
                $input['description'],
                $input['id_matiere'],
                $user['id_utilisateur']
            ]);
            
            $questionId = $pdo->lastInsertId();
            
            respond(['message' => 'Question créée', 'id_question' => $questionId], 201);
            break;
        
        case 'PUT':
            if (!$questionId) {
                respond(['error' => 'ID question requis'], 400);
            }
            
            // Vérifier que l'utilisateur est l'auteur ou un enseignant
            $stmt = $pdo->prepare("SELECT id_auteur FROM question WHERE id_question = ?");
            $stmt->execute([$questionId]);
            $question = $stmt->fetch();
            
            if (!$question) {
                respond(['error' => 'Question non trouvée'], 404);
            }
            
            if ($question['id_auteur'] != $user['id_utilisateur'] && $user['type_user'] !== 'enseignant') {
                respond(['error' => 'Non autorisé'], 403);
            }
            
            $fields = [];
            $values = [];
            
            if (isset($input['titre'])) {
                $fields[] = 'titre = ?';
                $values[] = $input['titre'];
            }
            if (isset($input['description'])) {
                $fields[] = 'description = ?';
                $values[] = $input['description'];
            }
            if (isset($input['est_resolue'])) {
                $fields[] = 'est_resolue = ?';
                $values[] = $input['est_resolue'];
            }
            
            if (empty($fields)) {
                respond(['error' => 'Aucun champ à mettre à jour'], 400);
            }
            
            $values[] = $questionId;
            $sql = "UPDATE question SET " . implode(', ', $fields) . " WHERE id_question = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($values);
            
            respond(['message' => 'Question mise à jour']);
            break;
        
        case 'DELETE':
            if (!$questionId) {
                respond(['error' => 'ID question requis'], 400);
            }
            
            // Vérifier que l'utilisateur est l'auteur
            $stmt = $pdo->prepare("SELECT id_auteur FROM question WHERE id_question = ?");
            $stmt->execute([$questionId]);
            $question = $stmt->fetch();
            
            if (!$question) {
                respond(['error' => 'Question non trouvée'], 404);
            }
            
            if ($question['id_auteur'] != $user['id_utilisateur']) {
                respond(['error' => 'Non autorisé'], 403);
            }
            
            $stmt = $pdo->prepare("DELETE FROM question WHERE id_question = ?");
            $stmt->execute([$questionId]);
            
            respond(['message' => 'Question supprimée']);
            break;
        
        default:
            respond(['error' => 'Méthode non autorisée'], 405);
    }
}

/**
 * Gestion des réponses
 */
function handleReponses($pdo, $method, $segments, $input, $user) {
    $reponseId = $segments[2] ?? null;
    
    switch ($method) {
        case 'GET':
            // Récupérer les réponses d'une question
            $questionId = $_GET['id_question'] ?? null;

            if (!$questionId) {
                respond(['error' => 'id_question requis'], 400);
            }

            $stmt = $pdo->prepare("
                SELECT r.*,
                       u.nom as nom_auteur, u.prenom as prenom_auteur, u.type_user as type_auteur,
                       v.nom as nom_validateur, v.prenom as prenom_validateur,
                       COUNT(DISTINCT react.id_reaction) as nombre_reactions,
                       SUM(CASE WHEN react.id_type_reaction = 1 THEN 1 ELSE 0 END) as nombre_likes,
                       SUM(CASE WHEN react.id_type_reaction = 2 THEN 1 ELSE 0 END) as nombre_hearts,
                       SUM(CASE WHEN react.id_type_reaction = 3 THEN 1 ELSE 0 END) as nombre_stars,
                       SUM(CASE WHEN react.id_type_reaction = 4 THEN 1 ELSE 0 END) as nombre_bulbs,
                       (SELECT id_type_reaction FROM reaction
                        WHERE id_reponse = r.id_reponse AND id_utilisateur = ?) as user_reaction_type
                FROM reponse r
                JOIN utilisateur u ON r.id_auteur = u.id_utilisateur
                LEFT JOIN utilisateur v ON r.validee_par = v.id_utilisateur
                LEFT JOIN reaction react ON r.id_reponse = react.id_reponse
                WHERE r.id_question = ?
                GROUP BY r.id_reponse
                ORDER BY r.est_validee DESC, r.date_reponse ASC
            ");
            $stmt->execute([$user['id_utilisateur'], $questionId]);
            $reponses = $stmt->fetchAll();

            respond(['reponses' => $reponses]);
            break;
        
        case 'POST':
            $required = ['contenu', 'id_question'];
            foreach ($required as $field) {
                if (!isset($input[$field]) || empty($input[$field])) {
                    respond(['error' => "Le champ $field est requis"], 400);
                }
            }
            
            $stmt = $pdo->prepare("
                INSERT INTO reponse (contenu, id_question, id_auteur) 
                VALUES (?, ?, ?)
            ");
            $stmt->execute([
                $input['contenu'],
                $input['id_question'],
                $user['id_utilisateur']
            ]);
            
            $reponseId = $pdo->lastInsertId();
            
            respond(['message' => 'Réponse créée', 'id_reponse' => $reponseId], 201);
            break;
        
        case 'PUT':
            if (!$reponseId) {
                respond(['error' => 'ID réponse requis'], 400);
            }
            
            // Récupérer la réponse et sa question
            $stmt = $pdo->prepare("
                SELECT r.*, q.id_auteur as auteur_question
                FROM reponse r
                JOIN question q ON r.id_question = q.id_question
                WHERE r.id_reponse = ?
            ");
            $stmt->execute([$reponseId]);
            $reponse = $stmt->fetch();
            
            if (!$reponse) {
                respond(['error' => 'Réponse non trouvée'], 404);
            }
            
            // Validation de la réponse (enseignant ou auteur de la question)
            if (isset($input['est_validee'])) {
                $canValidate = $user['type_user'] === 'enseignant' || 
                               $user['id_utilisateur'] == $reponse['auteur_question'];
                
                if (!$canValidate) {
                    respond(['error' => 'Seuls l\'auteur de la question ou un enseignant peuvent valider'], 403);
                }
                
                $stmt = $pdo->prepare("
                    UPDATE reponse 
                    SET est_validee = ?, validee_par = ?, date_validation = NOW() 
                    WHERE id_reponse = ?
                ");
                $stmt->execute([
                    $input['est_validee'],
                    $user['id_utilisateur'],
                    $reponseId
                ]);
                
                respond(['message' => 'Réponse validée']);
            }
            // Modification du contenu (auteur uniquement)
            elseif (isset($input['contenu'])) {
                if ($reponse['id_auteur'] != $user['id_utilisateur']) {
                    respond(['error' => 'Non autorisé'], 403);
                }
                
                $stmt = $pdo->prepare("UPDATE reponse SET contenu = ? WHERE id_reponse = ?");
                $stmt->execute([$input['contenu'], $reponseId]);
                
                respond(['message' => 'Réponse mise à jour']);
            }
            else {
                respond(['error' => 'Aucun champ à mettre à jour'], 400);
            }
            break;
        
        case 'DELETE':
            if (!$reponseId) {
                respond(['error' => 'ID réponse requis'], 400);
            }
            
            // Vérifier que l'utilisateur est l'auteur
            $stmt = $pdo->prepare("SELECT id_auteur FROM reponse WHERE id_reponse = ?");
            $stmt->execute([$reponseId]);
            $reponse = $stmt->fetch();
            
            if (!$reponse) {
                respond(['error' => 'Réponse non trouvée'], 404);
            }
            
            if ($reponse['id_auteur'] != $user['id_utilisateur']) {
                respond(['error' => 'Non autorisé'], 403);
            }
            
            $stmt = $pdo->prepare("DELETE FROM reponse WHERE id_reponse = ?");
            $stmt->execute([$reponseId]);
            
            respond(['message' => 'Réponse supprimée']);
            break;
        
        default:
            respond(['error' => 'Méthode non autorisée'], 405);
    }
}

/**
 * Gestion des réactions
 */
function handleReactions($pdo, $method, $segments, $input, $user) {
    switch ($method) {
        case 'GET':
            // Récupérer les types de réactions disponibles
            if (isset($segments[2]) && $segments[2] === 'types') {
                $stmt = $pdo->query("SELECT * FROM type_reaction ORDER BY ordre");
                $types = $stmt->fetchAll();
                respond(['types_reaction' => $types]);
            }
            // Récupérer les réactions d'une réponse
            else {
                $reponseId = $_GET['id_reponse'] ?? null;
                
                if (!$reponseId) {
                    respond(['error' => 'id_reponse requis'], 400);
                }
                
                $stmt = $pdo->prepare("
                    SELECT r.*, u.nom, u.prenom, tr.code, tr.libelle, tr.icone
                    FROM reaction r
                    JOIN utilisateur u ON r.id_utilisateur = u.id_utilisateur
                    JOIN type_reaction tr ON r.id_type_reaction = tr.id_type_reaction
                    WHERE r.id_reponse = ?
                    ORDER BY r.date_reaction DESC
                ");
                $stmt->execute([$reponseId]);
                $reactions = $stmt->fetchAll();
                
                respond(['reactions' => $reactions]);
            }
            break;
        
        case 'POST':
            $required = ['id_reponse', 'id_type_reaction'];
            foreach ($required as $field) {
                if (!isset($input[$field])) {
                    respond(['error' => "Le champ $field est requis"], 400);
                }
            }
            
            // Vérifier si l'utilisateur a déjà réagi à cette réponse
            $stmt = $pdo->prepare("
                SELECT id_reaction FROM reaction 
                WHERE id_reponse = ? AND id_utilisateur = ?
            ");
            $stmt->execute([$input['id_reponse'], $user['id_utilisateur']]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                // Mettre à jour la réaction existante
                $stmt = $pdo->prepare("
                    UPDATE reaction 
                    SET id_type_reaction = ?, date_reaction = NOW() 
                    WHERE id_reaction = ?
                ");
                $stmt->execute([$input['id_type_reaction'], $existing['id_reaction']]);
                
                respond(['message' => 'Réaction mise à jour']);
            } else {
                // Créer une nouvelle réaction
                $stmt = $pdo->prepare("
                    INSERT INTO reaction (id_reponse, id_utilisateur, id_type_reaction) 
                    VALUES (?, ?, ?)
                ");
                $stmt->execute([
                    $input['id_reponse'],
                    $user['id_utilisateur'],
                    $input['id_type_reaction']
                ]);
                
                $reactionId = $pdo->lastInsertId();
                
                respond(['message' => 'Réaction créée', 'id_reaction' => $reactionId], 201);
            }
            break;
        
        case 'DELETE':
            $reponseId = $_GET['id_reponse'] ?? null;
            
            if (!$reponseId) {
                respond(['error' => 'id_reponse requis'], 400);
            }
            
            $stmt = $pdo->prepare("
                DELETE FROM reaction 
                WHERE id_reponse = ? AND id_utilisateur = ?
            ");
            $stmt->execute([$reponseId, $user['id_utilisateur']]);
            
            respond(['message' => 'Réaction supprimée']);
            break;
        
        default:
            respond(['error' => 'Méthode non autorisée'], 405);
    }
}

// ============================================
// FONCTIONS UTILITAIRES
// ============================================

/**
 * Envoyer une réponse JSON
 */
function respond($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}
