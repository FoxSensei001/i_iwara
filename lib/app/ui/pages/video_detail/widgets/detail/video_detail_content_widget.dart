import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/routes/app_routes.dart';
import 'package:i_iwara/app/services/app_service.dart';
import 'package:i_iwara/app/services/user_service.dart';
import 'package:i_iwara/app/services/video_service.dart';
import 'package:i_iwara/app/ui/pages/video_detail/widgets/detail/video_description_widget.dart';
import 'package:i_iwara/app/ui/widgets/MDToastWidget.dart';
import 'package:i_iwara/app/ui/widgets/avatar_widget.dart';
import 'package:i_iwara/common/enums/media_enums.dart';
import 'package:i_iwara/utils/common_utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../common/constants.dart';
import '../../../../widgets/error_widget.dart';
import '../../controllers/my_video_state_controller.dart';
import 'expandable_tags_widget.dart';
import 'like_avatars_widget.dart';
import '../player/my_video_screen.dart';
import '../../../../widgets/follow_button_widget.dart';
import '../../../../widgets/like_button_widget.dart';
import '../../../../../../i18n/strings.g.dart' as slang;
import 'add_video_to_playlist_dialog.dart';

class VideoDetailContent extends StatelessWidget {
  final MyVideoStateController controller;
  final double paddingTop;
  final double? videoHeight;
  final double? videoWidth;

  const VideoDetailContent({
    super.key,
    required this.controller,
    required this.paddingTop,
    this.videoHeight,
    this.videoWidth,
  });

