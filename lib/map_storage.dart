import 'dart:convert';
import 'dart:io';

import 'models.dart';

class MapStorage {
  static MapData load(String path) {
    final file = File(path);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return MapData.fromJson(json);
  }

  static void save(String path, MapData map) {
    final file = File(path);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map.toJson()));
  }
}
