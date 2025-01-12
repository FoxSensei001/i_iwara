import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_iwara/app/services/config_service.dart';
import 'package:i_iwara/common/constants.dart';
import 'package:i_iwara/i18n/strings.g.dart' as slang;

class AppSettingsPage extends StatelessWidget {
  final bool isWideScreen;

  const AppSettingsPage({super.key, this.isWideScreen = false});

  @override
  Widget build(BuildContext context) {
    final t = slang.Translations.of(context);
    final configService = Get.find<ConfigService>();

    return Scaffold(
      appBar: isWideScreen
          ? null
          : AppBar(
              title: Text(slang.t.settings.appSettings,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              elevation: 2,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              iconTheme: IconThemeData(color: Get.isDarkMode ? Colors.white : null),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    slang.t.settings.history,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Obx(
                  () => SwitchListTile(
                    title: Text(slang.t.settings.autoRecordHistory),
                    subtitle: Text(slang.t.settings.autoRecordHistoryDesc),
                    value: configService[ConfigService.AUTO_RECORD_HISTORY_KEY],
                    onChanged: (value) {
                      configService[ConfigService.AUTO_RECORD_HISTORY_KEY] = value;
                      CommonConstants.enableHistory = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 