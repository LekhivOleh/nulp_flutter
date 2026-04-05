import 'package:my_project/data/local/key_value_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStorage implements KeyValueStorage {
  SharedPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> writeString({required String key, required String value}) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> readString({required String key}) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> remove({required String key}) async {
    await _prefs.remove(key);
  }
}
