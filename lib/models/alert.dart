
enum AlertType {
  danger,
  assistance,
}


class Alert {

  final int id;

  final AlertType type;

  final String? objectName;

  final double? distance;

  final String message;

  final String time;


  const Alert({
    required this.id,
    required this.type,
    this.objectName,
    this.distance,
    required this.message,
    required this.time,
  });


  factory Alert.fromJson(Map<String, dynamic> json) {

    return Alert(
      id: json['id'],

      type: json['alert_type'] == 'danger'
          ? AlertType.danger
          : AlertType.assistance,

      objectName: json['object_name'],

      distance: json['distance'] != null
          ? double.tryParse(
              json['distance'].toString(),
            )
          : null,

      message: json['message'] ?? '',

      time: json['created_at'] ?? '',
    );
  }
}

