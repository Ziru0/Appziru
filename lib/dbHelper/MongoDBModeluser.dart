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
  String? driverId; // For drivers
  String? passengerId; // For passengers

  Map<String, dynamic>? coordinates; // GeoJSON format for coordinates
  double? distance; // Added field
  double? duration; // Added field
  double? cost; // Added field

  MongoDbModelUser({
    required this.id,
    this.email,
    this.firebaseId,
    this.fullname,
    this.number,
    this.address,
    this.role,
    String? driverId,
    String? passengerId,
    this.coordinates,
    this.distance, // Added
    this.duration, // Added
    this.cost, // Added
  })
      : driverId = driverId ?? id.oid,
        passengerId = passengerId ?? id.oid;

  factory MongoDbModelUser.fromJson(Map<String, dynamic> json) {
    // Ensure _id is an ObjectId and handle it gracefully
    ObjectId objectId;
    if (json["_id"] is ObjectId) {
      objectId = json["_id"];
    } else if (json["_id"] is String) {
      objectId = ObjectId.fromHexString(json["_id"]);
    } else {
      throw FormatException("Invalid _id format in the provided JSON.");
    }

    return MongoDbModelUser(
      id: objectId,
      email: json["email"],
      firebaseId: json["firebaseId"],
      fullname: json["fullname"],
      number: json["number"],
      address: json["address"],
      role: json["role"],
      driverId: json["driverId"] ?? objectId.oid,
      passengerId: json["passengerId"] ?? objectId.oid,
      coordinates: json["coordinates"],
      distance: json["distance"]?.toDouble(),
      duration: json["duration"]?.toDouble(),
      cost: json["cost"]?.toDouble(),
    );
  }

  get profileImage => null;

  Map<String, dynamic> toJson() =>
      {
        "_id": id.toHexString(), // Convert ObjectId to String
        "email": email,
        "firebaseId": firebaseId,
        "fullname": fullname,
        "number": number,
        "address": address,
        "role": role,
        "driverId": driverId,
        "passengerId": passengerId,
        "coordinates": coordinates,
        "distance": distance,
        "duration": duration,
        "cost": cost,
      };
}
