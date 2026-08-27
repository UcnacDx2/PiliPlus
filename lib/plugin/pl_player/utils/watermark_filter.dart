import 'dart:io';

import 'package:PiliPlus/plugin/pl_player/models/watermark_region.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:media_kit/media_kit.dart';

abstract final class WatermarkFilter {
  static const maxRegions = 4;
  static const _shaderFileName = 'piliplus_watermark.glsl';

  /// Returns the one fixed shader path owned by PiliPlus.
  static String shaderPathFor(String supportDirectory) {
    return PathUtils.buildShadersAbsolutePath(supportDirectory, const [
      _shaderFileName,
    ]);
  }

  /// Builds the mpv GLSL shader without touching the player or filesystem.
  ///
  /// The shader leaves pixels outside each normalized region untouched. Inside
  /// a region it samples just outside all four edges and bilinearly blends
  /// those samples to cover the watermark.
  static String shaderFor(List<WatermarkRegion> regions) {
    final selected = regions.take(maxRegions).toList(growable: false);
    final regionSource = StringBuffer();
    for (var index = 0; index < selected.length; index++) {
      final region = selected[index];
      regionSource
        ..writeln(
          '  const vec4 region$index = vec4('
          '${_glslNumber(region.left)}, ${_glslNumber(region.top)}, '
          '${_glslNumber(region.right)}, ${_glslNumber(region.bottom)});',
        )
        ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
        ..writeln('    color = piliplus_fill(HOOKED_pos, region$index);')
        ..writeln('  }');
    }

    return '''//!HOOK MAIN
//!BIND HOOKED
//!DESC PiliPlus watermark removal

vec4 piliplus_fill(vec2 uv, vec4 rect) {
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 position = clamp((uv - rect.xy) / size, 0.0, 1.0);
  vec2 pad = max(HOOKED_pt * 2.0, vec2(0.0005));

  vec4 left = HOOKED_tex(vec2(max(rect.x - pad.x, 0.0), uv.y));
  vec4 right = HOOKED_tex(vec2(min(rect.z + pad.x, 1.0), uv.y));
  vec4 top = HOOKED_tex(vec2(uv.x, max(rect.y - pad.y, 0.0)));
  vec4 bottom = HOOKED_tex(vec2(uv.x, min(rect.w + pad.y, 1.0)));

  vec4 horizontal = mix(left, right, position.x);
  vec4 vertical = mix(top, bottom, position.y);
  if (rect.x <= pad.x) horizontal = right;
  if (rect.z >= 1.0 - pad.x) horizontal = left;
  if (rect.y <= pad.y) vertical = bottom;
  if (rect.w >= 1.0 - pad.y) vertical = top;
  float edgeX = min(position.x, 1.0 - position.x);
  float edgeY = min(position.y, 1.0 - position.y);
  float verticalWeight = edgeX / max(edgeX + edgeY, 0.000001);
  return mix(horizontal, vertical, verticalWeight);
}

bool piliplus_inside(vec2 uv, vec4 rect) {
  return uv.x >= rect.x && uv.x <= rect.z &&
      uv.y >= rect.y && uv.y <= rect.w;
}

vec4 hook() {
  vec4 color = HOOKED_tex(HOOKED_pos);
${regionSource.toString()}  return color;
}
''';
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
    List<WatermarkRegion> regions,
  ) async {
    final shaderPath = shaderPathFor(appSupportDirPath);
    try {
      await player.command(removeCommandFor(shaderPath));
    } catch (_) {
      // The first application has no previous shader to remove.
    }
    if (regions.isEmpty) return;
    await File(shaderPath).writeAsString(shaderFor(regions));
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

  static String _glslNumber(double value) {
    if (value == 0) return '0.0';
    if (value == 1) return '1.0';
    return value.toStringAsFixed(6);
  }
}
