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
  double? topLevelLatitude; // To store latitude if it's a top-level field
  double? topLevelLongitude; // To store longitude if it's a top-level field
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
    this.topLevelLatitude,
    this.topLevelLongitude,
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

    // Helper function to safely convert to hex string
    String? _safeObjectIdToString(dynamic value) {
      if (value is ObjectId) {
        return value.toHexString();
      }
      return value as String?; // If it's already a String or null, cast it
    }

    return MongoDbModelUser(
      id: objectId,
      email: json["email"],
      firebaseId: json["firebaseId"],
      fullname: json["fullname"],
      number: json["number"],
      address: json["address"],
      role: json["role"],
      driverId: _safeObjectIdToString(json["driverId"]) ?? objectId.oid,
      passengerId: _safeObjectIdToString(json["passengerId"]) ?? objectId.oid,
      coordinates: json["coordinates"],
      topLevelLatitude: json["latitude"]?.toDouble(), // Capture top-level latitude
      topLevelLongitude: json["longitude"]?.toDouble(), // Capture top-level longitude
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
        "latitude": topLevelLatitude, // Include top-level latitude in toJson
        "longitude": topLevelLongitude, // Include top-level longitude in toJson
        "distance": distance,
        "duration": duration,
        "cost": cost,
      };

  double? get latitude {
    // First check if top-level latitude exists
    if (topLevelLatitude != null) {
      return topLevelLatitude;
    }
    // If not, check for the nested coordinates structure
    if (coordinates != null &&
        coordinates!.containsKey("coordinates") &&
        coordinates!["coordinates"] is List &&
        coordinates!["coordinates"].length == 2) {
      return (coordinates!["coordinates"][1] as num?)?.toDouble(); // Latitude is second
    }
    return null;
  }

  double? get longitude {
    // First check if top-level longitude exists
    if (topLevelLongitude != null) {
      return topLevelLongitude;
    }
    // If not, check for the nested coordinates structure
    if (coordinates != null &&
        coordinates!.containsKey("coordinates") &&
        coordinates!["coordinates"] is List &&
        coordinates!["coordinates"].length == 2) {
      return (coordinates!["coordinates"][0] as num?)?.toDouble(); // Longitude is first
    }
    return null;
  }
}