import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/data/themes_data.dart';
import 'package:puzzle_journey/models/puzzle_result.dart';
import 'package:puzzle_journey/screens/victory/victory_screen.dart';

void main() {
  testWidgets('victory renders before persistence and updates rewards later', (
    tester,
  ) async {
    final theme = gameThemes.first;
    final level = theme.levels.first;
    final completion = Completer<CompletionOutcome>();
    final result = PuzzleResult(
      levelId: level.id,
      themeId: theme.id,
      gridSize: level.gridSize,
      elapsedSeconds: 12,
      moves: 8,
      stars: 3,
      completedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VictoryScreen(
          theme: theme,
          level: level,
          result: result,
          outcomeFuture: completion.future,
        ),
      ),
    );

    expect(find.text('FASE CONCLUÍDA'), findsOneWidget);
    expect(find.text('Salvando recompensas…'), findsOneWidget);

    completion.complete(
      const CompletionOutcome(
        isNewRecord: true,
        xpEarned: 25,
        dailyPointsEarned: 10,
        dailyScore: 40,
      ),
    );
    await tester.pump();

    expect(find.text('Salvando recompensas…'), findsNothing);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('NOVO RECORDE!'), findsOneWidget);
  });
}
