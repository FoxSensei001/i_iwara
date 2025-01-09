import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/models/download/download_task.model.dart';
import 'package:i_iwara/app/models/download/download_task_ext_data.model.dart';
import 'package:i_iwara/app/services/download_service.dart';
import 'package:i_iwara/app/services/app_service.dart';
import 'package:i_iwara/app/ui/widgets/avatar_widget.dart';
import 'package:i_iwara/common/constants.dart';
import 'package:i_iwara/utils/logger_utils.dart';
import 'package:i_iwara/utils/image_utils.dart';
import 'package:path/path.dart' as path;
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:i_iwara/app/ui/pages/gallery_detail/widgets/horizontial_image_list.dart';
import 'package:i_iwara/i18n/strings.g.dart' as slang;

class GalleryDownloadTaskDetailPage extends StatelessWidget {
  final String taskId;

  const GalleryDownloadTaskDetailPage({super.key, required this.taskId});

  DownloadTask? get task => DownloadService.to.tasks[taskId];

  GalleryDownloadExtData? get galleryData {
    try {
      if (task?.extData?.type == 'gallery') {
        return GalleryDownloadExtData.fromJson(task!.extData!.data);
      }
    } catch (e) {
      LogUtils.e('解析图库下载任务数据失败', tag: 'GalleryDownloadTaskDetailPage', error: e);
    }
    return null;
  }

  // 检查图片是否已下载
  bool isImageDownloaded(String imagePath) {
    try {
      return File(imagePath).existsSync();
    } catch (e) {
      return false;
    }
  }

  // 构建图片菜单项
  List<MenuItem> _buildImageMenuItems(BuildContext context, ImageItem item) {
    final t = slang.Translations.of(context);
    final isLocalFile = item.data.url.startsWith('file://');

    return [
      if (!isLocalFile) ...[
        MenuItem(
          title: t.galleryDetail.copyLink,
          icon: Icons.copy,
          onTap: () => ImageUtils.copyLink(item),
        ),
        MenuItem(
          title: t.galleryDetail.copyImage,
          icon: Icons.copy,
          onTap: () => ImageUtils.copyImage(item),
        ),
      ],
      if (GetPlatform.isDesktop && !GetPlatform.isWeb)
        MenuItem(
          title: t.galleryDetail.saveAs,
          icon: Icons.download,
          onTap: () => ImageUtils.downloadImageForDesktop(item),
        ),
      if (!isLocalFile)
        MenuItem(
          title: t.galleryDetail.saveToAlbum,
          icon: Icons.save,
          onTap: () => ImageUtils.downloadImageForMobile(item),
        ),
    ];
  }

