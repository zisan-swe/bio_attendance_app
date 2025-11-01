import 'package:shared_preferences/shared_preferences.dart';
import '../db/setting_seeder.dart';

class AutoSettingSeeder {
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool('settings_seeded') ?? false;

    if (!alreadySeeded) {
      final seeder = SettingSeeder();
      await seeder.seedDummySettings();
      await prefs.setBool('settings_seeded', true);
    }
  }
}
