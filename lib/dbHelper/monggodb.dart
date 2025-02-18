import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

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
      // print("✅ MongoDB Connected Successfully");
      userCollection = db.collection(PROFILE_COLLECTION);
    } catch (e) {
      // print("❌ MongoDB Connection Error: $e");
    }
  }

  // Fetch the current user by firebaseId
  static Future<MongoDbModelUser?> getUser(String firebaseId) async {
    try {
      var userData = await userCollection.findOne(where.eq('firebaseId', firebaseId));

      if (userData != null) {
        return MongoDbModelUser.fromJson(userData);
      } else {
        // print("🚨 User not found in the database!");
        return null;
      }
    } catch (e) {
      // print("❌ Error fetching user: $e");
      return null;
    }
  }


  // Fetch all data from user collection
  static Future<List<Map<String, dynamic>>> getData() async {
    final arrData = await userCollection.find().toList();
    return arrData;
  }

  static Future<String> insertUser(Map<String, dynamic> data) async {
    try {
      var result = await userCollection.insertOne(data);
      if (result.isSuccess) {
        return "User Inserted Successfully";
      } else {
        return "Failed to Insert User";
      }
    } catch (e) {
      return "MongoDB Insert Error: $e";
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
      // print(e.toString());
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

    // print("🔥 Before Insert - Final Request Data: $requestData");

    await collection.insert(requestData);
  }


  static Future<bool> updateProfile(String firebaseId, Map<String, dynamic> updatedData) async {
    var collection = db.collection('users');

    // ✅ DEBUG: Print all users in DB to check if the firebaseId exists
    var allUsers = await collection.find().toList();
    print("📝 All Users in Database: $allUsers");

    // ✅ DEBUG: Try to find user with given firebaseId
    var existingUser = await collection.findOne(where.eq("firebaseId", firebaseId));
    print("🔍 Searching for User with firebaseId: $firebaseId");
    print("🔍 Existing User: $existingUser");

    if (existingUser == null) {
      print("❌ User not found! Check if firebaseId is correct.");
      return false;
    }

    print("✅ User found! Proceeding with update...");

    // Ensure the update contains a timestamp
    updatedData["lastUpdated"] = DateTime.now().toUtc().toString();

    var result = await collection.updateOne(
      where.eq("firebaseId", firebaseId),
      modify.set("fullname", updatedData["fullname"] ?? existingUser["fullname"])
          .set("number", updatedData["number"] ?? existingUser["number"])
          .set("address", updatedData["address"] ?? existingUser["address"])
          .set("lastUpdated", updatedData["lastUpdated"]),
      upsert: false, // Don't insert a new document if not found
    );

    if (result.isSuccess && result.nModified > 0) {
      print("✅ Profile updated successfully");
      return true;
    } else if (result.isSuccess && result.nMatched > 0) {
      print("⚠️ No new changes detected, but the document exists.");
      return false;
    } else {
      print("❌ Profile update failed! No matching document.");
      return false;
    }
  }


  static Future<List<Map<String, dynamic>>> getCompletedRideHistory(String userId) async {
    try {
      var rides = await userCollection.find({'passengerId': userId, 'status': 'completed'}).toList();
      return rides.map((ride) => Map<String, dynamic>.from(ride)).toList();
    } catch (e) {
      return [];
    }
  }



}
