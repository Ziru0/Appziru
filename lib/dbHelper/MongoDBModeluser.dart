// To parse this JSON data, do
//
//     final mongoDbModerl = mongoDbModerlFromJson(jsonString);

import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

MongoDbModelUser mongoDbModelFromJson(String str) => MongoDbModelUser.fromJson(json.decode(str));

String mongoDbModelToJson(MongoDbModelUser data) => json.encode(data.toJson());

class MongoDbModelUser {
  ObjectId id;
  String? email;
  String? firebaseId;
  String? fullname;
  String? number;
  String? address;

  MongoDbModelUser({
    required this.id,
    this.email,
    this.firebaseId,
    this.fullname,
    this.number,
    this.address,
  });

  factory MongoDbModelUser.fromJson(Map<String, dynamic> json) => MongoDbModelUser(
    id: json["_id"],
    email: json["email"],
    firebaseId: json["firebaseId"],
    fullname: json["fullname"],
    number: json["number"],
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "email": email,
    "firebaseId": firebaseId,
    "fullname": fullname,
    "lastname": number,
    "address": address,
  };
}
