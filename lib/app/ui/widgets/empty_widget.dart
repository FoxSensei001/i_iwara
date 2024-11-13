import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final VoidCallback? onRefresh;
  final double? spacing;

  const EmptyWidget({
    super.key,
    this.message = '暂无数据',
    this.icon = Icons.inbox_outlined, // 默认使用inbox图标
    this.iconSize = 60,
    this.iconColor = Colors.grey,
    this.onRefresh,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标部分
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
            SizedBox(height: spacing),
          ],

          // 文字提示
          Text(
            message!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          // 刷新按钮
          if (onRefresh != null) ...[
            SizedBox(height: spacing),
            TextButton(
              onPressed: onRefresh,
              child: const Text('点击刷新'),
            ),
          ],
        ],
      ),
    );
  }
}