  // 处理图片点击事件
  void _onImageTap(BuildContext context, ImageItem item, List<ImageItem> imageItems) {
    int index = imageItems.indexWhere((element) => element.url == item.url);
    if (index == -1) {
      index = imageItems.indexWhere((element) => element.data.id == item.data.id);
    }
    NaviService.navigateToPhotoViewWrapper(
      imageItems: imageItems, 
      initialIndex: index,
      menuItemsBuilder: (context, item) => _buildImageMenuItems(context, item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = slang.Translations.of(context);
    final extData = galleryData;
    if (task == null || extData == null) {
      return Scaffold(
        body: Center(
          child: Text(t.download.errors.taskNotFoundOrDataError),
        ),
      );
    }

    // 格式化保存路径
    final savePath = path.normalize(task!.savePath);

    // 构建图片列表
    final List<ImageItem> imageItems = extData.imageList.map((imageInfo) {
      final imageId = imageInfo['id']!;
      final imageUrl = imageInfo['url']!;
      final imagePath = path.join(savePath, '$imageId${path.extension(imageUrl)}');
      final isDownloaded = isImageDownloaded(imagePath);

      return ImageItem(
        url: isDownloaded ? 'file://$imagePath' : imageUrl,
        data: ImageItemData(
          id: imageId,
          url: isDownloaded ? 'file://$imagePath' : imageUrl,
          originalUrl: isDownloaded ? 'file://$imagePath' : imageUrl,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.galleryDetail.galleryDetail),
        actions: [
          if (extData.id != null)
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: () => NaviService.navigateToGalleryDetailPage(extData.id!),
              tooltip: t.galleryDetail.viewGalleryDetail,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                extData.title ?? t.download.errors.unknown,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // 作者信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MouseRegion(
                cursor: extData.authorUsername != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: extData.authorUsername != null
                      ? () => NaviService.navigateToAuthorProfilePage(extData.authorUsername!)
                      : null,
                  child: Row(
                    children: [
                      AvatarWidget(
                        avatarUrl: extData.authorAvatar,
                        defaultAvatarUrl: CommonConstants.defaultAvatarUrl,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            extData.authorName ?? t.download.errors.unknown,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (extData.authorUsername != null)
                            Text(
                              '@${extData.authorUsername}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 下载状态
            Obx(() {
              final currentTask = DownloadService.to.tasks[taskId];
              if (currentTask == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.download.downloadStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: currentTask.status == DownloadStatus.completed
                          ? 1.0
                          : currentTask.totalBytes > 0
                              ? currentTask.downloadedBytes / currentTask.totalBytes
                              : null,
                    ),
                    const SizedBox(height: 8),
                    Text(_getStatusText(context, currentTask)),
                    if (currentTask.error != null)
                      Text(
                        currentTask.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // 图片网格
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.download.imageList,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final currentTask = DownloadService.to.tasks[taskId];
              if (currentTask == null) return const SizedBox.shrink();

              return LayoutBuilder(
                builder: (context, constraints) {
                  // 计算列数，最少两列
                  final columnCount = (constraints.maxWidth / 200).floor().clamp(2, 4); // 200 是每列的最小宽度

                  return WaterfallFlow.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: imageItems.length,
                    itemBuilder: (context, index) {
                      final item = imageItems[index];
                      final isDownloaded = item.url.startsWith('file://');

                      return Stack(
                        children: [
                          // 图片容器
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onImageTap(context, item, imageItems),
                                  child: isDownloaded
                                      ? Image.file(
                                          File(item.url.replaceFirst('file://', '')),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.error_outline),
                                          ),
                                        )
                                      : Image.network(
                                          item.url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.error_outline),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          // 状态指示器
                          if (!isDownloaded && currentTask.status == DownloadStatus.failed)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.white),
                                    onPressed: () {
                                      if (currentTask.status == DownloadStatus.failed) {
                                        final imageId = item.data.id;
                                        DownloadService.to.retryGalleryImageDownload(taskId, imageId);
                                      }
                                    },
                                    tooltip: t.download.retryDownload,
                                  ),
                                ),
                              ),
                            ),
                          // 下载状态指示器
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDownloaded ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isDownloaded ? t.download.downloaded : t.download.notDownloaded,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getStatusText(BuildContext context, DownloadTask task) {
    final t = slang.Translations.of(context);
    switch (task.status) {
      case DownloadStatus.pending:
        return t.download.waitingForDownload;
      case DownloadStatus.downloading:
        if (task.totalBytes > 0) {
          final progress =
              (task.downloadedBytes / task.totalBytes * 100).toStringAsFixed(1);
          // return '下载中 (${task.downloadedBytes}/${task.totalBytes}张 $progress%)';
          return t.download.downloadingProgressForImageProgress(downloaded: task.downloadedBytes, total: task.totalBytes, progress: progress);
        } else {
          // return '下载中 (${task.downloadedBytes}张)';
          return t.download.downloadingSingleImageProgress(downloaded: task.downloadedBytes);
        }
      case DownloadStatus.paused:
        if (task.totalBytes > 0) {
          final progress =
              (task.downloadedBytes / task.totalBytes * 100).toStringAsFixed(1);
          // return '已暂停 (${task.downloadedBytes}/${task.totalBytes}张 $progress%)';
          return t.download.pausedProgressForImageProgress(downloaded: task.downloadedBytes, total: task.totalBytes, progress: progress);
        } else {
          // return '已暂停 (已下载${task.downloadedBytes}张)';
          return t.download.pausedSingleImageProgress(downloaded: task.downloadedBytes);
        }
      case DownloadStatus.completed:
        // return '下载完成 (共${task.totalBytes}张)';
        return t.download.downloadedProgressForImageProgress(total: task.totalBytes);
      case DownloadStatus.failed:
        // return '下载失败';
        return t.download.errors.downloadFailed;
    }
  }
} 