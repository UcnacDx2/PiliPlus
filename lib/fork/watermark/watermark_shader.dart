import 'dart:convert';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';

/// Builds the mpv GLSL shader as a pure function, without touching the player
/// or filesystem. Kept free of `dart:ui` and plugin imports so offline
/// tooling can exercise it too.
///
/// Pixels outside each normalized region are untouched. A region backed by a
/// [WatermarkRefinement] replaces only the stroke cells and leaves the rest of
/// the corner intact; any other region falls back to a four-side blend of the
/// whole rectangle.
///
/// The stroke mask is embedded as an r8 `//!TEXTURE` instead of a GLSL const
/// array: dynamic array indexing, `uint` and bit operations are all
/// unavailable on GLES2-era mobile drivers, and a texture is portable across
/// every GLSL version mpv can compile. The output is the shader source
/// followed by the raw mask bytes.
abstract final class WatermarkShader {
  static const maxRegions = 4;
  static const shaderFileName = 'piliplus_watermark.glsl';

  static Uint8List source(
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
        '${_number(region.left)}, ${_number(region.top)}, '
        '${_number(region.right)}, ${_number(region.bottom)});',
      );
      final refined =
          !usesRefine &&
          refinement != null &&
          _sameRegion(region, refinement.region);
      if (refined) {
        usesRefine = true;
        regionSource
          ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
          ..writeln('    color = piliplus_refine(HOOKED_pos, region$index);')
          ..writeln('  }');
      } else {
        regionSource
          ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
          ..writeln('    color = piliplus_fill(HOOKED_pos, region$index);')
          ..writeln('  }');
      }
    }

    var maskBytes = Uint8List(0);
    var textureHeader = '';
    if (usesRefine) {
      final mask = refinement!.mask;
      maskBytes = _maskBytes(mask);
      textureHeader = '''

//!TEXTURE piliplus_mask_tex
//!SIZE ${mask.columns} ${mask.rows}
//!FORMAT rgba8
//!FILTER LINEAR
//!BORDER 0
''';
    }

    final glsl = '''//!HOOK MAIN
//!BIND HOOKED
//!DESC PiliPlus watermark removal

bool piliplus_inside(vec2 uv, vec4 rect) {
  return uv.x >= rect.x && uv.x <= rect.z &&
      uv.y >= rect.y && uv.y <= rect.w;
}

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
${usesRefine ? _refineHelpers : ''}
vec4 hook() {
  vec4 color = HOOKED_tex(HOOKED_pos);
${regionSource.toString()}  return color;
}
''';
    // The raw mask bytes must directly follow the //!TEXTURE header block.
    return Uint8List.fromList([
      ...utf8.encode(textureHeader),
      ...maskBytes,
      ...utf8.encode(glsl),
    ]);
  }

  static String get _refineHelpers => '''
float piliplus_stroke(vec2 uv, vec4 rect) {
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  return piliplus_mask_tex_tex((uv - rect.xy) / size).r;
}

vec4 piliplus_refine(vec2 uv, vec4 rect) {
  float alpha = smoothstep(0.10, 0.70, piliplus_stroke(uv, rect));
  if (alpha <= 0.001) return HOOKED_tex(uv);
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 step = size / piliplus_mask_tex_size;
  vec4 sum = vec4(0.0);
  float total = 0.0;
  // GLSL ES 1.00 has no const-array initializers, so the eight directions
  // and eight radii are selected with ternaries. Each ray stops at its
  // first clear sample.
  for (int d = 0; d < 8; d++) {
    vec2 dir = d == 0 ? vec2(1.0, 0.0)
      : d == 1 ? vec2(-1.0, 0.0)
      : d == 2 ? vec2(0.0, 1.0)
      : d == 3 ? vec2(0.0, -1.0)
      : d == 4 ? vec2(0.7071, 0.7071)
      : d == 5 ? vec2(0.7071, -0.7071)
      : d == 6 ? vec2(-0.7071, 0.7071)
      : vec2(-0.7071, -0.7071);
    for (int r = 0; r < 8; r++) {
      float radius = r == 0 ? 1.0
        : r == 1 ? 2.0
        : r == 2 ? 3.0
        : r == 3 ? 4.0
        : r == 4 ? 6.0
        : r == 5 ? 8.0
        : r == 6 ? 11.0
        : 15.0;
      vec2 tap = clamp(uv + dir * step * radius, vec2(0.0), vec2(1.0));
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

  static Uint8List _maskBytes(WatermarkStrokeMask mask) {
    // rgba8 is the one pixel format every mpv build accepts for embedded
    // shader textures.
    final bytes = Uint8List(mask.bitCount * 4);
    for (var index = 0; index < mask.bitCount; index++) {
      final value =
          (mask.words[index >> 5] >> (index & 31)) & 1 == 1 ? 255 : 0;
      bytes[index * 4] = value;
      bytes[index * 4 + 1] = value;
      bytes[index * 4 + 2] = value;
      bytes[index * 4 + 3] = 255;
    }
    return bytes;
  }

  static bool _sameRegion(WatermarkRegion first, WatermarkRegion second) =>
      (first.left - second.left).abs() < 0.004 &&
      (first.top - second.top).abs() < 0.004 &&
      (first.right - second.right).abs() < 0.004 &&
      (first.bottom - second.bottom).abs() < 0.004;

  static String _number(double value) {
    if (value == 0) return '0.0';
    if (value == 1) return '1.0';
    return value.toStringAsFixed(6);
  }
}
