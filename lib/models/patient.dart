class PersonalInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? photo;
  final String? dateOfBirth;
  final String? gender;

  PersonalInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.photo,
    this.dateOfBirth,
    this.gender,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      photo: json['photo'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
    );
  }
}

class Patient {
  final String id;
  final PersonalInfo personalInfo;

  Patient({
    required this.id,
    required this.personalInfo,
  });

  String get fullName => '${personalInfo.firstName} ${personalInfo.lastName}';

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      personalInfo: PersonalInfo.fromJson(json['personalInfo']),
    );
  }
}
