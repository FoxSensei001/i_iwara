import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:i_iwara/app/services/app_service.dart';
import 'package:i_iwara/app/services/comment_service.dart';
import 'package:i_iwara/app/services/conversation_service.dart';
import 'package:i_iwara/app/services/deep_link_service.dart';
import 'package:i_iwara/app/services/forum_service.dart';
import 'package:i_iwara/app/services/gallery_service.dart';
import 'package:i_iwara/app/services/light_service.dart';
import 'package:i_iwara/app/services/play_list_service.dart';
import 'package:i_iwara/app/services/post_service.dart';
import 'package:i_iwara/app/services/search_service.dart';
import 'package:i_iwara/app/services/tag_service.dart';
import 'package:i_iwara/app/services/video_service.dart';
import 'package:i_iwara/utils/common_utils.dart';
import 'package:i_iwara/utils/logger_utils.dart';
import 'package:i_iwara/utils/proxy/proxy_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'app/my_app.dart';
import 'app/services/api_service.dart';
import 'app/services/auth_service.dart';
import 'app/services/config_service.dart';
import 'app/services/global_search_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/user_preference_service.dart';
import 'app/services/user_service.dart';
import 'db/database_service.dart';
import 'app/services/translation_service.dart';
import 'i18n/strings.g.dart';
import 'app/services/theme_service.dart';
import 'app/services/version_service.dart';
import 'app/repositories/history_repository.dart';
import 'app/services/message_service.dart';

void main() {
  // 确保Flutter初始化
  runZonedGuarded(() async {
    // 日志初始化
    LogUtils.init();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent.withAlpha(0x01)/*Android=28,不能用全透明 */
    ));

    // 确保Flutter初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 设置最高刷新率(仅Android)
    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
        LogUtils.i('已设置最高刷新率', '启动初始化');
      } catch (e) {
        LogUtils.e('设置刷新率失败', tag: '启动初始化', error: e);
      }
    }

    // 初始化基础服务
    await _initializeBaseServices();
    
    // 初始化业务服务
    await _initializeBusinessServices();

    // 运行应用
    runApp(TranslationProvider(child: const MyApp()));

    if (GetPlatform.isDesktop && !GetPlatform.isWeb) {
      await _initializeDesktop();
    }

  }, (error, stackTrace) {
    // 在这里处理未捕获的异常
    LogUtils.e('未捕获的异常: $error', tag: '全局异常处理', stackTrace: stackTrace);
  });
}

/// 初始化基础服务
Future<void> _initializeBaseServices() async {
  LogUtils.i('开始初始化基础服务...', '启动初始化');

  // 初始化深度链接服务
  final deepLinkService = DeepLinkService();
  await deepLinkService.init();
  Get.put(deepLinkService);
  LogUtils.i('深度链接服务初始化完成', '启动初始化');

  // 初始化语言设置
  String systemLanguage = CommonUtils.getDeviceLocale();
  if (systemLanguage == 'zh' || systemLanguage == 'zh-CN' || systemLanguage == 'ja' || systemLanguage == 'zh-TW') {
    LocaleSettings.useDeviceLocale();
  } else if (systemLanguage == 'zh-HK') {
    LocaleSettings.setLocaleRaw('zh-TW');
  } else {
    LocaleSettings.setLocaleRaw('en');
  }
  LogUtils.i('语言设置初始化完成', '启动初始化');

  // 初始化数据库
  final dbService = DatabaseService();
  await dbService.init();
  LogUtils.i('数据库初始化完成', '启动初始化');

  // 初始化存储服务
  await GetStorage.init();
  await StorageService().init();
  LogUtils.i('存储服务初始化完成', '启动初始化');

  // 初始化消息服务
  Get.put(MessageService());
  LogUtils.i('消息服务初始化完成', '启动初始化');

  LogUtils.i('基础服务初始化完成', '启动初始化');
}

