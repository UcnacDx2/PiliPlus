import 'dart:io';

import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_shader.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:media_kit/media_kit.dart';

abstract final class WatermarkFilter {
  static const maxRegions = WatermarkShader.maxRegions;
  static const _shaderFileName = WatermarkShader.shaderFileName;

  /// Returns the one fixed shader path owned by PiliPlus.
  static String shaderPathFor(String supportDirectory) {
    return PathUtils.buildShadersAbsolutePath(supportDirectory, const [
      _shaderFileName,
    ]);
  }

  /// Removes only the shader file owned by this filter.
  static Future<void> clear(Player player) async {
    try {
      await player.command(removeCommandFor(shaderPathFor(appSupportDirPath)));
    } catch (_) {
      // Removing a path which is not currently loaded is harmless.
    }
  }

  /// Writes and dynamically appends the owned shader. Reapplying always
  /// removes the previous path first, preserving unrelated shaders such as
  /// Anime4K.
  static Future<void> apply(
    Player player,
    List<WatermarkRegion> regions, {
    WatermarkRefinement? refinement,
  }) async {
    final shaderPath = shaderPathFor(appSupportDirPath);
    try {
      await player.command(removeCommandFor(shaderPath));
    } catch (_) {
      // The first application has no previous shader to remove.
    }
    if (regions.isEmpty) return;
    await File(shaderPath).writeAsBytes(
      WatermarkShader.source(regions, refinement: refinement),
    );
    await player.command(appendCommandFor(shaderPath));
  }

  static List<String> removeCommandFor(String shaderPath) {
    return ['change-list', 'glsl-shaders', 'remove', shaderPath];
  }

  static List<String> appendCommandFor(String shaderPath) {
    return ['change-list', 'glsl-shaders', 'append', shaderPath];
  }

  static List<List<String>> commandSequenceFor(String shaderPath) {
    return [removeCommandFor(shaderPath), appendCommandFor(shaderPath)];
  }
}
