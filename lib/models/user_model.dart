class AppUser {
  final String uid;
  String firstName;
  String? middleName;
  String lastName;
  String username;
  //List<String> friendUIDs;
  String? profileImageUrl;
  String? phoneNumber;
  bool isPrivate;
  String email;
  String? location;
  List<String>? interests;
  List<String>? travelStyles;

  AppUser({
    required this.uid,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.username,
    //required this.friendUIDs,
    this.profileImageUrl,
    this.phoneNumber,
    required this.isPrivate,
    required this.email,
    this.location,
    this.interests,
    this.travelStyles,
  });

  AppUser copyWith({
    String? uid,
    String? username,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phoneNumber,
    String? location,
    String? profileImageUrl,
    List<String>? interests,
    List<String>? travelStyles,
    bool? isPrivate,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interests: interests ?? this.interests,
      travelStyles: travelStyles ?? this.travelStyles,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      username: json['username'],
      //friendUIDs: List<String>.from(json['friendUIDs'] ?? []),
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber'],
      isPrivate: json['isPrivate'] ?? false,
      email: json['email'],
      location: json['location'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      travelStyles: json['travelStyles'] != null ? List<String>.from(json['travelStyles']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'username': username,
      //'friendUIDs': friendUIDs,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'isPrivate': isPrivate,
      'email': email,
      'location': location,
      'interests': interests,
      'travelStyles': travelStyles,
    };
  }

}
