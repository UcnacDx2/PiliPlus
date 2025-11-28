import 'package:PiliPlus/utils/tv_key_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test TV Key Mapping', () {
    expect(TvKeyHandler.androidToLogicalKey[19], LogicalKeyboardKey.arrowUp);
    expect(TvKeyHandler.androidToLogicalKey[20], LogicalKeyboardKey.arrowDown);
    expect(TvKeyHandler.androidToLogicalKey[21], LogicalKeyboardKey.arrowLeft);
    expect(TvKeyHandler.androidToLogicalKey[22], LogicalKeyboardKey.arrowRight);
    expect(TvKeyHandler.androidToLogicalKey[23], LogicalKeyboardKey.select);
    expect(TvKeyHandler.androidToLogicalKey[4], LogicalKeyboardKey.back);
    expect(TvKeyHandler.androidToLogicalKey[82], LogicalKeyboardKey.menu);
  });
}
