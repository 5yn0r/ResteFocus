import 'package:flutter_test/flutter_test.dart';
import 'package:restefocus/core/xp.dart';

void main() {
  test('paliers de niveau', () {
    expect(XpLevel.fromXp(0).level, 1);
    expect(XpLevel.fromXp(49).level, 1);
    expect(XpLevel.fromXp(50).level, 2);
    expect(XpLevel.fromXp(149).level, 2);
    expect(XpLevel.fromXp(150).level, 3);
  });

  test('progression dans le niveau', () {
    final l = XpLevel.fromXp(100); // niveau 2 : 50 → 150
    expect(l.xpIntoLevel, 50);
    expect(l.xpForNextLevel, 100);
    expect(l.progress, 0.5);
  });
}
