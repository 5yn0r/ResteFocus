import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:restefocus/main.dart';

void main() {
  testWidgets('affiche l\'onboarding au premier lancement', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ResteFocusApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur ResteFocus'), findsOneWidget);
  });

  testWidgets('l\'onboarding complet mène à l\'accueil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: ResteFocusApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('C\'est parti'));
    await tester.pumpAndSettle();

    // Le prénom est obligatoire.
    final continueButton = find.widgetWithText(FilledButton, 'Continuer');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Koffi');
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Tes matières'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Dernière étape'), findsOneWidget);
    await tester.tap(find.text('Terminer'));
    // Pas de pumpAndSettle : l'écran Apps (monté dans l'IndexedStack) garde
    // un indicateur de chargement, le plugin installed_apps ne répondant pas
    // en test.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Salut Koffi 👋'), findsOneWidget);
    expect(find.text('Prêt à te concentrer ?'), findsOneWidget);
  });
}
