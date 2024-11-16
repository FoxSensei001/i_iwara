import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/ui/pages/video_detail/controllers/related_media_controller.dart';
import 'package:i_iwara/common/enums/media_enums.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../../../utils/common_utils.dart';
import '../../../../../utils/x_version_calculator_utils.dart';
import '../../../../models/user.model.dart';
import '../../../../models/video_source.model.dart';
import '../../../../models/video.model.dart' as video_model;
import '../../../../services/api_service.dart';
import '../../../../services/config_service.dart';
import '../widgets/custom_slider_bar_shape_widget.dart';
import '../widgets/my_video_screen.dart';

class MyVideoStateController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final String? videoId;
  late Player player;
  late VideoController videoController;
  final Logger logger = Logger();
  VolumeController? volumeController;

  final ApiService _apiService = Get.find();
  final ConfigService _configService = Get.find();
  VolumeController? _volumeController;

  // 视频详情页信息
  RxBool isCommentSheetVisible = false.obs; // 评论面板是否可见
  OtherAuthorzMediasController? otherAuthorzVideosController; // 作者的其他视频控制器

  // 状态
  // 播放器状态
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxBool videoPlaying = false.obs;
  final RxBool videoBuffering = true.obs;
  final RxBool sliderDragLoadFinished = true.obs; // 拖动进度条加载完成
  final RxDouble playerPlaybackSpeed = 1.0.obs; // 播放速度
  final RxBool isDesktopAppFullScreen = false.obs; // 是否是应用全屏

  // 工具栏可见性
  final RxBool areToolbarsVisible = true.obs;

  // 视频信息 | 详情页状态
  final RxBool isVideoInfoLoading = false.obs;
  final RxBool isVideoSourceLoading = false.obs;
  final Rxn<String> errorMessage = Rxn<String>(); // 错误信息
  final Rxn<String> videoErrorMessage = Rxn<String>(); // 视频错误信息
  final Rxn<video_model.Video> videoInfo = Rxn<video_model.Video>(); // 视频信息
  final RxBool videoIsReady = false.obs; // 视频是否准备好
  final RxInt sourceVideoWidth = 1920.obs; // 视频宽度
  final RxInt sourceVideoHeight = 1080.obs; // 视频高度
  final RxDouble aspectRatio = (16 / 9).obs; // 视频宽高比
  final RxList<VideoResolution> videoResolutions = <VideoResolution>[].obs;
  final Rxn<String> currentResolutionTag = Rxn<String>();
  final RxBool isDescriptionExpanded = false.obs;
  final RxBool isFullscreen = false.obs;

  // 快进和后退时间设置
  final RxList<BufferRange> buffers = <BufferRange>[].obs; // 缓冲区段列表

  late AnimationController animationController;
  late Animation<Offset> topBarAnimation;
  late Animation<Offset> bottomBarAnimation;

  StreamSubscription<bool>? bufferingSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration?>? durationSubscription;
  StreamSubscription<int?>? widthSubscription;
  StreamSubscription<int?>? heightSubscription;
  StreamSubscription<bool>? playingSubscription;
  StreamSubscription<Duration>? bufferSubscription;

  MyVideoStateController(this.videoId);

  @override
  void onInit() {
    super.onInit();
    // 初始化 VideoController
    player = Player();
    videoController = VideoController(player);

    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      _volumeController = VolumeController();
      // 初始化并关闭系统音量UI
      _volumeController?.showSystemUI = false;
    }

    if (videoId == null) {
      errorMessage.value = '视频ID为空';
      return;
    }

    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      volumeController = VolumeController();
      // 初始化并关闭系统音量UI
      volumeController?.showSystemUI = false;
    }

    // 是否沿用之前的音量
    bool keepLastVolumeKey = _configService[ConfigService.KEEP_LAST_VOLUME_KEY];
    if (keepLastVolumeKey) {
      double lastVolume = _configService[ConfigService.VOLUME_KEY];
      if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        volumeController?.setVolume(lastVolume);
      } else {
        player.setVolume(lastVolume * 100);
      }
    }

    // 是否沿用之前的亮度
    if (!GetPlatform.isWeb && !GetPlatform.isLinux) {
      bool keepLastBrightnessKey =
          _configService[ConfigService.KEEP_LAST_BRIGHTNESS_KEY];
      if (keepLastBrightnessKey) {
        double lastBrightness = _configService[ConfigService.BRIGHTNESS_KEY];
        try {
          ScreenBrightness().setScreenBrightness(lastBrightness);
        } catch (e) {
          logger.e('设置亮度失败: $e');
        }
      }
    }

    // 动画
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    topBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    bottomBarAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    // 想办法让native player默认走系统代理
    if (player.platform is NativePlayer &&
        _configService[ConfigService.USE_PROXY]) {
      bool useProxy = _configService[ConfigService.USE_PROXY];
      String proxyUrl = _configService[ConfigService.PROXY_URL];
      logger.i('使用代理: $useProxy, 代理地址: $proxyUrl');
      if (useProxy && proxyUrl.isNotEmpty) {
        // 如果是以 https 开头的地址，需要转换为 http
        var finalProxyUrl = proxyUrl;
        if (proxyUrl.startsWith('https://')) {
          finalProxyUrl = proxyUrl.replaceFirst('https://', 'http://');
        }
        // 如果没有以 http 开头，需要加上 http://
        if (!proxyUrl.startsWith('http://')) {
          finalProxyUrl = 'http://$proxyUrl';
        }
        (player.platform as dynamic).setProperty(
          'http-proxy',
          finalProxyUrl,
        );
      }
    }

    fetchVideoDetail(videoId!);
  }

  @override
  void onClose() {
    _cancelSubscriptions();
    player.dispose();
    super.onClose();
  }

  // 取消监听
  Future<void> _cancelSubscriptions() async {
    await Future.wait([
      bufferingSubscription?.cancel() ?? Future.value(),
      positionSubscription?.cancel() ?? Future.value(),
      durationSubscription?.cancel() ?? Future.value(),
      widthSubscription?.cancel() ?? Future.value(),
      heightSubscription?.cancel() ?? Future.value(),
      playingSubscription?.cancel() ?? Future.value(),
      bufferSubscription?.cancel() ?? Future.value(),
    ]);
  }

  /// 获取视频详情信息
  void fetchVideoDetail(String videoId) async {
    try {
      isVideoInfoLoading.value = true;
      isVideoSourceLoading.value = true;
      videoErrorMessage.value = null;

      // 获取视频基本信息
      var res = await _apiService.get('/video/$videoId');
      videoInfo.value = video_model.Video.fromJson(res.data);
      if (videoInfo.value == null) {
        errorMessage.value = '视频信息为空';
        return;
      }
      String? authorId = videoInfo.value!.user?.id;
      if (authorId != null) {
        otherAuthorzVideosController = OtherAuthorzMediasController(
            mediaId: videoId, userId: authorId, mediaType: MediaType.VIDEO);
        otherAuthorzVideosController!.fetchRelatedMedias();
      }

      // 如果视频不是私密的且有文件URL，则获取视频源
      if (videoInfo.value!.private == false &&
          videoInfo.value!.fileUrl != null) {
        fetchVideoSource();
      }
    } on DioException catch (e) {
      // 处理 403 错误，表示这是一个私密视频
      if (e.response?.statusCode == 403) {
        videoInfo.value = video_model.Video(
          id: videoId,
          private: true,
          user: User.fromJson(e.response?.data['user']),
        );
        errorMessage.value = '这是一个私密视频';
      } else {
        // 处理其他错误
        errorMessage.value = '获取视频信息失败：${e.message}';
      }
    } finally {
      // 无论成功还是失败，都将加载状态设置为 false
      isVideoInfoLoading.value = false;
      isVideoSourceLoading.value = false;
    }
  }

  /// 获取视频源信息
  Future<void> fetchVideoSource() async {
    try {
      isVideoSourceLoading.value = true;
      videoErrorMessage.value = null;

      // 获取视频源数据
      var res = await _apiService.get(videoInfo.value!.fileUrl!, headers: {
        'X-Version':
            XVersionCalculatorUtil.calculateXVersion(videoInfo.value!.fileUrl!),
      });
      List<dynamic> data = res.data;
      List<VideoSource> sources =
          data.map((item) => VideoSource.fromJson(item)).toList();

      var lastUserSelectedResolution =
          _configService[ConfigService.DEFAULT_QUALITY_KEY];
      // 使用 Video 的 copyWith 方法来更新 videoSources
      videoInfo.value = videoInfo.value!.copyWith(videoSources: sources);

      await resetVideoInfo(
        title: videoInfo.value!.title ?? '',
        resolutionTag: lastUserSelectedResolution,
        videoResolutions: CommonUtils.convertVideoSourcesToResolutions(
            videoInfo.value!.videoSources,
            filterPreview: true),
      );
    } catch (e) {
      // 处理错误
      videoErrorMessage.value = '获取视频源失败：$e';
    } finally {
      // 无论成功还是失败，都将加载状态设置为 false
      isVideoSourceLoading.value = false;
    }
  }

  /// 切换清晰度
  Future<void> switchResolution(String resolutionTag) async {
    logger.i('[切换清晰度] $resolutionTag');
    if (resolutionTag == currentResolutionTag.value) {
      logger.d('清晰度相同，无需切换');
      return;
    }

    // 通过tag找出对应的视频源
    String? url =
        CommonUtils.findUrlByResolutionTag(videoResolutions, resolutionTag);
    if (url == null) {
      Get.snackbar('错误', '未找到对应的视频源');
      return;
    }

    await resetVideoInfo(
      title: videoInfo.value!.title ?? '',
      resolutionTag: resolutionTag,
      videoResolutions: videoResolutions.toList(),
      position: currentPosition.value,
    );
  }

  /// 重置视频信息并加载新视频
  Future<void> resetVideoInfo({
    required String title,
    required String resolutionTag,
    required List<VideoResolution> videoResolutions,
    Duration position = Duration.zero,
  }) async {
    logger.i('[重置视频] $title $resolutionTag $videoResolutions $position');

    await _cancelSubscriptions();

    videoIsReady.value = false;
    _configService[ConfigService.DEFAULT_QUALITY_KEY] = resolutionTag;
    this.videoResolutions.value = videoResolutions; // 确保赋值为 List
    currentPosition.value = position;
    currentResolutionTag.value = resolutionTag;
    sliderDragLoadFinished.value = true;
    buffers.clear();

    // 通过tag找出对应的视频源
    String? url =
        CommonUtils.findUrlByResolutionTag(videoResolutions, resolutionTag);
    if (url == null) {
      errorMessage.value = '未找到对应的视频源';
      return;
    }

    await player.open(Media(url));

    // 监听缓冲状态
    bufferingSubscription = player.stream.buffering.listen((buffering) async {
      // logger.d('[视频缓冲中] $buffering');
      videoBuffering.value = buffering;
      if (!videoIsReady.value && !buffering) {
        logger.d('[视频准备好了], 尝试快进到 $currentPosition');
        videoIsReady.value = true;
        await player.seek(currentPosition.value);
      }
    });

    // 监听播放位置
    positionSubscription = player.stream.position.listen((position) async {
      if (!videoIsReady.value) return;

      if (videoIsReady.value &&
          totalDuration.value.inMilliseconds > 0 &&
          position.inMilliseconds > 0 &&
          position >= totalDuration.value) {
        bool repeat = _configService[ConfigService.REPEAT_KEY];
        if (repeat) {
          logger.d('[视频播放完成]，尝试重播');
          await player.seek(Duration.zero);
          await player.play();
        }
      }

      currentPosition.value = position;
      sliderDragLoadFinished.value = true;
    });

    // 监听视频总时长
    durationSubscription = player.stream.duration.listen((duration) {
      logger.d('[视频总时长] $duration');
      totalDuration.value = duration;
    });

    // 监听视频宽度
    widthSubscription = player.stream.width.listen((width) {
      logger.d('[视频宽度] $width');
      if (width != null) {
        sourceVideoWidth.value = width;
      }
    });

    // 监听视频高度
    heightSubscription = player.stream.height.listen((height) {
      logger.d('[视频高度] $height');
      if (height != null) {
        sourceVideoHeight.value = height;
        _updateAspectRatio();
      }
    });

    // 正在播放
    playingSubscription = player.stream.playing.listen((playing) {
      videoPlaying.value = playing;
    });

    // 缓冲进度
    // 监听缓冲进度
    bufferSubscription = player.stream.buffer.listen((bufferDuration) {
      // logger.d('[缓冲进度] $bufferDuration');
      // _addBufferRange(bufferDuration);
    });
  }

  /// 更新视频宽高比
  void _updateAspectRatio() {
    aspectRatio.value = sourceVideoWidth.value / sourceVideoHeight.value;
    logger.d(
        '[更新后的宽高比] $aspectRatio, 视频高度: $sourceVideoHeight, 视频宽度: $sourceVideoWidth');
  }

  /// 进入全屏模式
  Future<void> enterFullscreen() async {
    isFullscreen.value = true;
    bool renderVerticalVideoInVerticalScreen =
        _configService[ConfigService.RENDER_VERTICAL_VIDEO_IN_VERTICAL_SCREEN];
    Get.to(() => MyVideoScreen(
          isFullScreen: true,
          myVideoStateController: this,
        ));
    if (renderVerticalVideoInVerticalScreen && aspectRatio.value < 1) {
      await CommonUtils.defaultEnterNativeFullscreen(toVerticalScreen: true);
    } else {
      await defaultEnterNativeFullscreen();
    }
  }

  /// 退出全屏模式
  void exitFullscreen() async {
    Get.back();
    await defaultExitNativeFullscreen();
    isFullscreen.value = false;
  }

  // 切换工具栏的显示
  void toggleToolbars() {
    logger.d('[切换工具栏]');
    if (animationController.isCompleted) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
  }

  // 设置当前视频的播放倍率
  void setPlaybackSpeed(double d) {
    player.setRate(d);
  }

  void setLongPressPlaybackSpeedByConfiguration() {
    double speed = _configService[ConfigService.LONG_PRESS_PLAYBACK_SPEED_KEY];
    player.setRate(speed);
  }

  void addVolume(double d) {
    double configVolume = _configService[ConfigService.VOLUME_KEY];
    double newVolume = (configVolume + d).clamp(0.0, 1.0);
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      volumeController?.setVolume(newVolume);
      logger.d('[音量] $newVolume, $d, $configVolume');
    } else {
      player.setVolume(newVolume * 100);
      logger.d('[音量] ${newVolume * 100}, $d, $configVolume');
    }
    _configService[ConfigService.VOLUME_KEY] = newVolume;
  }

  void setVolume(double d) {
    d = d.clamp(0.0, 1.0);
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      volumeController?.setVolume(d);
    } else {
      player.setVolume(d * 100);
    }
    _configService[ConfigService.VOLUME_KEY] = d;
  }

