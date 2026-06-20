import 'package:flutter/material.dart';

/// Maps a device profile to a display icon (mirrors the phone app).
IconData iconForProfile(String profile) {
  switch (profile) {
    case 'color_light':
    case 'dimmable_light':
      return Icons.lightbulb_outline;
    case 'onoff_actuator':
      return Icons.toggle_on_outlined;
    case 'curtain':
      return Icons.blinds_outlined;
    case 'door_lock':
      return Icons.lock_outline;
    case 'siren_actuator':
      return Icons.notifications_active_outlined;
    case 'smoke_alarm':
      return Icons.local_fire_department_outlined;
    case 'ias_sensor':
      return Icons.directions_walk_outlined;
    case 'mmwave_sensor':
      return Icons.sensors_outlined;
    case 'multi_sensor':
      return Icons.thermostat_outlined;
    case 'button_remote':
      return Icons.radio_button_checked;
    default:
      return Icons.devices_other_outlined;
  }
}
