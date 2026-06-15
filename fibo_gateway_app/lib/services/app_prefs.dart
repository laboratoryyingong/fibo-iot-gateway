import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// App-wide user preferences, persisted on the current `_User` record so they
/// follow the account across devices. Loaded once after login; screens read the
/// values and call the setters to persist + notify.
class AppPrefs extends ChangeNotifier {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  static const _kNotifications = 'prefNotifications';
  static const _kTempUnit = 'prefTempUnit';

  bool notificationsEnabled = true;
  String temperatureUnit = 'C'; // 'C' | 'F'

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Reads the preferences off the current user. Safe to call repeatedly.
  Future<void> loadFromUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      notificationsEnabled = user.get<bool>(_kNotifications) ?? true;
      final unit = user.get<String>(_kTempUnit);
      temperatureUnit = (unit == 'F') ? 'F' : 'C';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (notificationsEnabled == value) return;
    notificationsEnabled = value;
    notifyListeners();
    await _persist(_kNotifications, value);
  }

  Future<void> setTemperatureUnit(String unit) async {
    final next = (unit == 'F') ? 'F' : 'C';
    if (temperatureUnit == next) return;
    temperatureUnit = next;
    notifyListeners();
    await _persist(_kTempUnit, next);
  }

  /// Converts a Celsius reading to the user's chosen unit and formats it.
  String formatTemperatureC(double celsius) {
    if (temperatureUnit == 'F') {
      return '${(celsius * 9 / 5 + 32).toStringAsFixed(1)}°F';
    }
    return '${celsius.toStringAsFixed(1)}°C';
  }

  Future<void> _persist(String key, Object value) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return;
    user.set(key, value);
    await user.save();
  }
}
