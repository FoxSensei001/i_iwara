import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/ui/pages/friends/controllers/friends_controller.dart';
import 'package:i_iwara/app/ui/pages/friends/widgets/friend_list.dart';
import 'package:i_iwara/app/ui/pages/friends/widgets/friend_request_list.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late FriendsController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(FriendsController());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
      // 切换标签时刷新列表
      _controller.refreshCurrentTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    // 判断是否是移动设备
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友列表'),
        actions: [
          Obx(
            () {
              final bool isLoading = _tabController.index == 0
                  ? _controller.isLoadingFriends.value
                  : _controller.isLoadingRequests.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          IconButton(
            onPressed: () =>
                _controller.refreshCurrentTab(_tabController.index),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            width: isMobile ? screenWidth : 400,
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : (screenWidth - 400) / 2,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(isMobile ? 0 : 25),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TabBar(
                  controller: _tabController,
                  // 使用Material 3风格的指示器
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 0 : 25),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  // 标签样式
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  // 取消标签的内边距，让整个区域都可点击
                  padding: EdgeInsets.zero,
                  tabs: [
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people),
                            SizedBox(width: 8),
                            Text('好友'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('请求'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FriendList(
            scrollController: _controller.friendListScrollController,
          ),
          FriendRequestList(
            scrollController: _controller.requestListScrollController,
          ),
        ],
      ),
    );
  }
}