-- MySQL dump 10.13  Distrib 9.5.0, for macos26.1 (arm64)
--
-- Host: localhost    Database: forum_db
-- ------------------------------------------------------
-- Server version	9.5.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `matiere`
--

DROP TABLE IF EXISTS `matiere`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `matiere` (
  `id_matiere` int NOT NULL AUTO_INCREMENT,
  `nom_matiere` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code_matiere` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `id_enseignant` int DEFAULT NULL,
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_matiere`),
  UNIQUE KEY `id_matiere_UNIQUE` (`id_matiere`),
  UNIQUE KEY `nom_matiere_UNIQUE` (`nom_matiere`),
  KEY `fk_matiere_enseignant_idx` (`id_enseignant`),
  CONSTRAINT `fk_matiere_enseignant` FOREIGN KEY (`id_enseignant`) REFERENCES `utilisateur` (`id_utilisateur`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `matiere`
--

LOCK TABLES `matiere` WRITE;
/*!40000 ALTER TABLE `matiere` DISABLE KEYS */;
INSERT INTO `matiere` VALUES (1,'Statistiques appliquées aux sciences de l\'éducation','STAT-EDU','Statistiques pour les sciences de l\'éducation',NULL,'2026-01-10 22:22:10'),(2,'Montage et gestion des projets EDTECH innovants','EDTECH','Projets technologiques éducatifs',NULL,'2026-01-10 22:22:10'),(3,'Méthodologie de recherche et outils d\'analyse en sciences de l\'éducation','METHODO','Méthodologie et analyse de recherche',NULL,'2026-01-10 22:22:10'),(4,'Ludo-pédagogie et serious games','LUDO-GAMES','Apprentissage par le jeu',NULL,'2026-01-10 22:22:10'),(5,'Évaluation et innovation : dispositifs et méthodes','EVAL-INNOV','Méthodes d\'évaluation innovantes',NULL,'2026-01-10 22:22:10'),(6,'Langues étrangères (Français / Anglais)','LANGUES','Cours de langues FR/EN',NULL,'2026-01-10 22:22:10'),(7,'Culture and Art skill','CULTURE-ART','Compétences culturelles et artistiques',NULL,'2026-01-10 22:22:10');
/*!40000 ALTER TABLE `matiere` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question`
--

DROP TABLE IF EXISTS `question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question` (
  `id_question` int NOT NULL AUTO_INCREMENT,
  `titre` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_publication` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `id_matiere` int NOT NULL,
  `id_auteur` int NOT NULL,
  `est_resolue` tinyint(1) NOT NULL DEFAULT '0',
  `nombre_vues` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_question`),
  UNIQUE KEY `id_question_UNIQUE` (`id_question`),
  KEY `fk_question_matiere_idx` (`id_matiere`),
  KEY `fk_question_auteur_idx` (`id_auteur`),
  KEY `idx_date_publication` (`date_publication` DESC),
  CONSTRAINT `fk_question_auteur` FOREIGN KEY (`id_auteur`) REFERENCES `utilisateur` (`id_utilisateur`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_question_matiere` FOREIGN KEY (`id_matiere`) REFERENCES `matiere` (`id_matiere`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question`
--

LOCK TABLES `question` WRITE;
/*!40000 ALTER TABLE `question` DISABLE KEYS */;
/*!40000 ALTER TABLE `question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reaction`
--

DROP TABLE IF EXISTS `reaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reaction` (
  `id_reaction` int NOT NULL AUTO_INCREMENT,
  `id_reponse` int NOT NULL,
  `id_utilisateur` int NOT NULL,
  `id_type_reaction` int NOT NULL,
  `date_reaction` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_reaction`),
  UNIQUE KEY `id_reaction_UNIQUE` (`id_reaction`),
  UNIQUE KEY `unique_user_reponse_reaction` (`id_reponse`,`id_utilisateur`),
  KEY `fk_reaction_reponse_idx` (`id_reponse`),
  KEY `fk_reaction_utilisateur_idx` (`id_utilisateur`),
  KEY `fk_reaction_type_idx` (`id_type_reaction`),
  CONSTRAINT `fk_reaction_reponse` FOREIGN KEY (`id_reponse`) REFERENCES `reponse` (`id_reponse`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_reaction_type` FOREIGN KEY (`id_type_reaction`) REFERENCES `type_reaction` (`id_type_reaction`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reaction_utilisateur` FOREIGN KEY (`id_utilisateur`) REFERENCES `utilisateur` (`id_utilisateur`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reaction`
--

LOCK TABLES `reaction` WRITE;
/*!40000 ALTER TABLE `reaction` DISABLE KEYS */;
/*!40000 ALTER TABLE `reaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reponse`
--

DROP TABLE IF EXISTS `reponse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reponse` (
  `id_reponse` int NOT NULL AUTO_INCREMENT,
  `contenu` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_reponse` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `est_validee` tinyint(1) NOT NULL DEFAULT '0',
  `id_question` int NOT NULL,
  `id_auteur` int NOT NULL,
  `validee_par` int DEFAULT NULL,
  `date_validation` datetime DEFAULT NULL,
  PRIMARY KEY (`id_reponse`),
  UNIQUE KEY `id_reponse_UNIQUE` (`id_reponse`),
  KEY `fk_reponse_auteur_idx` (`id_auteur`),
  KEY `fk_reponse_question_idx` (`id_question`),
  KEY `fk_reponse_validee_par_idx` (`validee_par`),
  KEY `idx_date_reponse` (`date_reponse` DESC),
  CONSTRAINT `fk_reponse_auteur` FOREIGN KEY (`id_auteur`) REFERENCES `utilisateur` (`id_utilisateur`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_reponse_question` FOREIGN KEY (`id_question`) REFERENCES `question` (`id_question`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_reponse_validee_par` FOREIGN KEY (`validee_par`) REFERENCES `utilisateur` (`id_utilisateur`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reponse`
--

LOCK TABLES `reponse` WRITE;
/*!40000 ALTER TABLE `reponse` DISABLE KEYS */;
/*!40000 ALTER TABLE `reponse` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `type_reaction`
--

DROP TABLE IF EXISTS `type_reaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `type_reaction` (
  `id_type_reaction` int NOT NULL AUTO_INCREMENT,
  `code` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `libelle` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `icone` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ordre` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_type_reaction`),
  UNIQUE KEY `id_type_reaction_UNIQUE` (`id_type_reaction`),
  UNIQUE KEY `code_UNIQUE` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `type_reaction`
--

LOCK TABLES `type_reaction` WRITE;
/*!40000 ALTER TABLE `type_reaction` DISABLE KEYS */;
INSERT INTO `type_reaction` VALUES (1,'LIKE','J\'aime','👍',1),(2,'LOVE','Adore','❤️',2),(3,'HELPFUL','Utile','✨',3),(4,'INSIGHTFUL','Pertinent','💡',4);
/*!40000 ALTER TABLE `type_reaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `utilisateur`
--

DROP TABLE IF EXISTS `utilisateur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utilisateur` (
  `id_utilisateur` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mot_de_passe` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type_user` enum('etudiant','enseignant') COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `derniere_connexion` datetime DEFAULT NULL,
  `est_actif` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_utilisateur`),
  UNIQUE KEY `email_UNIQUE` (`email`),
  KEY `idx_type_user` (`type_user`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `utilisateur`
--

LOCK TABLES `utilisateur` WRITE;
/*!40000 ALTER TABLE `utilisateur` DISABLE KEYS */;
INSERT INTO `utilisateur` VALUES (1,'Test','User','test@test.com','$2y$10$Q0jG7qdfZ8xwYkAkbA.6nudJ/GBzH7iZ15KA5gqniCpb0qa0zseSy','etudiant','2026-01-10 21:26:22','2026-01-11 13:19:47',1),(12,'Benani','Youssef','youssef.benani@edu.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','enseignant','2026-01-10 22:23:51','2026-01-10 22:34:54',1),(13,'El Fassi','Nadia','nadia.elfassi@edu.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','enseignant','2026-01-10 22:23:51','2026-01-11 13:04:20',1),(14,'Alaoui','Karim','karim.alaoui@edu.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','enseignant','2026-01-10 22:23:51',NULL,1),(15,'Chraibi','Fatima','fatima.chraibi@edu.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','enseignant','2026-01-10 22:23:51',NULL,1),(16,'Tazi','Omar','omar.tazi@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51','2026-01-10 22:45:52',1),(17,'Benjelloun','Sara','sara.benjelloun@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51',NULL,1),(18,'Idrissi','Amine','amine.idrissi@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51',NULL,1),(19,'Berrada','Hajar','hajar.berrada@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51',NULL,1),(20,'Sqalli','Mehdi','mehdi.sqalli@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51',NULL,1),(21,'El Amrani','Salma','salma.elamrani@student.ma','$2y$10$w/Ma/LXMrK9rjKYEBbPhB.B1Dvc5Mns7xEhR.r00rlUFAg9A2gGbm','etudiant','2026-01-10 22:23:51',NULL,1);
/*!40000 ALTER TABLE `utilisateur` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-11 13:29:10
