import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

enum AppUserRole { installer, user }

const String kUserTypeUser = 'user';
const String kUserTypeInstaller = 'installer';

AppUserRole resolveUserRole(ParseUser user) {
  final rawType = _resolveRawUserType(user);

  if (rawType == kUserTypeUser) return AppUserRole.user;
  if (rawType == kUserTypeInstaller) return AppUserRole.installer;

  // Backward compatibility for historical account values.
  if (rawType == 'admin') return AppUserRole.installer;

  final isAdmin = user.get<bool>('isAdmin');
  if (isAdmin == false) return AppUserRole.user;

  return AppUserRole.installer;
}

String resolveHomeRoute(ParseUser user) {
  return '/home';
}

String _resolveRawUserType(ParseUser user) {
  // Use userType as the single source of truth.
  final userType = user.get<String>('userType');
  if (userType != null && userType.trim().isNotEmpty) {
    return userType.toLowerCase().trim();
  }

  // Legacy fields for old records only.
  return (user.get<String>('type') ??
          user.get<String>('accountType') ??
          user.get<String>('role') ??
          user.get<String>('userRole') ??
          user.get<String>('appRole') ??
          '')
      .toLowerCase()
      .trim();
}