/// 初始化业务服务
Future<void> _initializeBusinessServices() async {
  LogUtils.i('开始初始化业务服务...', '启动初始化');

  // 初始化应用服务
  Get.put(AppService());
  LogUtils.i('应用服务初始化完成', '启动初始化');
  
  // 初始化配置服务
  var configService = await ConfigService().init();
  Get.put(configService);
  LogUtils.i('配置服务初始化完成', '启动初始化');

  // 设置代理
  if (ProxyUtil.isSupportedPlatform()) {
    bool useProxy = configService.settings[ConfigService.USE_PROXY].value;
    if (useProxy) {
      String proxyUrl = configService.settings[ConfigService.PROXY_URL].value;
      HttpOverrides.global = MyHttpOverrides(proxyUrl);
      LogUtils.i('代理设置完成: $proxyUrl', '启动初始化');
    } else {
      LogUtils.i('未启用代理', '启动初始化');
    }
  }

  // 初始化用户相关服务
  var userPreferenceService = await UserPreferenceService().init();
  Get.put(userPreferenceService);
  LogUtils.i('用户偏好服务初始化完成', '启动初始化');

  // 初始化认证服务和API服务
  try {
    AuthService authService = await AuthService().init();
    Get.put(authService);
    LogUtils.i('认证服务初始化完成', '启动初始化');
    
    ApiService apiService = await ApiService.getInstance();
    Get.put(apiService);
    LogUtils.i('API服务初始化完成', '启动初始化');
    
    // 只有在认证服务初始化成功后才初始化用户服务
    if (authService.isAuthenticated) {
      try {
        UserService userService = await UserService().init();
        Get.put(userService);
        LogUtils.i('用户服务初始化完成', '启动初始化');
      } catch (e) {
        LogUtils.e('用户服务初始化失败', tag: '启动初始化', error: e);
        // 用户服务初始化失败，清理认证状态
        await authService.handleTokenExpired();
        Get.put(UserService());
      }
    } else {
      // 如果未认证，仍然注册服务但不初始化
      Get.put(UserService());
      LogUtils.i('用户未认证，跳过用户服务初始化', '启动初始化');
    }
  } catch (e) {
    LogUtils.e('认证相关服务初始化失败', tag: '启动初始化', error: e);
    // 即使认证失败，也要注册基本服务
    Get.put(UserService());
    // 确保清理任何可能的部分认证状态
    try {
      final authService = Get.find<AuthService>();
      await authService.handleTokenExpired();
    } catch (_) {}
  }

  // 初始化其他服务
  var versionService = await VersionService().init();
  Get.put(versionService);
  LogUtils.i('版本服务初始化完成', '启动初始化');
  
  var themeService = await ThemeService().init();
  Get.put(themeService);
  LogUtils.i('主题服务初始化完成', '启动初始化');

  // 初始化懒加载服务
  Get.lazyPut(() => VideoService());
  Get.lazyPut(() => CommentService());
  Get.lazyPut(() => SearchService());
  Get.lazyPut(() => GalleryService());
  Get.lazyPut(() => PostService());
  Get.lazyPut(() => TagService());
  Get.lazyPut(() => LightService());
  Get.lazyPut(() => GlobalSearchService());
  Get.lazyPut(() => PlayListService());
  Get.lazyPut(() => ForumService());
  Get.lazyPut(() => ConversationService());
  Get.put(TranslationService());
  LogUtils.i('懒加载服务注册完成', '启动初始化');

  // 初始化媒体服务
  MediaKit.ensureInitialized();
  LogUtils.i('媒体服务初始化完成', '启动初始化');

  // 注册历史记录仓库
  Get.put(HistoryRepository());
  LogUtils.i('历史记录仓库注册完成', '启动初始化');

  LogUtils.i('业务服务初始化完成', '启动初始化');
}

/// 初始化桌面端设置
Future<void> _initializeDesktop() async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
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
