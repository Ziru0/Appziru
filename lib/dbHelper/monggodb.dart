import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'MongoDBModeluser.dart';
import 'constant.dart';

class MongoDatabase {
  static var db, userCollection;

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

  // Fetch only users with role "Driver"
  static Future<List<MongoDbModelUser>> getDrivers() async {
    try {
      var collection = db.collection(PROFILE_COLLECTION);
      var query = where.eq('role', 'Driver');
      print("🔍 Executing Query: $query");

      var result = await collection.find(query).toList();
      print("🔍 Raw Driver Data: $result");

      if (result.isEmpty) {
        print("🚨 No drivers found in the database!");
        return [];
      }

      List<MongoDbModelUser> drivers = result.map((doc) {
        return MongoDbModelUser.fromJson(Map<String, dynamic>.from(doc));
      }).toList();

      print("✅ Successfully Parsed Drivers: ${drivers.length}");
      return drivers;
    } catch (e) {
      print("❌ Error fetching drivers: $e");
      return [];
    }
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

// Save request data into 'requests' collection
  static Future<void> saveRequest(Map<String, dynamic> requestData) async {
    var collection = db.collection('requests');

    // Ensure the request has a 'status' and 'driverId'
    requestData['status'] = 'pending'; // Default status when a ride is requested
    requestData['driverId'] = null; // Initially no driver assigned

    await collection.insert(requestData);
  }





}
