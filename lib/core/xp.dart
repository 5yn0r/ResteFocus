/// Système de niveaux basé sur les XP (1 XP par minute de focus + 5 par
/// Math Gate résolu, voir session_provider.dart).
///
/// Chaque niveau demande 50 XP de plus que le précédent :
/// niveau 2 à 50 XP, niveau 3 à 150, niveau 4 à 300...
class XpLevel {
  const XpLevel._(this.level, this.xpIntoLevel, this.xpForNextLevel);

  factory XpLevel.fromXp(int xp) {
    var level = 1;
    var floor = 0;
    while (xp >= floor + level * 50) {
      floor += level * 50;
      level++;
    }
    return XpLevel._(level, xp - floor, level * 50);
  }

  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;

  double get progress => xpIntoLevel / xpForNextLevel;

  String get title => switch (level) {
    < 3 => 'Débutant',
    < 6 => 'Concentré',
    < 10 => 'Discipliné',
    < 15 => 'Maître du focus',
    _ => 'Légende',
  };
}
