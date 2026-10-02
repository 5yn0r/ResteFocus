
RESTEFOCUS
Application Mobile Anti-Distraction
Reste concentré. Débloque ton potentiel.


Projet	ResteFocus — Blocker intelligent avec friction cognitive
Version	2.0 — Mise à jour post-implémentation MVP
Date	Juin 2026 (v1.0) · Septembre 2026 (v2.0)
Auteur	SYNOR
Plateforme	Android (priorité) · iOS (Phase 2, non démarré)
Stack	Flutter · Dart · Kotlin (services natifs) — 100 % local, sans Firebase (voir §6.1 et §7)
Statut	🟢 MVP fonctionnel, testé sur appareil — développement actif

Le document ci-dessous est le cahier des charges initial du projet (sections 1 à 15), conservé tel quel pour l'historique, **annoté** avec l'état réel d'implémentation (✅ Fait · 🔁 Remplacé · 🔜 Prévu · ❌ Abandonné) partout où le projet a divergé du plan d'origine. Écart principal : le MVP a été construit **entièrement en local** (aucune donnée envoyée à un serveur, `shared_preferences` + `SharedPreferences` natif), sans la suite Firebase envisagée en §7 — un choix délibéré de confidentialité et de simplicité, pas un oubli. En contrepartie, plusieurs fonctionnalités hors périmètre initial ont été ajoutées (carnet d'erreurs, widget écran d'accueil, matière Culture & Tech Afrique, citations motivantes) — voir §9.4.

##  Démarrage rapide

Voir [README.md](README.md) pour les instructions d'installation et de lancement à jour.

## 📂 Structure actuelle du code

