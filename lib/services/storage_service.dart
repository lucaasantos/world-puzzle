import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  const StorageService(this.preferences);
  final SharedPreferences preferences;

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  String? read(String key) => preferences.getString(key);
  Future<bool> write(String key, String value) =>
      preferences.setString(key, value);
}
