import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import '../../common/constants.dart';
import '../../utils/logger_utils.dart';

Future<CommonDatabase> openSqliteDb() async {
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String appDirPath =
      join(documentsDirectory.path, CommonConstants.applicationName);
  String path = join(appDirPath, "i_iwara.db");
  LogUtils.i('数据库路径：$path', 'DatabaseService');
  return sqlite3.open(path);
}