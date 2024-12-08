import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/services/app_service.dart';

import '../../../common/constants.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class GlobalDrawerColumns extends StatelessWidget {
  GlobalDrawerColumns({super.key});

  final UserService userService = Get.find();
  final AuthService authService = Get.find();
  final AppService appService = Get.find();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => _buildHeader(context, appService)),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildMenuItem(Icons.settings, '设置', () {
                AppService.switchGlobalDrawer();
                Get.toNamed(Routes.SETTINGS_PAGE);
              }),
              // 日历
              _buildMenuItem(Icons.calendar_today, '戒律签到', () {
                NaviService.navigateToSignInPage();
                AppService.switchGlobalDrawer();
              }),
              // 播放列表
              _buildMenuItem(Icons.playlist_play, '播放列表', () {
                if (userService.isLogin) {
                  NaviService.navigateToPlayListPage(
                      userService.currentUser.value!.id,
                      isMine: true);
                  AppService.switchGlobalDrawer();
                } else {
                  Get.snackbar('错误', '请先登录');
                }
              }),
              // 最爱
              _buildMenuItem(Icons.favorite, '最爱', () {
                if (userService.isLogin) {
                  NaviService.navigateToFavoritePage();
                  AppService.switchGlobalDrawer();
                } else {
                  Get.snackbar('错误', '请先登录');
                }
              }),
              // 关于
              _buildMenuItem(Icons.info, '关于', () {
                userService.fetchUserProfile();
                Get.snackbar('操作', '你点击了关于');
              }),
              Obx(() => userService.isLogin
                  ? Column(
                      children: [
                        const Divider(),
                        _buildMenuItem(Icons.exit_to_app, '退出',
                            () => _showLogoutDialog(appService)),
                      ],
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppService globalDrawerService) {
    return GestureDetector(
      onTap: () {
        if (!userService.isLogin) {
          AppService.switchGlobalDrawer();
          Get.toNamed(
            Routes.LOGIN,
          );
        } else {
          AppService.switchGlobalDrawer();
          NaviService.navigateToAuthorProfilePage(
              userService.currentUser.value!.username);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.paddingOf(context).top + 16, 16, 16),
        decoration: BoxDecoration(
          color: Get.theme.primaryColor,
          image: DecorationImage(
            image: const CachedNetworkImageProvider(
              CommonConstants.defaultAvatarUrl,
              headers: {'referer': CommonConstants.iwaraBaseUrl},
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userService.isLogin
                      ? userService.currentUser.value!.name
                      : '未登录',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userService.isLogin
                      ? '@${userService.currentUser.value!.username}'
                      : '点击此处登录',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: userService.userAvatar,
        httpHeaders: const {'referer': CommonConstants.iwaraBaseUrl},
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Get.theme.primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(AppService globalDrawerService) {
    AppService.switchGlobalDrawer();
    showDialog(
      context: Get.context!,
      builder: (context) => LogoutDialog(userService: userService),
    );
  }
}

class LogoutDialog extends StatelessWidget {
  final UserService userService;

  const LogoutDialog({required this.userService, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('退出'),
      content: const Text('你确定要退出吗？'),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('确定'),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await userService.logout();
              Get.snackbar('操作', '你已退出');
            } catch (e) {
              Get.snackbar('错误', '退出失败: $e');
            }
          },
        ),
      ],
    );
  }
}
