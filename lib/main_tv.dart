import 'dart:io';

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/tv/app/tv_app.dart';
import 'package:PiliPlus/tv/services/tv_web_server.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/cache_manager.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/json_file_handler.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<void> _initAppPath() async {
  appSupportDirPath = (await getApplicationSupportDirectory()).path;
}

Future<void> _initTmpPath() async {
  tmpDirPath = (await getTemporaryDirectory()).path;
}

Future<void> _initDownPath() async {
  final externalStorageDirPath = (await getExternalStorageDirectory())?.path;
  if (externalStorageDirPath != null) {
    downloadPath = path.join(externalStorageDirPath, PathUtils.downloadDir);
  } else {
    downloadPath = defDownloadPath;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  PlatformUtils.isTV = true;

  await _initAppPath();
  try {
    await GStorage.init();
  } catch (e) {
    await Utils.copyText(e.toString());
    if (kDebugMode) debugPrint('GStorage init error: $e');
    exit(0);
  }

  // TV 默认画质 1080P，默认关闭硬件解码（如果用户没有手动设置过）
  if (!GStorage.setting.containsKey(SettingBoxKey.defaultVideoQa)) {
    GStorage.setting.put(SettingBoxKey.defaultVideoQa, 80); // 1080P
  }
  if (!GStorage.setting.containsKey(SettingBoxKey.enableHA)) {
    GStorage.setting.put(SettingBoxKey.enableHA, false);
  }

  await Future.wait([
    _initDownPath(),
    _initTmpPath(),
    CacheManager.ensureInitialized(),
  ]);

  Get.lazyPut(AccountService.new);

  HttpOverrides.global = _TVHttpOverrides();

  await setupServiceLocator();

  // BiliTV-compatible LAN management page. A bind failure is intentionally
  // non-fatal and must never prevent the TV app from starting.
  await TvWebServer.instance.start();

  Request();
  Request.setCookie();
  RequestUtils.syncHistoryStatus();

  SmartDialog.config.toast = SmartConfigToast(displayType: .onlyRefresh);

  // TV immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  if (Pref.enableLog) {
    final customParameters = {
      'Build Time': DateFormatUtils.format(
        BuildConfig.buildTime,
        format: DateFormatUtils.longFormatDs,
      ),
      'Commit Hash': BuildConfig.commitHash,
    };
    final fileHandler = await JsonFileHandler.init();
    Catcher2(
      [?fileHandler, const ConsoleHandler()],
      const TvApp(),
      customParameters: customParameters,
    );
  } else {
    runApp(const TvApp());
  }
}

class _TVHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (kDebugMode || Pref.badCertificateCallback) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