- `lib/core/` — constantes (matières, citations), thème, formatage, widgets partagés (dont le cadran de durée)
- `lib/data/models/` — modèles (app bloquée, session, problème, problème raté, profil)
- `lib/data/repositories/` — persistance locale JSON via `shared_preferences` (pas de backend)
- `lib/features/` — écrans + providers Riverpod par feature (onboarding, apps, session, math_gate, review, stats, settings, home)
- `lib/services/` — bridge Flutter ↔ Kotlin (`MethodChannel`), générateur de problèmes
- `android/app/src/main/kotlin/.../` — services natifs Android : `FocusAccessibilityService` (détection), `MathGateActivity` (overlay de blocage), `NativeProblemGenerator` (génération de problèmes en Kotlin pur), `MotivationalQuotes`, `FocusWidgetProvider` (widget écran d'accueil), `SessionPrefs` (état partagé)

## 📖 Cahier des charges

Le reste de ce document (sections 1 à 15) est le cahier des charges détaillé du projet.

0. Sommaire


1.  Contexte & Problématique
2.  Objectifs du Projet
3.  Personas & Utilisateurs Cibles
4.  Périmètre Fonctionnel
5.  User Stories
6.  Spécifications Techniques
7.  Architecture Firebase
8.  Architecture Applicative Flutter
9.  La Feature Clé — Math Gate
10.  Sécurité & Anti-Contournements
11.  Gestion des Secrets (Firebase)
12.  Roadmap & Phases
13.  KPIs & Critères de Succès
14.  Contraintes & Risques
15.  Livrables Attendus

1. Contexte & Problématique

Les réseaux sociaux modernes — TikTok, Instagram, YouTube Shorts — sont conçus pour maximiser le temps passé sur la plateforme via des mécanismes de récompense variable (scroll infini, likes imprévisibles) qui activent les mêmes circuits dopaminergiques que les machines à sous.
1.1  Impact sur les étudiants africains
En Afrique, la démocratisation de la 4G/5G a amplifié ce phénomène. Les étudiants en informatique, ingénierie ou sciences n'arrivent plus à maintenir des sessions de concentration longues (90 min+), indispensables pour maîtriser des sujets complexes.
    • Interruptions toutes les 20-30 minutes pour checker les trends
    • Impossibilité d'entrer en état de « deep work » (flux cognitif)
    • Les solutions natives (Screen Time iOS, Digital Wellbeing Android) sont contournables en 2 taps
    • Les solutions sérieuses comme Freedom ou Opal coûtent 40 $/an — inaccessibles pour la majorité

1.2  Tableau comparatif — Avant / Après ResteFocus
Situation actuelle	Avec ResteFocus
    • Blocages désactivables en 2 taps
    • Aucun coût cognitif à la désactivation
    • Aucun lien avec l'apprentissage
    • Solutions payantes en devises étrangères	    • Déblocage nécessite un effort intellectuel
    • Friction cognitive = décision consciente
    • Math Gate renforce les compétences
    • Solution gratuite / freemium locale


2. Objectifs du Projet

2.1  Objectif général
Développer une application mobile Flutter (Android prioritaire, iOS Phase 2) combinant blocage strict des applications distractives et un système de friction cognitive — le Math Gate — basé sur la résolution de problèmes mathématiques ou physiques pour déverrouiller une application bloquée.
2.2  Objectifs spécifiques
    1. Bloquer l'utilisation des apps distractives pendant les sessions d'étude programmées
    2. Imposer des limites de temps journalières par application
    3. Alerter lors de tentatives d'installation d'apps pendant les sessions
    4. Forcer la résolution d'un problème (maths/physique/info) pour accéder à une app bloquée
    5. Calibrer automatiquement la difficulté selon le niveau et le taux de réussite
    6. Fournir des statistiques de productivité claires et motivantes
    7. Rester accessible sans abonnement payant — modèle freemium

2.3  Ce que ResteFocus N'est PAS
    • Un contrôle parental — c'est un outil de self-discipline adulte
    • Un tracker de données personnelles revendu à des tiers
    • Un remplaçant d'un thérapeute ou coach en productivité

3. Personas & Utilisateurs Cibles

🎓  Étudiant Ingénierie	💻  Dev Junior / Freelance	📚  Lycéen / Terminale
Koffi, 21 ans, Abidjan
    • Études en informatique/télécoms
    • Distrait par TikTok & YouTube
    • Veut maintenir 2h de focus min/jour
    • Budget quasi nul	Aicha, 24 ans, Dakar
    • Freelance développement web
    • Mélange travail et réseaux sociaux
    • Veut tracker ses heures facturables
    • Accepte le freemium	Moussa, 17 ans, Ouaga
    • Terminale, prépare le BAC
    • Addictif à Instagram & WhatsApp
    • Veut des maths calibrées lycée
    • Besoin de gamification


4. Périmètre Fonctionnel

Priorités : CRITIQUE = MVP indispensable · HAUTE = V1 · MOYENNE = V2
Module	Fonctionnalité	Priorité	Statut
🔐
Onboarding	Création de profil, sélection du niveau scolaire (Lycée / Licence / Master / Ingé), choix des matières pour le Math Gate	CRITIQUE	✅ Fait
📱
Sélection d'apps	Interface pour choisir les apps à bloquer depuis la liste des apps installées, avec catégories prédéfinies (Réseaux sociaux, Jeux, Vidéo...)	CRITIQUE	✅ Fait
⏱️
Sessions de focus	Démarrage manuel. Durée configurable via cadran circulaire ou présélections.	CRITIQUE	✅ Fait (sans programmation ni notif sonore)
🗓️
Planificateur	Sessions récurrentes (ex: Lundi-Vendredi 8h-12h). Synchronisation optionnelle avec calendrier Android.	HAUTE	🔜 Prévu
⏳
Limites journalières	Quota de temps par app (ex: TikTok max 30 min/jour). Compteur visible. Alerte à 80% et blocage à 100%.	CRITIQUE	🔜 Prévu
🧮
Math Gate	FEATURE CLÉ : À l'ouverture d'une app bloquée, présentation d'un problème (7 matières). Accès accordé uniquement après résolution correcte.	CRITIQUE	✅ Fait — natif, sans Firestore (voir §9)
🎯
Calibrage adaptatif	Niveaux : Lycée / Licence / Ingé. Deux échecs d'affilée font descendre d'un palier de difficulté.	HAUTE	✅ Fait (version simplifiée, pas de montée automatique)
📊
Banque de problèmes	Génération procédurale locale, 7 matières × 3 niveaux, plusieurs variantes par cellule.	HAUTE	🔁 Remplacé (procédural au lieu de Firestore, voir §9.3)
🛡️
Mode strict	Impossible de désactiver ResteFocus pendant une session sans résoudre un problème.	CRITIQUE	✅ Fait
🚫
Anti-install	Alerte + confirmation difficile lors d'installation d'app pendant une session. Journalisation des tentatives.	HAUTE	🔜 Prévu
📈
Dashboard stats	Temps de focus total, Math Gates résolus, streak journalier, graphes hebdo.	HAUTE	✅ Fait — 100 % local, pas de sync cloud
🏆
Gamification	Niveaux XP basés sur les problèmes résolus et le temps de focus. Streak.	MOYENNE	✅ Fait (sans badges ni classement entre amis)
📔
Carnet d'erreurs	*Hors périmètre initial.* Les problèmes ratés reviennent en révision espacée jusqu'à être maîtrisés (2 bonnes réponses de suite).	—	✅ Fait (ajouté en v2.0)
🏠
Widget écran d'accueil	*Hors périmètre initial.* État de la session (fin prévue, streak) visible sans ouvrir l'app.	—	✅ Fait (ajouté en v2.0)
⚙️
Paramètres avancés	Whitelist d'apps toujours autorisées (appels urgence). Mode urgence PIN. Profils multiples (Étude / Travail / Repos).	HAUTE	🔜 Prévu
☁️
Sync Firebase	Profil utilisateur, stats et préférences synchronisés sur Firebase. Accès multi-appareils.	HAUTE	🔜 Prévu (v1 volontairement 100 % local, voir §7)

5. User Stories

ID	En tant que	Je veux	Afin de	Priorité
US-01	Utilisateur	Créer un profil avec mon niveau scolaire et mes matières	Recevoir des problèmes adaptés à mon niveau	Must
US-02	Utilisateur	Sélectionner les apps que je veux bloquer	Cibler précisément mes sources de distraction	Must
US-03	Utilisateur	Programmer des sessions d'étude récurrentes	Automatiser ma discipline sans y penser chaque jour	Must
US-04	Utilisateur	Définir un quota journalier par app	Garder un usage raisonnable sans blocage total	Must
US-05	Utilisateur	Voir un problème de maths quand j'essaie d'ouvrir une app bloquée	Transformer une distraction en moment d'apprentissage	Must
US-06	Utilisateur	Choisir la matière des Math Gates (maths, physique, info)	Réviser ce qui m'est le plus utile	Should
US-07	Utilisateur	Activer un mode strict anti-désactivation	Me protéger de moi-même en période d'examen	Must
US-08	Utilisateur	Voir mes statistiques de focus hebdomadaires	Mesurer mes progrès et rester motivé	Should
US-09	Utilisateur	Retrouver mon profil et mes stats sur un nouvel appareil	Ne pas perdre mes données si je change de téléphone	Should
US-10	Utilisateur	Recevoir une alerte si je tente d'installer une app distractrice	Éviter de contourner le blocage via installation	Should
US-11	Utilisateur	Configurer une whitelist d'apps toujours accessibles	Garder accès aux communications essentielles	Must
US-12	Utilisateur	Gagner des badges selon mes streaks et problèmes résolus	Avoir une motivation ludique à rester focus	Could

6. Spécifications Techniques

6.1  Stack technologique complète

**Choix v2.0 : aucune des lignes Firebase ci-dessous n'a été implémentée.** Le MVP fonctionne 100 % en local (`shared_preferences` côté Flutter, `SharedPreferences` natif côté Kotlin) — plus simple, plus rapide à livrer, et cohérent avec la promesse "tes données restent sur ton téléphone" affichée dans l'app. Le tableau d'origine est gardé ci-dessous comme plan pour une éventuelle V2 multi-appareils.

Couche	Technologie	Justification	Statut
UI / Framework	Flutter + Dart	Cross-platform Android/iOS, performances natives, riche écosystème	✅ Fait
Services Android	Kotlin (AccessibilityService, Overlay, Widget)	APIs système impossibles à atteindre autrement depuis Flutter	✅ Fait
Bridge Flutter↔Kotlin	MethodChannel	Communication bidirectionnelle Flutter ↔ code natif Kotlin	✅ Fait
Backend / BDD cloud	Firebase (suite complète)	Temps réel, auth intégrée, pas de serveur à gérer, free tier généreux	🔜 Prévu (V2)
Auth utilisateur	Firebase Authentication	Auth anonyme → compte email/Google. Sync multi-appareils.	🔜 Prévu (V2)
Base de données	Firebase Firestore	NoSQL temps réel, banque de problèmes mise à jour sans republier l'app	🔁 Remplacé par génération procédurale locale
Stockage fichiers	Firebase Storage	Avatars, exports PDF des stats	🔜 Prévu (V2)
Analytics	Firebase Analytics	Comportement utilisateur anonymisé, taux de rétention	🔜 Prévu (V2)
Notifications push	Firebase Cloud Messaging (FCM)	Rappels de sessions, nouveaux problèmes disponibles	🔜 Prévu (V2)
BDD locale	`shared_preferences` (Flutter) + `SharedPreferences` (Kotlin)	Fonctionnement hors-ligne natif, aucune dépendance réseau	🔁 Remplacé SQLite/sqflite par JSON clé-valeur (suffisant au volume actuel)
State management	Riverpod	Léger, typé, adapté Flutter moderne	✅ Fait
Rendu maths	Unicode (exposants, signe moins, barre de fraction)	Formules lisibles sans dépendance LaTeX lourde	🔁 Remplacé flutter_math_fork par du texte Unicode formaté
Graphes stats	fl_chart	Graphes hebdomadaires du dashboard	✅ Fait
Secrets / Config	dart-define-from-file + env.json	Clés Firebase jamais en dur dans le code source	🔜 Prévu (sans objet tant qu'aucun secret n'est utilisé, voir §11)

6.2  Permissions Android requises
Permission	Niveau	Usage	Statut
SYSTEM_ALERT_WINDOW	Paramètres système	Affiche l'écran Math Gate quand l'utilisateur ouvre une app bloquée	✅ Utilisée
AccessibilityService	Service accessibilité	Détecte les changements de fenêtre en temps réel (déclenche le blocage)	✅ Utilisée
PACKAGE_USAGE_STATS	Paramètres système	Détecter quelle app est utilisée et comptabiliser les quotas	🔜 Prévu (avec les limites journalières, §4)
RECEIVE_BOOT_COMPLETED	Normal	Relancer le service de blocage après reboot du téléphone	🔜 Prévu
INTERNET	Normal	Synchronisation cloud (banque problèmes, stats, auth)	🔜 Prévu (l'app ne fait aujourd'hui aucun appel réseau)
DEVICE_OWNER (optionnel)	Mode Device Owner	Blocage installation/désinstallation d'apps (mode avancé)	🔜 Prévu

7. Architecture Firebase

**🔜 Prévu — non implémenté en v1.** Cette section décrit le plan d'origine pour une V2 multi-appareils ; le MVP actuel n'a aucune dépendance réseau (voir §6.1). Gardée ici comme référence de conception.

7.1  Structure Firestore
Organisation des collections Firestore :
Collection / Document	Champs principaux
users/{uid}	displayName, level, subjects[], createdAt, streakDays, totalFocusMinutes, xpPoints
users/{uid}/sessions/{id}	startTime, endTime, durationMinutes, blockedApps[], mathGatesSolved, mathGatesFailed
users/{uid}/quotas/{date}	{ packageName: minutesUsed } — quota journalier par app
problems/{id}	question (LaTeX), answer, tolerance, level (easy/medium/hard), subject, type (calcul/qcm/theory), hint
badges/{id}	name, description, iconUrl, condition (ex: streak >= 7)

7.2  Règles de sécurité Firestore
Chaque utilisateur ne peut lire/écrire que ses propres données. La banque de problèmes est publique en lecture seule.
    • users/{uid}/** → lecture/écriture si request.auth.uid == uid
    • problems/** → lecture publique, écriture réservée aux admins uniquement
    • badges/** → lecture publique, écriture admin uniquement

7.3  Stratégie offline-first
    • Firestore offline persistence activée → l'app fonctionne sans connexion
    • SQLite local pour les données de session en temps réel (compteurs, overlays)
    • Sync Firebase au retour de connexion de manière transparente

8. Architecture Applicative Flutter

8.1  Structure des dossiers (état réel v2.0)
Architecture Clean + Feature-first :
Dossier	Contenu
lib/core/	constants.dart (matières, citations), theme.dart, format.dart, xp.dart, widgets/ (dont fade_slide_in.dart)
lib/data/models/	blocked_app.dart, focus_session.dart, math_problem.dart, missed_problem.dart, user_profile.dart
lib/data/repositories/	blocked_apps_repository.dart, missed_problems_repository.dart, session_repository.dart, user_repository.dart — tous en JSON via `shared_preferences`
lib/services/	accessibility_bridge.dart (MethodChannel), math_problem_generator.dart
lib/features/	onboarding/, session/ (+ widgets/duration_dial.dart), apps/, math_gate/, review/ (carnet d'erreurs), stats/, settings/, home/, permissions/ — chacun avec screens/ + providers/
android/.../kotlin/	MainActivity.kt, FocusAccessibilityService.kt, MathGateActivity.kt, NativeProblemGenerator.kt, MotivationalQuotes.kt, FocusWidgetProvider.kt, SessionPrefs.kt
assets/	aucun pour l'instant (pas d'animations Lottie ni de polices custom)

8.2  Flux principal — Ouverture d'une app bloquée (état réel)
①	L'utilisateur tente d'ouvrir TikTok pendant une session active
②	FocusAccessibilityService.kt (Kotlin) détecte le changement de fenêtre via AccessibilityEvent
③	Vérification locale (SharedPreferences natif) : package dans la blocklist ? session active ? accès déjà accordé pour cette app ?
④	Si blocage requis → lancement immédiat de MathGateActivity (activité native pure, sans moteur Flutter, pour un affichage instantané)
⑤	NativeProblemGenerator (Kotlin pur, en mémoire) génère un problème dans une matière tirée au hasard parmi celles choisies à l'onboarding
⑥	Affichage du problème (texte Unicode formaté) + une citation motivante (MotivationalQuotes)
⑦	L'utilisateur résout le problème. Validation locale (égalité exacte, les réponses natives sont toujours des entiers).
⑧	Si correct → accès accordé 10 minutes à cette app. Le problème raté le cas échéant reste dans l'historique du device, prêt à être relu par le carnet d'erreurs (§9.4).
⑨	Si incorrect → nouveau problème, le raté est archivé pour le carnet d'erreurs. Après 3 échecs consécutifs : cooldown de 2 minutes avant nouvelle tentative.

9. La Feature Clé — Math Gate

Le Math Gate est la différenciation principale de ResteFocus par rapport à toutes les solutions existantes : transformer chaque tentative de distraction en un moment d'apprentissage actif.
9.1  Niveaux de difficulté (état réel : 3 paliers, pas de palier "Master/Ingé" séparé)
Niveau	Profil	Exemples de problèmes réellement générés
🟢  FACILE	Lycée / L1	Équation du 1er degré (une ou deux inconnues des deux côtés), triangle rectangle (Pythagore), loi d'Ohm, moyenne, boucles imbriquées, adresses hôtes d'un sous-réseau
🟡  MOYEN	L2 / L3	Dérivée d'un polynôme, racines d'une équation du 2nd degré, énergie potentielle/cinétique, combinaisons/arrangements, pont diviseur de tension, complexité d'algorithmes, calcul de broadcast
🔴  DIFFICILE	Master / Ingé	Intégrale d'une fonction polynomiale, suite géométrique, résonance LC, portée d'un projectile, rendement énergétique, écart-type, médiane, résistances en parallèle, suite de Fibonacci récursive, subnetting

Le calibrage ⚡ **adaptatif** décrit ci-dessus (montée automatique >80 %) n'est pas implémenté ; seule la **descente** l'est : deux échecs d'affilée font redescendre d'un palier.

9.2  Matières disponibles
📐 Maths	⚛️ Physique	💻 Algorithmique	📡 Électronique	📊 Stats & Proba	🔌 Réseaux	🌍 Culture & Tech Afrique *(ajoutée en v2.0 — voir §9.4)*

9.3  Format des problèmes (génération procédurale locale — état réel)
    • Question en texte Unicode formaté (exposants, signe moins, barre de fraction) — pas de rendu LaTeX
    • Type calcul : saisie libre, tolérance numérique définie par problème (0 pour les réponses entières, jusqu'à quelques % pour les calculs physiques avec racines/irrationnels)
    • Type QCM : disponible côté Math Gate Flutter (mode strict) pour certaines questions d'algorithmique ; le Math Gate natif (blocage réel d'une app) n'accepte que des réponses numériques
    • Indice optionnel disponible côté Math Gate Flutter uniquement — ne réduit pas la durée d'accès (pas de pénalité implémentée)
    • Pas de temps limite par problème
    • Après 3 échecs consécutifs : cooldown de 2 minutes avant nouvelle tentative (implémenté des deux côtés, natif et Flutter)
    • Chaque problème raté est gardé pour le carnet d'erreurs (§9.4) au lieu d'être simplement perdu

9.4  Fonctionnalités ajoutées en v2.0 (hors périmètre initial)

Trois ajouts construits après le MVP initial, absents du plan d'origine :

    • **Carnet d'erreurs** : chaque problème raté (natif ou Flutter) est archivé — côté natif dans `SessionPrefs` puis rapatrié par Flutter via un appel `MethodChannel` dédié (`pullMissedProblems`), côté Flutter directement dans un repository JSON. Un écran de révision (`lib/features/review/`) les représente un par un, sans pression de temps ; un problème sort du paquet après deux bonnes réponses d'affilée, une erreur le renvoie en fin de paquet. Accessible depuis l'onglet Progrès dès qu'au moins un problème est en attente.
    • **Widget écran d'accueil** (`FocusWidgetProvider.kt`) : affiche l'état de la session (heure de fin) ou le streak sans ouvrir l'app. Un widget Android ne peut pas faire défiler un vrai chrono (le système impose un rafraîchissement automatique toutes les 30 min minimum) — l'heure de fin est donc fixe, rafraîchie immédiatement à chaque démarrage/arrêt de session. Taper le widget ouvre toujours l'app ; aucune action (comme arrêter une session) n'y est possible, pour ne pas contourner le mode strict.
    • **Citations motivantes** : une citation (scientifiques, philosophes, plus quelques lignes de motivation générale — voir `mathGateQuotes` dans `constants.dart` et `MotivationalQuotes.kt` côté natif) s'affiche sous le problème et pendant le cooldown, aux deux endroits où le Math Gate peut apparaître.

10. Sécurité & Anti-Contournements

Un blocker contournable en 2 taps ne sert à rien. ResteFocus anticipe chaque vecteur de bypass — **état réel : seule la contre-mesure du premier vecteur (dismissal de l'overlay) est implémentée ; les autres restent à construire.**
Vecteur	Risque	Contre-mesure prévue	Statut
Fermer/contourner l'écran Math Gate lui-même	🔴 CRITIQUE	Activité `singleTask` non exportée, bouton retour intercepté (redirige vers l'accueil au lieu de fermer l'overlay)	✅ Fait
Désinstaller ResteFocus	🔴 CRITIQUE	Mode Device Owner : désinstallation impossible. Sinon : PIN + délai 24h de cooling-off.	🔜 Prévu
Changer l'heure système	🟡 HAUTE	Sync avec serveur Timestamp. Alerte si heure locale dévie de >5 min.	🔜 Prévu (sans objet tant qu'il n'y a pas de serveur)
Ouvrir l'app via navigateur (PWA)	🟡 HAUTE	Blocage des domaines en parallèle via VPN local Android.	🔜 Prévu
Redémarrer le téléphone	🟡 HAUTE	RECEIVE_BOOT_COMPLETED : le service se relance automatiquement.	🔁 Partiellement couvert — Android relance nativement un AccessibilityService déjà activé par l'utilisateur après reboot ; l'état de session (SharedPreferences) survit aussi au reboot. Pas de receiver dédié.
Chercher la réponse du Math Gate en ligne	🟢 FAIBLE	Le navigateur est lui-même bloqué. Le délai de recherche + résolution décourage la plupart.	🔜 Prévu (le navigateur n'est pas bloqué par défaut)
Cloner ou modifier l'APK ResteFocus	🟢 FAIBLE	Signature APK + validation côté serveur.	🔜 Prévu (build debug actuel, pas de release signée)

11. Gestion des Secrets Firebase

**🔜 Prévu — sans objet pour l'instant.** Le MVP v1/v2.0 n'utilise aucun secret ni clé d'API (pas de Firebase, pas de réseau). Cette section décrit la méthode à suivre le jour où un backend sera ajouté ; le `.gitignore` du dépôt est déjà prêt (entrées `env.json`, `google-services.json`, `*.keystore`, etc.).

Les clés Firebase ne doivent JAMAIS apparaître en dur dans le code source. ResteFocus utilise la méthode native Flutter --dart-define-from-file.
11.1  Principe
    • Fichier env.json à la racine du projet — jamais commité sur Git
    • Fichier env.example.json commité — template vide pour les autres développeurs
    • lib/core/env.dart lit les valeurs via String.fromEnvironment() — aucune valeur en dur
    • Injection au moment du build : flutter run --dart-define-from-file=env.json

11.2  Fichiers Git — Ce qui est commité ou non
Fichier	Git	Raison
env.json	❌  Non	Contient les vraies clés Firebase
env.example.json	✅  Oui	Template vide pour les autres devs
google-services.json	❌  Non	Généré par Firebase, contient les clés du projet
lib/core/env.dart	✅  Oui	Juste des String.fromEnvironment(), aucune valeur réelle
.gitignore	✅  Oui	Inclut env.json, google-services.json, *.env

12. Roadmap & Phases de Développement

Phase	Durée	Tâches principales	Livrable	Statut
Phase 0 Setup	1 semaine	Init Flutter, structure dossiers	Projet initialisé	✅ Fait (sans Firebase/CI-CD)
Phase 1 POC Blocage	2 semaines	FocusAccessibilityService.kt, MethodChannel Flutter↔Kotlin, overlay SYSTEM_ALERT_WINDOW, test sur TikTok	APK POC fonctionnel	✅ Fait, testé sur appareil réel
Phase 2 MVP Core	3 semaines	Onboarding profil, sélection apps, sessions manuelles, Math Gate (générateur procédural), mode strict	MVP testable	✅ Fait (mode strict sans PIN — bloque la sortie tant qu'un problème n'est pas résolu)
Phase 3 Planificateur	2 semaines	Sessions récurrentes programmées, quotas journaliers (UsageStats), notifications FCM, dashboard stats basique	V0.5 stable	🔁 Partiel — dashboard stats ✅ fait, reste : planificateur, quotas, notifications
Phase 4 Math Gate complet	3 semaines	Banque de problèmes riche (3 niveaux, 7 matières dont Culture & Tech Afrique), système adaptatif, carnet d'erreurs	V1.0 bêta	🔁 Partiel — 7 matières + variantes + carnet d'erreurs ✅ fait (génération procédurale au lieu de Firestore/LaTeX), adaptatif = descente seule
Phase 5 Gamification & Stats	2 semaines	XP, streaks, graphes fl_chart, widget écran d'accueil	V1.0 release	🔁 Partiel — XP/streaks/graphes/widget ✅ fait, reste : badges, sync cloud, export PDF
Phase 6 Play Store	2 semaines	Optimisations batterie, tests multi-devices, screenshots, description store, soumission Play Store	Publié Play Store	🔜 Prévu
Phase 7 iOS	4 semaines	Adaptation iOS (Screen Time API), TestFlight, App Store soumission	V2.0 iOS	🔜 Prévu

13. KPIs & Critères de Succès

**Non mesurés à ce jour** : ces cibles supposent Firebase Analytics / Play Console, qui ne sont pas encore en place (§6.1, §7). Gardées comme objectifs pour la V1 publique.

Métrique	Cible 3 mois	Mesure
Temps de focus moyen/jour (utilisateur actif)	> 90 min	Firestore sessions/{uid}
Taux de résolution Math Gate (correct/tentatives)	> 65%	Compteur events Math Gate Firestore
Taux de rétention à 7 jours	> 50%	Firebase Analytics
Tentatives de contournement bloquées	< 5% des sessions	Log bypass Firestore
Note moyenne Play Store	> 4.2 / 5	Play Console
Streak moyen (jours consécutifs)	> 5 jours	Calcul local + sync Firestore
Problèmes résolus par utilisateur/semaine	> 15	Firestore Math Gate logs


14. Contraintes & Risques

14.1  Contraintes techniques
    • AccessibilityService : Google peut restreindre son usage sur Play Store à tout moment (historique 2019-2022)
    • SYSTEM_ALERT_WINDOW : comportements différents selon les ROM (MIUI, One UI, ColorOS)
    • iOS : Screen Time API bien plus restrictive qu'Android — fonctionnalités réduites en V2
    • Performances : le service background doit consommer < 2% de batterie/jour
    • Firebase free tier (Spark) : 50k lectures/jour et 20k écritures/jour — à surveiller en croissance

14.2  Tableau des risques projet
Risque	Probabilité	Mitigation
Google retire les permissions AccessibilityService	🟡 Moyenne	Surveillance Play Policy, fallback UsageStatsManager + VPN local
Firebase gratuit insuffisant (quotas)	🟢 Faible	Cache Firestore offline actif. Migration Blaze (pay-as-you-go) si nécessaire.
Abandon face à la complexité Kotlin natif	🟡 Moyenne	Commencer par un POC minimaliste AccessibilityService avant de construire le reste
Banque de problèmes insuffisante ou répétitive	🟢 Faible	Générateur algorithmique de problèmes simples en complément de la base manuelle
Manque de temps (Afrobridge + ITEtude + cours)	🔴 Haute	Phases courtes 2-3 semaines, usage personnel en priorité, MVP minimal fonctionnel

15. Livrables Attendus

Phase MVP (Livrable 1)
    8. ✅ APK Android installable (build debug, testé sur appareil réel — pas encore de release signée)
    9. ✅ Service de blocage fonctionnel (AccessibilityService + overlay Kotlin natif)
    10. 🔁 Génération procédurale locale (7 matières × 3 niveaux, plusieurs variantes chacune) au lieu de 20 problèmes Firestore
    11. 🔜 Auth Firebase anonyme → profil utilisateur Firestore (profil géré 100 % en local pour l'instant)
    12. 🔁 Mode strict fonctionnel, sans PIN : la sortie est bloquée tant qu'un problème n'est pas résolu
    13. 🔁 Testé manuellement sur 1 appareil (Samsung Galaxy A56, Android 16) — pas encore multi-devices

Livrable V1.0
    14. 🔁 Toutes les features CRITIQUE sont faites ; plusieurs HAUTE restent à faire (planificateur, quotas, anti-install, whitelist) — voir §4
    15. 🔁 Génération procédurale (7 matières, 3 niveaux) au lieu d'une banque Firestore de 200+ problèmes
    16. ✅ Dashboard statistiques avec graphes fl_chart
    17. 🔜 Sync cloud complète (profil, sessions, badges) — tout est local pour l'instant
    18. 🔜 Gestion secrets via dart-define-from-file (sans objet : aucune clé utilisée aujourd'hui)
    19. 🔜 Soumission Google Play Store

Documentation
    • Cahier des charges (ce document) — v2.0, annoté avec l'état réel
    • [README.md](README.md) — présentation, capture d'écran, stack, démarrage
    • 🔜 Architecture diagram (Excalidraw)
    • 🔜 Guide installation permissions Android (pour utilisateurs non-tech)
    • 🔜 Changelog versionné (CHANGELOG.md)



ResteFocus — Cahier des Charges v2.0
SYNOR · Juin 2026 (v1.0) → Septembre 2026 (v2.0)