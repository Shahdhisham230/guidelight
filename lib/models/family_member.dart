
class FamilyMember {
  final int id;
  final String name;
  final bool isSafe;
  final bool deviceConnected;
  final String lastUpdate;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.isSafe,
    required this.deviceConnected,
    required this.lastUpdate,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      isSafe: json['is_safe'],
      deviceConnected: json['device_connected'],
      lastUpdate: json['last_update'],
    );
  }
}

