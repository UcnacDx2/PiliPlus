import 'package:PiliPlus/pages_tv/common/tv_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps seven character keys on each TV keyboard row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              // TVSearchPage reserves 440 logical px for the left pane and
              // applies 16 px padding on each side.
              width: 408,
              child: TVKeyboard(onTextChanged: (_) {}),
            ),
          ),
        ),
      ),
    );

    final a = tester.getCenter(find.text('A'));
    final g = tester.getCenter(find.text('G'));
    final h = tester.getCenter(find.text('H'));
    final nine = tester.getCenter(find.text('9'));
    final search = tester.getCenter(find.text('搜索'));

    expect(g.dy, a.dy);
    expect(h.dy, greaterThan(a.dy));
    expect(search.dy, nine.dy);
    expect(tester.getBottomRight(find.text('搜索')).dy, lessThan(500));
  });
}
