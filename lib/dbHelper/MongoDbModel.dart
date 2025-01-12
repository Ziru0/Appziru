
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

MongoDbModel mongoDbModelFromJson(String str) => MongoDbModel.fromJson(json.decode(str));

String mongoDbModelToJson(MongoDbModel data) => json.encode(data.toJson());

class MongoDbModel {
  ObjectId id;
  String fullname;
  String number;
  String address;

  MongoDbModel({
    required this.id,
    required this.fullname,
    required this.number,
    required this.address,
  });

  factory MongoDbModel.fromJson(Map<String, dynamic> json) => MongoDbModel(
    id: json["_id"],
    fullname: json["fullname"],
    number: json["number"],
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "fullname": fullname,
    "number": number,
    "address": address,
  };
}
