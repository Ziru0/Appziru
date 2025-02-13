import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'MongoDBModeluser.dart';
import 'constant.dart';

class MongoDatabase {
  static var db, userCollection;

  static get ridesCollection => null;

  // Connect to MongoDB
  static connect() async {
    try {
      db = await Db.create(MONGO_CONN_URL);
      await db.open();
      print("✅ MongoDB Connected Successfully");
      userCollection = db.collection(PROFILE_COLLECTION);
    } catch (e) {
      print("❌ MongoDB Connection Error: $e");
    }
  }

  // Fetch the current user by firebaseId
  static Future<MongoDbModelUser?> getUser(String firebaseId) async {
    try {
      var userData = await userCollection.findOne(where.eq('firebaseId', firebaseId));

      if (userData != null) {
        return MongoDbModelUser.fromJson(userData);
      } else {
        print("🚨 User not found in the database!");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching user: $e");
      return null;
    }
  }


  // Fetch all data from user collection
  static Future<List<Map<String, dynamic>>> getData() async {
    final arrData = await userCollection.find().toList();
    return arrData;
  }
  
  // Insert user data
  static Future<String> insertUser(MongoDbModelUser data) async {
    try {
      var result2 = await userCollection.insertOne(data.toJson());
      if (result2.isSuccess) {
        return "Data Inserted";
      } else {
        return "Something wrong";
      }
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  // Update user data
  static Future<String> updateOne(String firebaseId, String fullname, String address, String number, Map<Object, dynamic> updatedData) async {
    try {
      var modifier = ModifierBuilder()
        ..set('fullname', fullname)
        ..set('address', address)
        ..set('number', number);

      if (updatedData.containsKey('role')) {
        modifier.set('role', updatedData['role']);
      }

      updatedData.forEach((key, value) {
        modifier.set(key as String, value);
      });

      var result = await userCollection.updateOne(
          where.eq('firebaseId', firebaseId),
          modifier
      );

      if (result.isSuccess) {
        return "Document Updated Successfully";
      } else {
        return "Failed to Update Document";
      }
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  // Fetch one user by firebaseId
  static Future<Map<String, dynamic>?> getOne(String firebaseId) async {
    return await userCollection.findOne(where.eq('firebaseId', firebaseId));
  }

  static Future<void> saveRequest(Map<String, dynamic> requestData) async {
    var collection = db.collection('requests');

    // Ensure the request has a 'status', but DO NOT overwrite driverId
    requestData['status'] = 'pending';

    print("🔥 Before Insert - Final Request Data: ${requestData}");

    await collection.insert(requestData);
  }


  static Future<void> updateProfile(String firebaseId, Map<String, dynamic> updatedData) async {
    var collection = db.collection('users');

    print("🔍 Updating profile for FirebaseID: $firebaseId");
    print("📌 Updated Data: $updatedData");

    var result = await collection.updateOne(
      {'firebaseId': firebaseId},
      {'\$set': updatedData},
    );

    if (result.isSuccess) {
      print("✅ Profile updated successfully!");
    } else {
      print("❌ Failed to update profile");
    }
  }

  
  static Future<List<Map<String, dynamic>>> getRideHistory(String userId) async {
    try {
      var rides = await ridesCollection.find({'userId': userId}).toList();
      return rides.map((ride) => Map<String, dynamic>.from(ride)).toList();
    } catch (e) {
      print("Error fetching ride history: $e");
      return [];
    }
  }



}
