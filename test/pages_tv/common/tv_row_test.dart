import 'package:PiliPlus/pages_tv/common/tv_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preloads more items before reaching the row end', (
    tester,
  ) async {
    var loadMoreCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TVRow(
            title: '推荐',
            itemCount: 20,
            itemWidth: 200,
            onApproachingEnd: () => loadMoreCalls++,
            itemBuilder: (_, index) => SizedBox(
              width: 200,
              child: Text('$index'),
            ),
          ),
        ),
      ),
    );

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    expect(loadMoreCalls, greaterThan(0));
  });
}
