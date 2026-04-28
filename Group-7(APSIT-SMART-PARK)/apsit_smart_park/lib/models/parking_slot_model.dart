enum SlotStatus { available, occupied, reserved, faculty }

enum VehicleType { car, bike }

/// Parking zone within the APSIT campus layout.
enum ParkingZone {
  staffCar,      // Left — 30 staff car slots
  studentBike,   // Right-top — 100 student bike slots
  staffBike,     // Right-bottom — 25 staff bike slots
  common,        // Bottom — 100 common slots (cars & bikes)
}

class ParkingSlotModel {
  final String id;
  final SlotStatus status;
  final VehicleType vehicleType;
  final ParkingZone zone;
  final String? reservedBy; // uid of user who reserved

  const ParkingSlotModel({
    required this.id,
    required this.status,
    required this.vehicleType,
    required this.zone,
    this.reservedBy,
  });

  factory ParkingSlotModel.fromMap(String id, Map<String, dynamic> map) {
    return ParkingSlotModel(
      id: id,
      status: _parseStatus(map['status'] as String? ?? 'available'),
      vehicleType: (map['vehicleType'] as String? ?? 'car') == 'bike'
          ? VehicleType.bike
          : VehicleType.car,
      zone: _parseZone(map['zone'] as String? ?? ''),
      reservedBy: map['reservedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': _statusString(status),
        'vehicleType': vehicleType == VehicleType.bike ? 'bike' : 'car',
        'zone': _zoneString(zone),
        'reservedBy': reservedBy,
      };

  static SlotStatus _parseStatus(String s) {
    switch (s) {
      case 'occupied':
        return SlotStatus.occupied;
      case 'reserved':
        return SlotStatus.reserved;
      case 'faculty':
        return SlotStatus.faculty;
      default:
        return SlotStatus.available;
    }
  }

  static String _statusString(SlotStatus s) {
    switch (s) {
      case SlotStatus.occupied:
        return 'occupied';
      case SlotStatus.reserved:
        return 'reserved';
      case SlotStatus.faculty:
        return 'faculty';
      default:
        return 'available';
    }
  }

  static ParkingZone _parseZone(String z) {
    switch (z) {
      case 'staff_car':
        return ParkingZone.staffCar;
      case 'student_bike':
        return ParkingZone.studentBike;
      case 'staff_bike':
        return ParkingZone.staffBike;
      case 'common':
        return ParkingZone.common;
      default:
        // Legacy slots without zone default to common
        return ParkingZone.common;
    }
  }

  static String _zoneString(ParkingZone z) {
    switch (z) {
      case ParkingZone.staffCar:
        return 'staff_car';
      case ParkingZone.studentBike:
        return 'student_bike';
      case ParkingZone.staffBike:
        return 'staff_bike';
      case ParkingZone.common:
        return 'common';
    }
  }
}
