enum SchoolLevel {
  lycee('Lycée', Difficulty.facile),
  licence('Licence', Difficulty.moyen),
  master('Master', Difficulty.difficile),
  ingenieur('Ingénieur', Difficulty.difficile);

  const SchoolLevel(this.label, this.baseDifficulty);
  final String label;

  /// Difficulté de départ du Math Gate pour ce niveau.
  final Difficulty baseDifficulty;
}

enum Subject {
  maths('Maths', '📐'),
  physique('Physique', '⚛️'),
  algo('Algorithmique', '💻'),
  electronique('Électronique', '📡'),
  stats('Stats & Proba', '📊'),
  reseaux('Réseaux', '🔌'),
  culture('Culture Afrique', '🌍');

  const Subject(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum Difficulty {
  facile('Facile'),
  moyen('Moyen'),
  difficile('Difficile');

  const Difficulty(this.label);
  final String label;
}

/// Apps distractives connues, utilisées pour pré-classer et suggérer les
/// apps installées à l'écran de sélection.
const Map<String, List<String>> appCategories = {
  'Réseaux sociaux': [
    'com.zhiliaoapp.musically', // TikTok
    'com.zhiliaoapp.musically.go', // TikTok Lite
    'com.instagram.android',
    'com.instagram.barcelona', // Threads
    'com.facebook.katana',
    'com.facebook.lite',
    'com.twitter.android', // X
    'com.snapchat.android',
    'com.reddit.frontpage',
    'com.pinterest',
  ],
  'Vidéo': [
    'com.google.android.youtube',
    'com.netflix.mediaclient',
    'tv.twitch.android.app',
    'com.amazon.avod.thirdpartyclient', // Prime Video
  ],
  'Jeux': [
    'com.dts.freefireth',
    'com.dts.freefiremax',
    'com.tencent.ig', // PUBG Mobile
    'com.king.candycrushsaga',
    'com.supercell.clashofclans',
    'jp.konami.pesam', // eFootball
    'com.kiloo.subwaysurf',
    'com.ludo.king',
  ],
  'Messagerie': [
    'com.whatsapp',
    'org.telegram.messenger',
    'com.facebook.orca', // Messenger
  ],
};

String? categoryOf(String packageName) {
  for (final entry in appCategories.entries) {
    if (entry.value.contains(packageName)) return entry.key;
  }
  return null;
}

/// Phrases affichées pendant une session, une nouvelle chaque minute.
const List<String> focusQuotes = [
  'Chaque minute de focus te rapproche de ton objectif.',
  'La discipline, c\'est choisir ce que tu veux le plus plutôt que ce que tu veux maintenant.',
  'Ton téléphone peut attendre. Ton avenir, non.',
  'Le deep work se construit une session à la fois.',
  'Les notifications passent, les compétences restent.',
  'Petit effort aujourd\'hui, grande différence demain.',
  'Concentre-toi sur le progrès, pas sur la perfection.',
];

/// Durées proposées (en minutes) sur l'écran de démarrage.
const List<int> sessionDurationPresets = [25, 50, 90, 120];

/// Citations affichées sous le défi (ou le décompte de pause) du Math Gate,
/// une nouvelle à chaque problème. Uniquement des citations réelles et
/// largement attestées, plus quelques lignes de motivation générale.
const List<String> mathGateQuotes = [
  '« La logique vous mènera d\'un point A à un point B. L\'imagination vous mènera partout. » — Albert Einstein',
  '« Il n\'y a pas de voie royale vers la géométrie. » — Euclide',
  '« Ce que nous savons est une goutte d\'eau, ce que nous ignorons est un océan. » — Isaac Newton',
  '« Le hasard ne favorise que les esprits préparés. » — Louis Pasteur',
  '« La nature ne fait rien en vain. » — Aristote',
  '« Donnez-moi un point d\'appui et un levier, et je soulèverai le monde. » — Archimède',
  '« Le cœur a ses raisons que la raison ne connaît point. » — Blaise Pascal',
  '« Je pense, donc je suis. » — René Descartes',
  '« Dans la science, il n\'y a jamais eu de grand pas fait par un seul homme. » — Marie Curie',
  '« Ce que l\'on conçoit bien s\'énonce clairement. » — Nicolas Boileau',
  '« Il est impossible d\'être un mathématicien sans être un poète dans l\'âme. » — Sofia Kovalevskaya',
  '« Je préfère les questions qui ne peuvent pas être répondues aux réponses qui ne peuvent pas être questionnées. » — Richard Feynman',
  '« La machine peut parfois donner des réponses inattendues. » — Alan Turing',
  '« C\'est la poésie de la logique. » — Ada Lovelace, à propos du calcul',
  '« L\'algèbre est la clé qui ouvre les mathématiques modernes. » — Al-Khwarizmi',
  '« Le savoir sans la conscience n\'est que ruine de l\'âme. » — Rabelais',
  '« L\'Afrique n\'est pas un pays, c\'est un continent d\'inventeurs. » — Cheikh Anta Diop',
  '« On ne peut pas résoudre un problème avec le même niveau de pensée qui l\'a créé. » — Albert Einstein',
  '« La persévérance est la clé du succès. » — Nelson Mandela',
  '« Il vaut mieux allumer une bougie que maudire l\'obscurité. » — Confucius',
  '« La discipline est le pont entre les objectifs et les résultats. » — Jim Rohn',
  '« Chaque calcul résolu est une distraction en moins. »',
  '« Le génie, c\'est 1% d\'inspiration et 99% de transpiration. » — Thomas Edison',
  '« On n\'apprend pas en restant passif. On apprend en résolvant. »',
  '« La vitesse ne compte pas si tu vas dans la mauvaise direction. »',
];
