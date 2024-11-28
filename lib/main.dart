import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:i_iwara/app/services/app_service.dart';
import 'package:i_iwara/app/services/gallery_service.dart';
import 'package:i_iwara/app/services/light_service.dart';
import 'package:i_iwara/app/services/tag_service.dart';
import 'package:i_iwara/app/services/video_service.dart';
import 'package:i_iwara/utils/logger_utils.dart';
import 'package:i_iwara/utils/proxy/proxy_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/my_app.dart';
import 'app/services/api_service.dart';
import 'app/services/auth_service.dart';
import 'app/services/config_service.dart';
import 'app/services/global_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/user_preference_service.dart';
import 'app/services/user_service.dart';
import 'db/database_service.dart';

void main() {

  // 确保Flutter初始化
  runZonedGuarded(() async {
    // 日志初始化
    LogUtils.init();

    // 确保Flutter初始化
    WidgetsFlutterBinding.ensureInitialized();

    final dbService = DatabaseService();
    await dbService.init();

    // 初始化Getx和视频组件
    await GetStorage.init();
    await StorageService().init();
    Get.put(AppService());
    var configService = await ConfigService().init();
    Get.put(configService);

    // 尝试设置代理
    if (ProxyUtil.isSupportedPlatform()) {
      bool useProxy = configService.settings[ConfigService.USE_PROXY].value;
      if (useProxy) {
        // 先从配置中获取代理信息
        String proxyUrl = configService.settings[ConfigService.PROXY_URL].value;
        HttpOverrides.global = MyHttpOverrides(proxyUrl);
        LogUtils.i('设置代理: $proxyUrl', '启动初始化');
      } else {
        LogUtils.i('未启用代理', '启动初始化');
      }
    }

    var userPreferenceService = await UserPreferenceService().init();
    Get.put(userPreferenceService);
    AuthService authService = await AuthService().init();
    Get.put(authService);
    ApiService apiService = await ApiService.getInstance();
    Get.put(apiService);
    UserService userService = await UserService().init();
    Get.put(userService);
    Get.lazyPut(() => VideoService());
    Get.lazyPut(() => GalleryService());
    Get.lazyPut(() => TagService());
    Get.lazyPut(() => GalleryService());
    Get.lazyPut(() => LightService());
    Get.lazyPut(() => GlobalService());

    // 初始化 MediaKit
    MediaKit.ensureInitialized();

    // 运行应用
    runApp(const MyApp());

    if (GetPlatform.isDesktop && !GetPlatform.isWeb) {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: GetPlatform.isMacOS,
        );
        if (GetPlatform.isLinux) {
          await windowManager.setBackgroundColor(Colors.transparent);
        }
        await windowManager.setMinimumSize(const Size(500, 600));
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }, (error, stackTrace) {
    // 在这里处理未捕获的异常
    LogUtils.e('未捕获的异常: $error', tag: '全局异常处理', stackTrace: stackTrace);
  });
}

/// 代理设置
class MyHttpOverrides extends HttpOverrides {
  final String url;

  MyHttpOverrides(this.url);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return 'PROXY $url';
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}
