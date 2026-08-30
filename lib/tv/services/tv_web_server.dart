import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:PiliPlus/tv/adapters/tv_account_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';

/// BiliTV-compatible LAN management service for the TV app.
///
/// This service deliberately contains no Widget, FocusNode, or player state.
/// It exposes only settings and account summaries backed by PiliPlus.
class TvWebServer {
  TvWebServer._();

  static final TvWebServer instance = TvWebServer._();
  static const int port = 3322;

  HttpServer? _server;
  Timer? _retryTimer;
  bool _starting = false;
  bool _shouldRun = false;
  String? _localIp;
  late final String _pairingToken = _newToken();

  bool get isRunning => _server != null;
  String? get address => _localIp == null ? null : 'http://$_localIp:$port';

  Future<void> start() async {
    _shouldRun = true;
    if (_server != null || _starting) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _starting = true;
    try {
      _localIp = await _findLocalIp();
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      if (!_shouldRun) {
        await server.close(force: true);
        return;
      }
      _server = server;
      unawaited(server.forEach(_handleRequest));
      debugPrint('TV Web server started at ${address ?? 'port $port'}');
    } catch (error) {
      // The app must remain usable if the port is occupied or networking is
      // unavailable on the TV.
      debugPrint('TV Web server unavailable: $error');
      _server = null;
      // A previous TV build may still own 3322 briefly during an upgrade.
      // Retry once the old process releases it, without requiring a reboot.
      if (_shouldRun) {
        _retryTimer = Timer(const Duration(seconds: 5), () {
          if (_shouldRun && _server == null) unawaited(start());
        });
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _shouldRun = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<String?> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (error) {
      debugPrint('Unable to find TV LAN address: $error');
    }
    return null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    try {
      if (request.method == 'OPTIONS') {
        response.statusCode = HttpStatus.noContent;
      } else if (request.uri.path == '/' ||
          request.uri.path == '/index.html') {
        response.headers.contentType = ContentType.html;
        response.write(_html.replaceAll('__PAIRING_TOKEN__', _pairingToken));
      } else if (request.uri.path == '/api/status' && request.method == 'GET') {
        _json(response, {
          'running': true,
          'port': port,
          'address': address,
        });
      } else if (request.uri.path == '/api/accounts') {
        await _accounts(request);
      } else if (request.uri.path == '/api/settings') {
        await _settings(request);
      } else if (request.uri.path == '/api/sponsor-block/config') {
        await _sponsorBlock(request);
      } else {
        _json(response, {'error': 'Not found'}, HttpStatus.notFound);
      }
    } catch (error) {
      _json(response, {'error': 'Request failed'}, HttpStatus.internalServerError);
      debugPrint('TV Web request failed: $error');
    } finally {
      await response.close();
    }
  }

  Future<void> _accounts(HttpRequest request) async {
    if (!_authorized(request)) {
      _json(request.response, {'error': 'Pairing required'}, HttpStatus.unauthorized);
      return;
    }
    if (request.method == 'GET') {
      final roles = <String, int>{
        'main': Accounts.main.mid,
        'video': Accounts.video.mid,
        'history': Accounts.heartbeat.mid,
        'heartbeat': Accounts.heartbeat.mid,
        'recommend': Accounts.get(AccountType.recommend).mid,
      };
      _json(request.response, {
        'accounts': [
          for (final account in Accounts.account.values)
            _accountSummary(account, roles),
        ],
        'roles': roles,
      });
      return;
    }
    if (request.method != 'POST') {
      _json(request.response, {'error': 'Method not allowed'}, HttpStatus.methodNotAllowed);
      return;
    }
    final body = await _readJson(request);
    final role = body?['role']?.toString();
    final mid = int.tryParse('${body?['mid'] ?? ''}');
    final type = switch (role) {
      'main' => AccountType.main,
      'video' => AccountType.video,
      'history' || 'heartbeat' => AccountType.heartbeat,
      'recommend' => AccountType.recommend,
      _ => null,
    };
    if (type == null || mid == null || mid <= 0) {
      _json(request.response, {'error': 'Invalid role or mid'}, HttpStatus.badRequest);
      return;
    }
    LoginAccount? selected;
    for (final account in Accounts.account.values) {
      if (account.mid == mid) {
        selected = account;
        break;
      }
    }
    if (selected == null) {
      _json(request.response, {'error': 'Account not found'}, HttpStatus.notFound);
      return;
    }
    await Accounts.set(type, selected);
    _json(request.response, {'success': true, 'role': role, 'mid': mid});
  }

  Map<String, dynamic> _accountSummary(LoginAccount account, Map<String, int> roles) {
    final active = account.mid == TvAccountFacade.mid;
    return {
      'mid': account.mid,
      'uname': active ? TvAccountFacade.uname : '',
      'face': active ? TvAccountFacade.face : '',
      'isVip': active && TvAccountFacade.isVip,
      'roles': [for (final entry in roles.entries) if (entry.value == account.mid) entry.key],
    };
  }

  Future<void> _settings(HttpRequest request) async {
    if (request.method == 'GET') {
      _json(request.response, {
        'autoPlay': TvSettingsFacade.autoPlay,
        'watermarkMode': TvSettingsFacade.watermarkMode.name,
      });
      return;
    }
    if (request.method != 'POST') {
      _json(request.response, {'error': 'Method not allowed'}, HttpStatus.methodNotAllowed);
      return;
    }
    if (!_authorized(request)) {
      _json(request.response, {'error': 'Pairing required'}, HttpStatus.unauthorized);
      return;
    }
    final body = await _readJson(request);
    if (body?['autoPlay'] is bool) {
      await TvSettingsFacade.setAutoPlay(body!['autoPlay'] as bool);
    }
    _json(request.response, {'success': true});
  }

  Future<void> _sponsorBlock(HttpRequest request) async {
    if (request.method == 'GET') {
      _json(request.response, {
        'enabled': Pref.enableSponsorBlock,
        'blockLimit': Pref.blockLimit,
        'blockToast': Pref.blockToast,
        'blockTrack': Pref.blockTrack,
        'categories': [
          for (final entry in Pref.blockSettings)
            {'category': entry.first.name, 'skipType': entry.second.name},
        ],
      });
      return;
    }
    if (request.method != 'POST') {
      _json(request.response, {'error': 'Method not allowed'}, HttpStatus.methodNotAllowed);
      return;
    }
    if (!_authorized(request)) {
      _json(request.response, {'error': 'Pairing required'}, HttpStatus.unauthorized);
      return;
    }
    final body = await _readJson(request);
    if (body == null) {
      _json(request.response, {'error': 'Invalid JSON'}, HttpStatus.badRequest);
      return;
    }
    final values = <dynamic, dynamic>{};
    if (body['enabled'] is bool) {
      values[SettingBoxKey.enableSponsorBlock] = body['enabled'];
    }
    if (body['blockToast'] is bool) {
      values[SettingBoxKey.blockToast] = body['blockToast'];
    }
    if (body['blockTrack'] is bool) {
      values[SettingBoxKey.blockTrack] = body['blockTrack'];
    }
    if (body['blockLimit'] is num) {
      final limit = (body['blockLimit'] as num).toDouble();
      if (limit.isFinite && limit >= 0 && limit <= 3600) {
        values[SettingBoxKey.blockLimit] = limit;
      }
    }
    for (final entry in values.entries) {
      await GStorage.setting.put(entry.key, entry.value);
    }
    _json(request.response, {'success': true});
  }

  Future<Map<String, dynamic>?> _readJson(HttpRequest request) async {
    try {
      final text = await utf8.decoder.bind(request).join();
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  void _json(HttpResponse response, Object data, [int status = HttpStatus.ok]) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
  }

  bool _authorized(HttpRequest request) =>
      request.headers.value('authorization') == 'Bearer $_pairingToken';

  String _newToken() => List<String>.generate(
        32,
        (_) => Random.secure().nextInt(16).toRadixString(16),
      ).join();

  static const _html = '''<!doctype html>
<html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BiliTV</title><style>
body{margin:0;padding:24px;background:#161623;color:#fff;font:16px system-ui,sans-serif}main{max-width:720px;margin:auto}
section{margin:16px 0;padding:20px;border:1px solid #35354b;border-radius:14px;background:#202033}
h1,h2{color:#fb7299}button{padding:10px 18px;border:0;border-radius:8px;background:#fb7299;color:#fff;font-size:16px}
label{display:block;margin:12px 0}#state{white-space:pre-wrap;color:#ccc}
</style><main><h1>BiliTV TV 控制台</h1><section><h2>设备</h2><div id="state">加载中…</div></section>
<section><h2>空降助手</h2><label><input id="enabled" type="checkbox"> 启用 SponsorBlock 自动跳过</label>
<label>最短片段（秒）<input id="limit" type="number" min="0" step="0.1"></label>
<button onclick="save()">保存设置</button></section></main><script>
async function load(){let s=await (await fetch('/api/status')).json();document.querySelector('#state').textContent=JSON.stringify(s,null,2);let b=await (await fetch('/api/sponsor-block/config')).json();enabled.checked=b.enabled;limit.value=b.blockLimit}
async function save(){await fetch('/api/sponsor-block/config',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer __PAIRING_TOKEN__'},body:JSON.stringify({enabled:enabled.checked,blockLimit:Number(limit.value)||0})});alert('已保存')};load();
</script>''';
}
