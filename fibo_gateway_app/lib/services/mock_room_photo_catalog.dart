const String kLivingRoomPhotoUrl = 'assets/images/spaces/living-room.jpg';
const String kBedroomPhotoUrl = 'assets/images/spaces/bedroom.jpg';
const String kKitchenPhotoUrl = 'assets/images/spaces/kitchen.jpg';
const String kOfficePhotoUrl = 'assets/images/spaces/office.jpg';
const String kBalconyPhotoUrl = 'assets/images/spaces/balcony.jpg';
const String kPatioPhotoUrl = 'assets/images/spaces/patio.jpg';

String? roomPhotoUrlForName(String roomName) {
  final normalized = roomName.trim().toLowerCase();

  if (normalized.contains('living')) return kLivingRoomPhotoUrl;
  if (normalized.contains('bed') || normalized.contains('guest')) {
    return kBedroomPhotoUrl;
  }
  if (normalized.contains('kitchen')) return kKitchenPhotoUrl;
  if (normalized.contains('office') || normalized.contains('studio')) {
    return kOfficePhotoUrl;
  }
  if (normalized.contains('balcony')) return kBalconyPhotoUrl;
  if (normalized.contains('patio')) return kPatioPhotoUrl;

  return null;
}
