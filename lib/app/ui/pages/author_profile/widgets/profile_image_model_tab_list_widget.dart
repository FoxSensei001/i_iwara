import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:i_iwara/utils/logger_utils.dart';

import '../../../../models/image.model.dart';
import '../../popular_media_list/widgets/image_model_tile_list_item_widget.dart';
import '../controllers/userz_image_model_list_controller.dart';


class ProfileImageModelTabListWidget extends StatefulWidget {
  final String tabKey;
  final TabController tc;
  final String userId;
  final Function({int? count})? onFetchFinished;

  const ProfileImageModelTabListWidget({
    super.key,
    required this.tabKey,
    required this.tc,
    required this.userId,
    this.onFetchFinished,
  });

  @override
  _ProfileImageModelTabListWidgetState createState() =>
      _ProfileImageModelTabListWidgetState();
}

class _ProfileImageModelTabListWidgetState extends State<ProfileImageModelTabListWidget>
    with AutomaticKeepAliveClientMixin {
  final String uniqueKey = UniqueKey().toString();
  late UserzImageModelListController imageModelListController;

  String getSort() {
    switch (widget.tc.index) {
      case 0:
        return 'date';
      case 1:
        return 'likes';
      case 2:
        return 'views';
      case 3:
        return 'popularity';
      case 4:
        return 'trending';
      default:
        return 'date';
    }
  }

  @override
  void initState() {
    super.initState();
    widget.tc.addListener(_handleTabSelection);
    imageModelListController = Get.put(
      UserzImageModelListController(onFetchFinished: widget.onFetchFinished),
      tag: uniqueKey,
    );
    LogUtils.d('[详情图片列表] 初始化，当前的用户ID是：${widget.userId}, 排序是：${getSort()}');
    imageModelListController.userId.value = widget.userId;
    imageModelListController.sort.value = getSort();
  }

  @override
  void dispose() {
    widget.tc.removeListener(_handleTabSelection);
    Get.delete<UserzImageModelListController>(tag: uniqueKey);
    super.dispose();
  }

  // 获取当前选择的
  void _handleTabSelection() {
    if (widget.tc.indexIsChanging) {
      imageModelListController.sort.value = getSort();

      LogUtils.d('[详情图片列表] 切换排序，当前选择的是：${widget.tc.index}, 排序是：${getSort()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final TabBar secondaryTabBar = TabBar(
      isScrollable: true,
      physics: const NeverScrollableScrollPhysics(),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      padding: EdgeInsets.zero,
      controller: widget.tc,
      tabs: const <Tab>[
        // date
        Tab(icon: Icon(Icons.calendar_today)),
        // likes
        Tab(icon: Icon(Icons.favorite)),
        // views
        Tab(icon: Icon(Icons.remove_red_eye)),
        // popularity
        Tab(icon: Icon(Icons.star)),
        // trending
        Tab(icon: Icon(Icons.trending_up)),
      ],
    );
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: secondaryTabBar,
            ),
            // 一个刷新按钮
            Obx(() => imageModelListController.isLoading.value
                ? const IconButton(icon: Icon(Icons.refresh), onPressed: null)
                .animate(
              onPlay: (controller) => controller.repeat(), // loop
            )
                .addEffect(
              const RotateEffect(
                duration: Duration(seconds: 1),
                curve: Curves.linear,
              ),
            )
                : IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                imageModelListController.fetchImageModels(refresh: true);
              },
            )),
            const SizedBox(width: 16),
          ],
        ),
        Expanded(
          child: Obx(() => _buildImageModelList()),
        )
      ],
    );
  }

  // 构建图片列表视图
  Widget _buildImageModelList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!imageModelListController.isLoading.value &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 100 &&
            imageModelListController.hasMore.value) {
          // 接近底部时加载更多评论
          imageModelListController.fetchImageModels();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: imageModelListController.imageModels.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index < imageModelListController.imageModels.length) {
            ImageModel imageModel = imageModelListController.imageModels[index];
            return ImageModelTileListItem(imageModel: imageModel);
          } else {
            // 最后一项显示加载指示器或结束提示
            return _buildLoadMoreIndicator();
          }
        },
      ),
    );
  }

  // 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    if (imageModelListController.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            '没有更多图片了',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}