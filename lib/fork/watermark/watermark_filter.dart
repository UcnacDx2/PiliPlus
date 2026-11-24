import 'dart:io';

import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
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
  /// Pixels outside each normalized region are untouched. A region backed by a
  /// [WatermarkRefinement] replaces only the stroke cells and leaves the rest
  /// of the corner intact; any other region falls back to a four-side blend of
  /// the whole rectangle.
  static String shaderFor(
    List<WatermarkRegion> regions, {
    WatermarkRefinement? refinement,
  }) {
    final selected = regions.take(maxRegions).toList(growable: false);
    final regionSource = StringBuffer();
    var usesRefine = false;
    for (var index = 0; index < selected.length; index++) {
      final region = selected[index];
      regionSource.writeln(
        '  const vec4 region$index = vec4('
        '${_glslNumber(region.left)}, ${_glslNumber(region.top)}, '
        '${_glslNumber(region.right)}, ${_glslNumber(region.bottom)});',
      );
      final refined =
          !usesRefine &&
          refinement != null &&
          _sameRegion(region, refinement.region);
      if (refined) {
        usesRefine = true;
        regionSource
          ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
          ..writeln(
            '    color = piliplus_refine(HOOKED_pos, region$index);',
          )
          ..writeln('  }');
      } else {
        regionSource
          ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
          ..writeln('    color = piliplus_fill(HOOKED_pos, region$index);')
          ..writeln('  }');
      }
    }

    final refineBlock = usesRefine ? _refineHelpers(refinement!.mask) : '';

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
$refineBlock
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

  static bool _sameRegion(WatermarkRegion first, WatermarkRegion second) =>
      (first.left - second.left).abs() < 0.004 &&
      (first.top - second.top).abs() < 0.004 &&
      (first.right - second.right).abs() < 0.004 &&
      (first.bottom - second.bottom).abs() < 0.004;

  static String _refineHelpers(WatermarkStrokeMask mask) {
    final words = mask.words.map((word) => '${word}u').join(', ');
    final count = mask.words.length;
    return '''

const int piliplus_cols = ${mask.columns};
const int piliplus_rows = ${mask.rows};
const uint piliplus_mask[$count] = uint[$count]($words);

float piliplus_cell(int cx, int cy) {
  if (cx < 0 || cy < 0 || cx >= piliplus_cols || cy >= piliplus_rows) {
    return 0.0;
  }
  int index = cy * piliplus_cols + cx;
  uint word = piliplus_mask[index >> 5];
  return float((word >> uint(index & 31)) & 1u);
}

float piliplus_stroke(vec2 uv, vec4 rect) {
  if (!piliplus_inside(uv, rect)) return 0.0;
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 grid = ((uv - rect.xy) / size) *
      vec2(float(piliplus_cols), float(piliplus_rows)) - vec2(0.5);
  ivec2 base = ivec2(floor(grid));
  vec2 frac = fract(grid);
  float top = mix(
    piliplus_cell(base.x, base.y),
    piliplus_cell(base.x + 1, base.y),
    frac.x
  );
  float bottom = mix(
    piliplus_cell(base.x, base.y + 1),
    piliplus_cell(base.x + 1, base.y + 1),
    frac.x
  );
  return mix(top, bottom, frac.y);
}

vec4 piliplus_refine(vec2 uv, vec4 rect) {
  float alpha = smoothstep(0.10, 0.70, piliplus_stroke(uv, rect));
  if (alpha <= 0.001) return HOOKED_tex(uv);
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 step = size / vec2(float(piliplus_cols), float(piliplus_rows));
  const vec2 dirs[8] = vec2[8](
    vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
    vec2(0.7071, 0.7071), vec2(0.7071, -0.7071),
    vec2(-0.7071, 0.7071), vec2(-0.7071, -0.7071)
  );
  const float radii[8] = float[8](1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 11.0, 15.0);
  vec4 sum = vec4(0.0);
  float total = 0.0;
  for (int d = 0; d < 8; d++) {
    for (int r = 0; r < 8; r++) {
      float radius = radii[r];
      vec2 tap = clamp(uv + dirs[d] * step * radius, vec2(0.0), vec2(1.0));
      // First ray sample that clears the strokes carries the direction.
      float hit = (1.0 - piliplus_stroke(tap, rect)) > 0.5 ? 1.0 / radius : 0.0;
      sum += HOOKED_tex(tap) * hit;
      total += hit;
      if (hit > 0.0) break;
    }
  }
  vec4 filled = total > 0.02
      ? (sum / total)
      : piliplus_fill(uv, rect);
  return mix(HOOKED_tex(uv), filled, alpha);
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
    await File(shaderPath).writeAsString(
      shaderFor(regions, refinement: refinement),
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

  static String _glslNumber(double value) {
    if (value == 0) return '0.0';
    if (value == 1) return '1.0';
    return value.toStringAsFixed(6);
  }
}
