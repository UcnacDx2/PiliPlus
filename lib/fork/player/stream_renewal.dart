import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Keeps a long playback alive when the signed playurl links expire.
///
/// Bilibili's `dash` sources carry a `deadline` query parameter (usually about
/// two hours out). A long video outlives it: mpv finishes the buffered range,
/// cannot request the next one, and freezes without an error event. The same
/// happens when the stream was fetched with another account than the one that
/// records history, because nothing else refreshes those links.
///
/// The guard refreshes proactively shortly before the deadline and reactively
/// when the player reports a dead link or stops advancing while playing.
final class ForkStreamRenewal {
  ForkStreamRenewal({
    required this.isPlaying,
    required this.positionMs,
    required this.toast,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Injected by the video page: refetches the playurl and reopens the media.
  Future<bool> Function()? renew;

  final bool Function() isPlaying;
  final int Function() positionMs;
  final void Function(String message) toast;
  final DateTime Function() _clock;

  static final _deadlinePattern = RegExp(r'deadline[=%3D]+(\d{9,})');

  /// Renew this long before the link expires, so the switch never waits for a
  /// stalled request.
  static const refreshAhead = Duration(minutes: 3);

  static const tickInterval = Duration(seconds: 5);
  static const stallTicks = 4;
  static const minRenewGap = Duration(seconds: 15);

  Timer? _deadlineTimer;
  Timer? _retryTimer;
  Timer? _watchdog;

  bool _hasSource = false;
  bool _isLive = false;
  bool _renewing = false;
  int _generation = 0;
  int _stuckTicks = 0;
  int _lastPositionMs = -1;
  int _failures = 0;
  DateTime? _lastAttempt;

  bool get isRenewing => _renewing;

  /// Registers a newly opened media and arms the deadline timer.
  void markSource(String media, {required bool isLive}) {
    _deadlineTimer?.cancel();
    _retryTimer?.cancel();
    _hasSource = !isLive;
    _isLive = isLive;
    _stuckTicks = 0;
    _failures = 0;
    _lastPositionMs = -1;
    _generation++;
    if (!_hasSource) {
      _watchdog?.cancel();
      _watchdog = null;
      return;
    }

    _startWatchdog();
    final refreshIn = timeUntilRefresh(media, _clock());
    if (refreshIn == null) return;
    final delay = refreshIn.isNegative ? const Duration(seconds: 3) : refreshIn;
    if (delay > const Duration(days: 1)) return;
    _deadlineTimer = Timer(delay, () => _attemptRenew('deadline'));
  }

  void clearSource() {
    _hasSource = false;
    _deadlineTimer?.cancel();
    _retryTimer?.cancel();
    _watchdog?.cancel();
    _watchdog = null;
    _generation++;
  }

  /// Handles mpv stream errors. Returns true when the fork takes over, so the
  /// upstream stale-URL retry (which reopens the same dead link) stays quiet.
  bool onStreamError(String event) {
    if (renew == null || !_hasSource || _isLive) return false;
    final deadLink =
        event.startsWith('Failed to open https://') ||
        event.startsWith('Can not open external file https://') ||
        event.startsWith('tcp: ffurl_read returned ') ||
        event.contains('HTTP error 403') ||
        event.contains('HTTP error 404');
    if (!deadLink) return false;
    _scheduleRetry(const Duration(seconds: 2), 'error');
    return true;
  }

  void dispose() {
    clearSource();
    renew = null;
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(tickInterval, (_) => _onTick());
  }

  void _onTick() {
    if (!_hasSource || _isLive || _renewing) return;
    if (!isPlaying()) {
      _stuckTicks = 0;
      _lastPositionMs = -1;
      return;
    }
    final position = positionMs();
    if (position <= 0) return;
    if (_lastPositionMs >= 0 && position - _lastPositionMs > 400) {
      _stuckTicks = 0;
    } else {
      _stuckTicks++;
    }
    _lastPositionMs = position;
    if (_stuckTicks >= stallTicks) {
      _stuckTicks = 0;
      _attemptRenew('stall');
    }
  }

  void _scheduleRetry(Duration delay, String reason) {
    if (renew == null) return;
    _retryTimer?.cancel();
    final generation = _generation;
    _retryTimer = Timer(delay, () {
      if (generation != _generation) return;
      _attemptRenew(reason);
    });
  }

  Future<void> _attemptRenew(String reason) async {
    final renew = this.renew;
    if (renew == null || _renewing) return;
    if (!isPlaying() && reason == 'deadline') {
      _scheduleRetry(const Duration(seconds: 30), reason);
      return;
    }
    final now = _clock();
    final last = _lastAttempt;
    if (last != null && now.difference(last) < minRenewGap) {
      _scheduleRetry(minRenewGap, reason);
      return;
    }

    _renewing = true;
    _lastAttempt = now;
    _generation++;
    try {
      final renewed = await renew();
      if (!renewed) {
        _failures++;
        if (_failures <= 3) {
          _scheduleRetry(Duration(seconds: 15 * _failures), reason);
        } else if (kDebugMode) {
          debugPrint('stream renewal failed $_failures times ($reason)');
        }
        return;
      }
      _failures = 0;
      if (reason != 'deadline') toast('播放地址已刷新');
    } catch (error) {
      if (kDebugMode) debugPrint('stream renewal threw: $error');
      _failures++;
    } finally {
      _renewing = false;
    }
  }

  /// Earliest `deadline` value (unix seconds) found in the media string.
  static int? earliestDeadline(String media) {
    int? earliest;
    for (final match in _deadlinePattern.allMatches(media)) {
      final value = int.tryParse(match.group(1)!);
      if (value == null) continue;
      if (earliest == null || value < earliest) earliest = value;
    }
    return earliest;
  }

  /// Time until the media should be refreshed, or null without a deadline.
  static Duration? timeUntilRefresh(String media, DateTime now) {
    final deadline = earliestDeadline(media);
    if (deadline == null) return null;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      deadline * 1000,
      isUtc: true,
    );
    return expiresAt.difference(now.toUtc()) - refreshAhead;
  }
}