// TODO 合并缓冲区的代码暂时不用，以后看看怎么改合适
// void _addBufferRange(Duration bufferDuration) {
//   final Duration start = currentPosition.value;
//   final Duration end = bufferDuration;
//
//   // 如果 bufferDuration 小于或等于当前播放位置，缓冲段无效，直接返回
//   if (end <= start) {
//     return;
//   }
//
//   BufferRange newRange = BufferRange(start: start, end: end);
//
//   List<BufferRange> updatedBuffers = buffers.toList();
//
//   // 合并新缓冲段与现有的缓冲段
//   bool merged = false;
//   for (int i = 0; i < updatedBuffers.length; i++) {
//     BufferRange existingRange = updatedBuffers[i];
//     if (existingRange.overlapsOrAdjacent(newRange)) {
//       // 合并缓冲段
//       BufferRange mergedRange = existingRange.merge(newRange);
//       updatedBuffers[i] = mergedRange;
//       merged = true;
//
//       // 检查合并后的缓冲段是否与其他缓冲段重叠或相邻
//       newRange = mergedRange;
//       i = -1; // 重置循环，从头开始检查
//     }
//   }
//
//   if (!merged) {
//     // 如果没有合并，直接添加新的缓冲段
//     updatedBuffers.add(newRange);
//   }
//
//   // 对缓冲段列表进行排序
//   updatedBuffers.sort((a, b) => a.start.compareTo(b.start));
//
//   buffers.value = updatedBuffers;
// }
//
// void _handleSeek(Duration newPosition) {
//   currentPosition.value = newPosition;
//
//   // 根据新的播放位置更新缓冲段列表
//   // 假设在 Seek 操作后，之前的缓冲段仍然有效，我们只需保留与新位置重叠或相邻的缓冲段
//   List<BufferRange> updatedBuffers = buffers.where((range) {
//     // 保留与新位置相邻或重叠的缓冲段
//     return range.overlapsOrAdjacent(BufferRange(
//       start: newPosition,
//       end: newPosition + Duration(seconds: 1), // 给一个小范围的区间
//     ));
//   }).toList();
//
//   buffers.value = updatedBuffers;
// }

// void _updateBufferRanges(Duration position) {
//   List<BufferRange> updatedBuffers = buffers.where((range) {
//     // 保留结束位置在当前播放位置之后的缓冲段
//     return range.end > position;
//   }).toList();
//
//   buffers.value = updatedBuffers;
// }
}

/// 视频清晰度模型
class VideoResolution {
  final String label;
  final String url;

  VideoResolution({required this.label, required this.url});
}