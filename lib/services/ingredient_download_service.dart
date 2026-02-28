import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe_model.dart';

/// Handles exporting the ingredients list as text or image.
///
/// Dependencies (add to pubspec.yaml):
///   share_plus: ^7.2.1
///   path_provider: ^2.1.1
class IngredientDownloadService {
  IngredientDownloadService._();
  static final instance = IngredientDownloadService._();

  // ── Text export ────────────────────────────────────────────────────────────

  /// Shares the ingredient list as plain text via the system share sheet.
  Future<void> shareAsText({
    required Recipe recipe,
    required List<String> ingredients,
    required bool isTelugu,
  }) async {
    final title = isTelugu ? recipe.titleTe : recipe.title;
    final heading = isTelugu ? 'పదార్థాలు' : 'Ingredients';
    final serving = isTelugu
        ? '${recipe.servings} వ్యక్తులకు'
        : 'Serves ${recipe.servings}';

    final buffer = StringBuffer();
    buffer.writeln('$title — $heading');
    buffer.writeln(serving);
    buffer.writeln('─' * 35);
    for (var i = 0; i < ingredients.length; i++) {
      buffer.writeln('${i + 1}. ${ingredients[i]}');
    }
    buffer.writeln();
    buffer.writeln(isTelugu
        ? 'రుచి యాప్ ద్వారా షేర్ చేయబడింది 🍛'
        : 'Shared via Ruchi App 🍛');

    await Share.share(
      buffer.toString(),
      subject: '$title — $heading',
    );
  }

  // ── Image export ───────────────────────────────────────────────────────────

  /// Captures [boundaryKey]'s widget as a PNG and shares it.
  /// [boundaryKey] must be attached to a RepaintBoundary in the widget tree.
  Future<void> shareAsImage({
    required GlobalKey boundaryKey,
    required String recipeTitle,
    required bool isTelugu,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RepaintBoundary not found');
      }

      // Capture at 3× pixel ratio for crisp output
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image capture failed');

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final name = recipeTitle
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      final file = File('${dir.path}/${name}_ingredients.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isTelugu
            ? '$recipeTitle — పదార్థాలు'
            : '$recipeTitle — Ingredients',
      );
    } catch (e) {
      rethrow; // caller shows snackbar
    }
  }
}
