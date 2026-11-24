import 'package:PiliPlus/fork/player/stream_renewal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('earliestDeadline', () {
    test('reads the deadline query parameter', () {
      const media = 'https://xy1.example.com/video.m4s?deadline=1700000000&x=1';
      expect(ForkStreamRenewal.earliestDeadline(media), 1700000000);
    });

    test('reads a url-encoded separator', () {
      const media = 'https://xy1.example.com/a.m4s?foo=1%26deadline%3D1700000123';
      expect(ForkStreamRenewal.earliestDeadline(media), 1700000123);
    });

    test('returns the earliest of several links in an edl source', () {
      const media =
          'edl://!no_chapters;%40%https://a/v.m4s?deadline=1700000500;'
          '!new_stream;!no_chapters;%40%https://b/a.m4s?deadline=1700000200';
      expect(ForkStreamRenewal.earliestDeadline(media), 1700000200);
    });

    test('returns null without a deadline', () {
      expect(
        ForkStreamRenewal.earliestDeadline('https://a/v.m4s?x=1'),
        isNull,
      );
    });
  });

  group('timeUntilRefresh', () {
    final now = DateTime.utc(2026, 11, 24, 12);

    test('lands on the deadline minus the refresh window', () {
      final deadline = now.add(const Duration(hours: 2));
      final media = 'https://a/v.m4s?deadline=${deadline.millisecondsSinceEpoch ~/ 1000}';
      expect(
        ForkStreamRenewal.timeUntilRefresh(media, now),
        const Duration(hours: 2) - ForkStreamRenewal.refreshAhead,
      );
    });

    test('is negative once the refresh window has passed', () {
      final deadline = now.add(const Duration(minutes: 1));
      final media = 'https://a/v.m4s?deadline=${deadline.millisecondsSinceEpoch ~/ 1000}';
      final pending = ForkStreamRenewal.timeUntilRefresh(media, now);
      expect(pending, isNotNull);
      expect(pending!.isNegative, isTrue);
    });

    test('is null without a deadline', () {
      expect(ForkStreamRenewal.timeUntilRefresh('https://a', now), isNull);
    });
  });

  group('onStreamError', () {
    late ForkStreamRenewal renewal;

    setUp(() {
      renewal = ForkStreamRenewal(
        isPlaying: () => true,
        positionMs: () => 0,
        toast: (_) {},
      );
    });

    tearDown(() => renewal.dispose());

    test('stays quiet while no page bound a renewer', () {
      expect(renewal.onStreamError('Failed to open https://a/v.m4s'), isFalse);
    });

    test('takes over a dead network link once a source is armed', () {
      renewal.renew = () async => true;
      // ignore: cascade_invocations
      renewal.markSource('https://a/v.m4s?x=1', isLive: false);
      expect(renewal.onStreamError('Failed to open https://a/v.m4s'), isTrue);
      expect(renewal.onStreamError('HTTP error 403'), isTrue);
    });

    test('leaves live streams to the upstream reconnect', () {
      renewal.renew = () async => true;
      // ignore: cascade_invocations
      renewal.markSource('https://a/live.flv', isLive: true);
      expect(renewal.onStreamError('Failed to open https://a/live.flv'), isFalse);
    });

    test('ignores unrelated errors', () {
      renewal.renew = () async => true;
      // ignore: cascade_invocations
      renewal.markSource('https://a/v.m4s', isLive: false);
      expect(renewal.onStreamError('Could not open codec'), isFalse);
    });
  });
}
