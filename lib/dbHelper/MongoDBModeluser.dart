import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

MongoDbModelUser mongoDbModelFromJson(String str) {
  try {
    final jsonData = json.decode(str);
    return MongoDbModelUser.fromJson(jsonData);
  } catch (e) {
    throw FormatException("Error parsing JSON: $e");
  }
}

String mongoDbModelToJson(MongoDbModelUser data) => json.encode(data.toJson());

class MongoDbModelUser {
  ObjectId id;
  String? email;
  String? firebaseId;
  String? fullname;
  String? number;
  String? address;
  String? role;
  Map<String, dynamic>? coordinates; // GeoJSON format for coordinates

  MongoDbModelUser({
    required this.id,
    this.email,
    this.firebaseId,
    this.fullname,
    this.number,
    this.address,
    this.role,
    this.coordinates,
  });

  factory MongoDbModelUser.fromJson(Map<String, dynamic> json) {
    if (json["_id"] == null) {
      throw FormatException("Missing _id in the provided JSON.");
    }

    return MongoDbModelUser(
      id: json["_id"],
      email: json["email"],
      firebaseId: json["firebaseId"],
      fullname: json["fullname"],
      number: json["number"],
      address: json["address"],
      role: json["role"],
      coordinates: json["coordinates"], // Parse coordinates from JSON
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "email": email,
    "firebaseId": firebaseId,
    "fullname": fullname,
    "number": number,
    "address": address,
    "role": role,
    "coordinates": coordinates, // Include coordinates in JSON
  };
}

