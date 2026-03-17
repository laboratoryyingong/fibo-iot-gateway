import 'package:flutter/material.dart';

import '../services/mock_room_photo_catalog.dart';

@immutable
class HomeProfileScene {
  const HomeProfileScene({
    required this.id,
    required this.name,
    required this.emoji,
    required this.active,
  });

  final String id;
  final String name;
  final String emoji;
  final bool active;
}

@immutable
class HomeProfileSpace {
  const HomeProfileSpace({
    required this.id,
    required this.name,
    required this.onDevices,
    required this.totalDevices,
    required this.icons,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int onDevices;
  final int totalDevices;
  final List<IconData> icons;
  final String? imageUrl;
}

@immutable
class HomeProfileMember {
  const HomeProfileMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

@immutable
class HomeProfileItem {
  const HomeProfileItem({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerFirstName,
    required this.ownerLastName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.scenes,
    required this.spaces,
    required this.members,
  });

  final String id;
  final String name;
  final String location;
  final String ownerFirstName;
  final String ownerLastName;
  final String ownerEmail;
  final String ownerPhone;
  final List<HomeProfileScene> scenes;
  final List<HomeProfileSpace> spaces;
  final List<HomeProfileMember> members;

  String get ownerFullName => '$ownerFirstName $ownerLastName';

  HomeProfileItem copyWith({
    String? name,
    String? location,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerEmail,
    String? ownerPhone,
  }) {
    return HomeProfileItem(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      scenes: scenes,
      spaces: spaces,
      members: members,
    );
  }
}

class HomeProfileMockStore extends ChangeNotifier {
  HomeProfileMockStore._();

  static final HomeProfileMockStore instance = HomeProfileMockStore._()
    .._init();

  final List<HomeProfileItem> _profiles = [];
  String _selectedProfileId = 'home-1';

  void _init() {
    if (_profiles.isNotEmpty) return;
    _profiles.addAll(_seedProfiles());
  }

  List<HomeProfileItem> get profiles => List.unmodifiable(_profiles);

  String get selectedProfileId => _selectedProfileId;

  HomeProfileItem get selectedProfile {
    return _profiles.firstWhere(
      (profile) => profile.id == _selectedProfileId,
      orElse: () => _profiles.first,
    );
  }

  HomeProfileItem? findProfileById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  void selectProfile(String profileId) {
    if (_selectedProfileId == profileId) return;
    if (_profiles.every((profile) => profile.id != profileId)) return;
    _selectedProfileId = profileId;
    notifyListeners();
  }

  void updateProfile({
    required String profileId,
    required String name,
    required String location,
    required String ownerFirstName,
    required String ownerLastName,
    required String ownerEmail,
    required String ownerPhone,
  }) {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index < 0) return;
    _profiles[index] = _profiles[index].copyWith(
      name: name.trim(),
      location: location.trim(),
      ownerFirstName: ownerFirstName.trim(),
      ownerLastName: ownerLastName.trim(),
      ownerEmail: ownerEmail.trim(),
      ownerPhone: ownerPhone.trim(),
    );
    notifyListeners();
  }

  List<HomeProfileItem> _seedProfiles() {
    return const [
      HomeProfileItem(
        id: 'home-1',
        name: 'Riverside Home',
        location: 'North Adelaide',
        ownerFirstName: 'Cameron',
        ownerLastName: 'Edwards',
        ownerEmail: 'cameron@gmail.com',
        ownerPhone: '+61 412 555 801',
        scenes: [
          HomeProfileScene(
            id: 'scene-1',
            name: 'Mornin’',
            emoji: '☀️',
            active: true,
          ),
          HomeProfileScene(
            id: 'scene-2',
            name: 'Night',
            emoji: '🌗',
            active: false,
          ),
          HomeProfileScene(
            id: 'scene-3',
            name: 'Music',
            emoji: '🥁',
            active: false,
          ),
          HomeProfileScene(
            id: 'scene-4',
            name: 'Movie',
            emoji: '🍿',
            active: false,
          ),
          HomeProfileScene(
            id: 'scene-5',
            name: 'Leave',
            emoji: '🔒',
            active: false,
          ),
        ],
        spaces: [
          HomeProfileSpace(
            id: 'space-1',
            name: 'Living Room',
            onDevices: 2,
            totalDevices: 5,
            imageUrl: kLivingRoomPhotoUrl,
            icons: [
              Icons.lightbulb_outline,
              Icons.router_outlined,
              Icons.thermostat_outlined,
              Icons.wifi_outlined,
            ],
          ),
          HomeProfileSpace(
            id: 'space-2',
            name: 'Bedroom',
            onDevices: 0,
            totalDevices: 4,
            imageUrl: kBedroomPhotoUrl,
            icons: [
              Icons.bed_outlined,
              Icons.air_outlined,
              Icons.sensors_outlined,
              Icons.lightbulb_outline,
            ],
          ),
          HomeProfileSpace(
            id: 'space-3',
            name: 'Kitchen',
            onDevices: 3,
            totalDevices: 6,
            imageUrl: kKitchenPhotoUrl,
            icons: [
              Icons.kitchen_outlined,
              Icons.microwave_outlined,
              Icons.wifi_outlined,
              Icons.lightbulb_outline,
            ],
          ),
        ],
        members: [
          HomeProfileMember(
            id: 'member-1',
            name: 'Guy Hawkins',
            email: 'guy@fibo.mock',
            role: 'Household',
          ),
          HomeProfileMember(
            id: 'member-2',
            name: 'Bessie Cooper',
            email: 'bessie@fibo.mock',
            role: 'Household',
          ),
          HomeProfileMember(
            id: 'member-3',
            name: 'Eleanor Pena',
            email: 'eleanor@fibo.mock',
            role: 'Guest',
          ),
        ],
      ),
      HomeProfileItem(
        id: 'home-2',
        name: 'City Apartment',
        location: 'Adelaide CBD',
        ownerFirstName: 'Nora',
        ownerLastName: 'Li',
        ownerEmail: 'nora@fibo.mock',
        ownerPhone: '+61 412 111 909',
        scenes: [
          HomeProfileScene(
            id: 'scene-a',
            name: 'Wake Up',
            emoji: '🌤️',
            active: true,
          ),
          HomeProfileScene(
            id: 'scene-b',
            name: 'Away',
            emoji: '🧳',
            active: false,
          ),
        ],
        spaces: [
          HomeProfileSpace(
            id: 'space-a',
            name: 'Studio',
            onDevices: 4,
            totalDevices: 7,
            imageUrl: kOfficePhotoUrl,
            icons: [
              Icons.lightbulb_outline,
              Icons.speaker_outlined,
              Icons.router_outlined,
              Icons.tv_outlined,
            ],
          ),
          HomeProfileSpace(
            id: 'space-b',
            name: 'Balcony',
            onDevices: 1,
            totalDevices: 2,
            imageUrl: kBalconyPhotoUrl,
            icons: [Icons.wb_sunny_outlined, Icons.camera_outlined],
          ),
        ],
        members: [
          HomeProfileMember(
            id: 'member-a',
            name: 'Nora Li',
            email: 'nora@fibo.mock',
            role: 'Owner',
          ),
          HomeProfileMember(
            id: 'member-b',
            name: 'Kevin Hu',
            email: 'kevin@fibo.mock',
            role: 'Household',
          ),
        ],
      ),
      HomeProfileItem(
        id: 'home-3',
        name: 'Beach House',
        location: 'Glenelg',
        ownerFirstName: 'Ivy',
        ownerLastName: 'Sun',
        ownerEmail: 'ivy@fibo.mock',
        ownerPhone: '+61 412 333 222',
        scenes: [
          HomeProfileScene(
            id: 'scene-x',
            name: 'Sunset',
            emoji: '🌅',
            active: true,
          ),
          HomeProfileScene(
            id: 'scene-y',
            name: 'Sleep',
            emoji: '🌙',
            active: false,
          ),
        ],
        spaces: [
          HomeProfileSpace(
            id: 'space-x',
            name: 'Outdoor Patio',
            onDevices: 2,
            totalDevices: 3,
            imageUrl: kPatioPhotoUrl,
            icons: [
              Icons.deck_outlined,
              Icons.lightbulb_outline,
              Icons.camera_alt_outlined,
            ],
          ),
          HomeProfileSpace(
            id: 'space-y',
            name: 'Guest Room',
            onDevices: 0,
            totalDevices: 2,
            imageUrl: kBedroomPhotoUrl,
            icons: [Icons.bed_outlined, Icons.thermostat_outlined],
          ),
        ],
        members: [
          HomeProfileMember(
            id: 'member-x',
            name: 'Ivy Sun',
            email: 'ivy@fibo.mock',
            role: 'Owner',
          ),
        ],
      ),
    ];
  }
}