  @override
  Widget build(BuildContext context) {
    final t = slang.Translations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 视频播放器区域
        ClipRect(
          child: Stack(
            children: [
              Obx(() {
                // 如果视频加载出错，显示错误组件
                if (controller.videoErrorMessage.value != null) {
                  return SizedBox(
                    width: videoWidth,
                    height: (videoHeight ?? (MediaQuery.sizeOf(context).width / 1.7)) + paddingTop,
                    child: Stack(
                      children: [
                        // 添加背景图片
                        if (controller.videoInfo.value?.previewUrl != null)
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: controller.videoInfo.value!.previewUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        // 添加半透明遮罩
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        // 错误提示内容
                        Center(
                          child: CommonErrorWidget(
                            text: controller.videoErrorMessage.value ?? t.videoDetail.errorLoadingVideo,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => AppService.tryPop(),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(t.common.back),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => controller.fetchVideoDetail(controller.videoId ?? ''),
                                icon: const Icon(Icons.refresh),
                                label: Text(t.common.retry),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // 如果是站外视频，显示站外视频提示
                else if (controller.videoInfo.value?.isExternalVideo == true) {
                  return SizedBox(
                    width: videoWidth,
                    height: (videoHeight ?? (MediaQuery.sizeOf(context).width / 1.7)) + paddingTop,
                    child: Stack(
                      children: [
                        // 添加背景图片
                        if (controller.videoInfo.value?.previewUrl != null)
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: controller.videoInfo.value!.previewUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        // 添加半透明遮罩
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        // 原有的提示内容
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.link, size: 48, color: Colors.white),
                              const SizedBox(height: 16),
                              Text(
                                '${t.videoDetail.externalVideo}: ${controller.videoInfo.value?.externalVideoDomain}',
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => AppService.tryPop(),
                                    icon: const Icon(Icons.arrow_back),
                                    label: Text(t.common.back),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (controller.videoInfo.value?.embedUrl != null) {
                                        launchUrl(Uri.parse(controller.videoInfo.value!.embedUrl!));
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: Text(t.videoDetail.openInBrowser),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // 如果不是全屏模式，显示视频播放器
                else if (!controller.isFullscreen.value) {
                  var isDesktopAppFullScreen =
                      controller.isDesktopAppFullScreen.value;
                  return SizedBox(
                    width: !isDesktopAppFullScreen
                        ? videoWidth
                        : MediaQuery.sizeOf(context).width,
                    height: !isDesktopAppFullScreen
                        ? (videoHeight ??
                                (
                                    // 使用有效的视频比例，如果比例小于1，则使用1.7
                                    (controller.aspectRatio.value < 1
                                        ? MediaQuery.sizeOf(context).width / 1.7
                                        : MediaQuery.sizeOf(context).width /
                                            controller.aspectRatio.value))) +
                            paddingTop
                        : MediaQuery.sizeOf(context).height,
                    child: MyVideoScreen(
                        isFullScreen: false,
                        myVideoStateController: controller),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
        // 视频详情内容区域
        Obx(() {
          if (!controller.isDesktopAppFullScreen.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // 视频标题
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SelectableText.rich(
                    TextSpan(
                      text: controller.videoInfo.value?.title ?? '',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 作者信息区域，包括头像和用户名
                _buildAuthorInfo(),
                const SizedBox(height: 8),
                // 视频发布时间和观看次数
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Obx(() => Text(
                        '${t.galleryDetail.publishedAt}：${CommonUtils.formatFriendlyTimestamp(controller.videoInfo.value?.createdAt)}    ${t.galleryDetail.viewsCount}：${CommonUtils.formatFriendlyNumber(controller.videoInfo.value?.numViews)}',
                        style: const TextStyle(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 16),
                // 视频描述内容，支持展开/收起
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Obx(() => VideoDescriptionWidget(
                        description: controller.videoInfo.value?.body,
                        isDescriptionExpanded: controller.isDescriptionExpanded,
                        onToggleDescription: () =>
                            controller.isDescriptionExpanded.toggle(),
                      )),
                ),
                const SizedBox(height: 16),
                // 视频标签区域，支持展开
                Obx(() {
                  final tags = controller.videoInfo.value?.tags;
                  if (tags != null && tags.isNotEmpty) {
                    return ExpandableTagsWidget(tags: tags);
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                const SizedBox(height: 16),
                // 点赞用户头像展示
                Obx(() {
                  final videoId = controller.videoInfo.value?.id;
                  if (videoId != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        height: 40,
                        child: LikeAvatarsWidget(mediaId: videoId, mediaType: MediaType.VIDEO,),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                const SizedBox(height: 16),
                // 点赞和评论按钮区域
                Obx(() {
                  final videoInfo = controller.videoInfo.value;
                  if (videoInfo != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                            spacing: 8,
                            children: [
                              LikeButtonWidget(
                                mediaId: videoInfo.id,
                                liked: videoInfo.liked ?? false,
                                likeCount: videoInfo.numLikes ?? 0,
                                onLike: (id) async {
                                  final result = await Get.find<VideoService>().likeVideo(id);
                                  return result.isSuccess;
                                },
                                onUnlike: (id) async {
                                  final result = await Get.find<VideoService>().unlikeVideo(id);
                                  return result.isSuccess;
                                },
                                onLikeChanged: (liked) {
                                  controller.videoInfo.value = controller.videoInfo.value?.copyWith(
                                    liked: liked,
                                    numLikes: (controller.videoInfo.value?.numLikes ?? 0) + (liked ? 1 : -1),
                                  );
                                },
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    final UserService userService = Get.find();
                                    if (!userService.isLogin) {
                                      showToastWidget(MDToastWidget(message: t.errors.pleaseLoginFirst, type: MDToastType.error));
                                      Get.toNamed(Routes.LOGIN);
                                      return;
                                    }
                                    showModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (context) => AddVideoToPlayListDialog(
                                        videoId: controller.videoInfo.value?.id ?? '',
                                      ), context: context,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.playlist_add),
                                        const SizedBox(width: 4),
                                        Text(slang.Translations.of(context).playList.myPlayList),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
              ],
            );
          } else {
            // 如果是全屏模式，则不显示详情内容
            return const SizedBox.shrink();
          }
        }),
      ],
    );
  }

  Widget _buildAuthorAvatar() {
    Widget avatar = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final user = controller.videoInfo.value?.user;
          if (user != null) {
            NaviService.navigateToAuthorProfilePage(user.username);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AvatarWidget(
          avatarUrl: controller.videoInfo.value?.user?.avatar?.avatarUrl,
          defaultAvatarUrl: CommonConstants.defaultAvatarUrl,
          headers: const {'referer': CommonConstants.iwaraBaseUrl},
          radius: 40,
          isPremium: controller.videoInfo.value?.user?.premium ?? false,
          isAdmin: controller.videoInfo.value?.user?.isAdmin ?? false,
        ),
      ),
    );

    if (controller.videoInfo.value?.user?.premium == true) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade200,
                Colors.blue.shade200,
                Colors.pink.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: avatar,
          ),
        ),
      );
    }

    return avatar;
  }

  Widget _buildAuthorNameButton() {
    final user = controller.videoInfo.value?.user;
    if (user?.premium == true) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            NaviService.navigateToAuthorProfilePage(user?.username ?? '');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.purple.shade300,
                    Colors.blue.shade300,
                    Colors.pink.shade300,
                  ],
                ).createShader(bounds),
                child: Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '@${user?.username ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          NaviService.navigateToAuthorProfilePage(user?.username ?? '');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '@${user?.username ?? ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildAuthorAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAuthorNameButton(),
          ),
          if (controller.videoInfo.value?.user != null)
            FollowButtonWidget(
              user: controller.videoInfo.value!.user!,
              onUserUpdated: (updatedUser) {
                controller.videoInfo.value = controller.videoInfo.value?.copyWith(
                  user: updatedUser,
                );
              },
            ),
        ],
      ),
    );
  }
}
