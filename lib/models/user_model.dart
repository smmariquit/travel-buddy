class AppUser {
  final String uid;
  String firstName;
  String? middleName;
  String lastName;
  String username;
  List<String>? friendUIDs;
  List<String>? sentFriendRequests; // UIDs of users to whom requests were sent
  List<String>? receivedFriendRequests; // UIDs of users who sent requests
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
    this.friendUIDs,
    this.sentFriendRequests,
    this.receivedFriendRequests,
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
    List<String>? friendUIDs,
    List<String>? sentFriendRequests,
    List<String>? receivedFriendRequests,
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
      friendUIDs: friendUIDs ?? this.friendUIDs,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      receivedFriendRequests: receivedFriendRequests ?? this.receivedFriendRequests,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      username: json['username'],
      friendUIDs: json['friendUIDs'] != null ? List<String>.from(json['friendUIDs']) : [],
      sentFriendRequests: json['sentFriendRequests'] != null ? List<String>.from(json['sentFriendRequests']) : [],
      receivedFriendRequests: json['receivedFriendRequests'] != null ? List<String>.from(json['receivedFriendRequests']) : [],
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
      'friendUIDs': friendUIDs,
      'sentFriendRequests': sentFriendRequests,
      'receivedFriendRequests': receivedFriendRequests,
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