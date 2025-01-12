// To parse this JSON data, do
//
//     final mongoDbModerl = mongoDbModerlFromJson(jsonString);

import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

MongoDbModel mongoDbModelFromJson(String str) => MongoDbModel.fromJson(json.decode(str));

String mongoDbModelToJson(MongoDbModel data) => json.encode(data.toJson());

class MongoDbModel {
  ObjectId id;
  String firstname;
  String number;
  String address;

  MongoDbModel({
    required this.id,
    required this.firstname,
    required this.number,
    required this.address,
  });

  factory MongoDbModel.fromJson(Map<String, dynamic> json) => MongoDbModel(
    id: json["_id"],
    firstname: json["firstname"],
    number: json["number"],
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "firstname": firstname,
    "lastname": number,
    "address": address,
  };
}
