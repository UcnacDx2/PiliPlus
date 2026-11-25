import 'dart:convert';
import 'dart:math' as math;
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
/// The stroke mask is baked into the GLSL as a list of merged rectangles,
/// unrolled into plain if-statements. An earlier fork tried embedding the mask
/// as a `//!TEXTURE` binary blob, but mpv silently drops the whole shader when
/// it fails to parse the blob, which broke both removal modes on mobile. Plain
/// text with no textures compiles everywhere, like the fork.3 fill shader.
abstract final class WatermarkShader {
  static const maxRegions = 4;
  static const shaderFileName = 'piliplus_watermark.glsl';

  /// Upper bound on mask rectangles; beyond this the refinement is dropped
  /// and the region falls back to the whole-rectangle blend. Glyph strokes
  /// fragment into a few hundred runs, which stays a compact plain-text
  /// shader, so the budget only guards against pathological masks.
  static const _maxMaskRects = 96;

  static Uint8List source(
    List<WatermarkRegion> regions, {
    WatermarkRefinement? refinement,
  }) {
    final selected = regions.take(maxRegions).toList(growable: false);
    final regionSource = StringBuffer();
    var maskSource = '';
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
        final rects = _maskRects(refinement.mask);
        if (rects == null || rects.isEmpty) {
          regionSource
            ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
            ..writeln('    color = piliplus_fill(HOOKED_pos, region$index);')
            ..writeln('  }');
        } else {
          maskSource = _maskHelpers(refinement.mask, rects);
          regionSource
            ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
            ..writeln(
              '    color = piliplus_refine(HOOKED_pos, region$index);',
            )
            ..writeln('  }');
        }
      } else {
        regionSource
          ..writeln('  if (piliplus_inside(HOOKED_pos, region$index)) {')
          ..writeln('    color = piliplus_fill(HOOKED_pos, region$index);')
          ..writeln('  }');
      }
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
$maskSource
vec4 hook() {
  vec4 color = HOOKED_tex(HOOKED_pos);
${regionSource.toString()}  return color;
}
''';
    // Pure ASCII text: identical bytes to writeAsString, no binary blob.
    return Uint8List.fromList(utf8.encode(glsl));
  }

  static String _maskHelpers(WatermarkStrokeMask mask, List<_Rect> rects) {
    final buffer = StringBuffer('''
// Grid dimensions of the baked stroke mask, in cells.
const vec2 piliplus_grid = vec2(float(${mask.columns}), float(${mask.rows}));

// One mask rectangle in normalized region coordinates.
bool piliplus_cell(vec2 uv, vec4 rect, vec4 cell) {
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 local = (uv - rect.xy) / size;
  return local.x >= cell.x && local.x < cell.z &&
      local.y >= cell.y && local.y < cell.w;
}

float piliplus_stroke(vec2 uv, vec4 rect) {
''');
    for (final rect in rects) {
      buffer.writeln(
        '  if (piliplus_cell(uv, rect, vec4('
        '${_number(rect.x0)}, ${_number(rect.y0)}, '
        '${_number(rect.x1)}, ${_number(rect.y1)}))) return 1.0;',
      );
    }
    buffer
      ..writeln('  return 0.0;')
      ..writeln('}')
      ..writeln('''
vec4 piliplus_refine(vec2 uv, vec4 rect) {
  float alpha = piliplus_stroke(uv, rect);
  if (alpha <= 0.001) return HOOKED_tex(uv);
  vec2 size = max(rect.zw - rect.xy, vec2(0.000001));
  vec2 step = size / piliplus_grid;
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
''');
    return buffer.toString();
  }

  /// Converts the packed stroke mask into merged cell rectangles, or null
  /// when the mask is too fragmented to embed compactly (the caller then
  /// falls back to the whole-region fill).
  ///
  /// Glyph strokes are thin and slanted, so the native grid yields well over a
  /// thousand one-cell runs, and a shader with that many branches is both huge
  /// and slow to compile on mobile drivers. Each coarser grid covers a block of
  /// cells, which also absorbs the antialiased fringe, so the finest grid whose
  /// rectangle count fits the budget wins.
  static List<_Rect>? _maskRects(WatermarkStrokeMask mask) {
    for (final (factor, tolerance) in const [
      (1, 0),
      (1, 1),
      (2, 0),
      (2, 1),
      (3, 1),
    ]) {
      final rects = _rectsAt(mask, factor, tolerance);
      if (rects != null && rects.isNotEmpty) return rects;
    }
    return null;
  }

  static List<_Rect>? _rectsAt(
    WatermarkStrokeMask mask,
    int factor,
    int tolerance,
  ) {
    final columns = (mask.columns + factor - 1) ~/ factor;
    final rows = (mask.rows + factor - 1) ~/ factor;
    bool filled(int x, int y) {
      final endX = math.min((x + 1) * factor, mask.columns);
      final endY = math.min((y + 1) * factor, mask.rows);
      for (var sy = y * factor; sy < endY; sy++) {
        for (var sx = x * factor; sx < endX; sx++) {
          if (mask.bitAt(sx, sy)) return true;
        }
      }
      return false;
    }

    // Maximal horizontal runs per row.
    final runsPerRow = <List<List<int>>>[];
    for (var y = 0; y < rows; y++) {
      final runs = <List<int>>[];
      var start = -1;
      for (var x = 0; x <= columns; x++) {
        final set = x < columns && filled(x, y);
        if (set && start < 0) {
          start = x;
        } else if (!set && start >= 0) {
          runs.add([start, x]);
          start = -1;
        }
      }
      runsPerRow.add(runs);
    }

    // Merge runs into the previous row's rect when their spans nearly match;
    // the union keeps slanted strokes as one tall rectangle.
    final rects = <_Rect>[];
    var active = <List<int>>[];
    for (var y = 0; y < rows; y++) {
      final next = <List<int>>[];
      for (final run in runsPerRow[y]) {
        var merged = false;
        for (final candidate in active) {
          if (candidate.isEmpty) continue;
          if ((candidate[0] - run[0]).abs() <= tolerance &&
              (candidate[1] - run[1]).abs() <= tolerance &&
              candidate[3] == y) {
            candidate[0] = math.min(candidate[0], run[0]);
            candidate[1] = math.max(candidate[1], run[1]);
            candidate[3] = y + 1;
            next.add(candidate);
            merged = true;
            break;
          }
        }
        if (!merged) next.add([run[0], run[1], y, y + 1]);
      }
      for (final candidate in active) {
        if (candidate.isEmpty) continue;
        // Only close rects that the current row did not extend.
        if (candidate[3] <= y) {
          rects.add(_cellsToRect(candidate, columns, rows));
        } else {
          next.add(candidate);
        }
      }
      active = next;
      if (rects.length + active.length > _maxMaskRects) return null;
    }
    for (final candidate in active) {
      rects.add(_cellsToRect(candidate, columns, rows));
    }
    if (rects.length > _maxMaskRects) return null;
    return rects;
  }

  static _Rect _cellsToRect(List<int> cells, int columns, int rows) => _Rect(
    x0: cells[0] / columns,
    y0: cells[2] / rows,
    x1: cells[1] / columns,
    y1: cells[3] / rows,
  );

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

final class _Rect {
  const _Rect({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });

  final double x0;
  final double y0;
  final double x1;
  final double y1;
}
