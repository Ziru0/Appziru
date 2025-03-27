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

  static Future<List<Map<String, dynamic>>> getData() async {
    try {
      // Fetch raw data from MongoDB
      var users = await userCollection!.find().toList();
      print("📊 Raw data from MongoDB (getData - Attempt 2): $users");

      // Explicitly define the return type of the map function
      List<Map<String, dynamic>> formattedUsers = users.map<Map<String, dynamic>>((user) { // <-- Explicit return type here
        if (user is Map) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(user);

          userData.forEach((key, value) {
            if (value is ObjectId) {
              userData[key] = value.toHexString();
            }
          });
          return userData;
        } else {
          print("❌ Unexpected data type in MongoDB result (Attempt 2): $user");
          return <String, dynamic>{};
        }
      }).toList();

      print("✅ Formatted Data (getData - Attempt 2): $formattedUsers");
      return formattedUsers;
    } catch (e) {
      print("❌ Error fetching data (getData - Attempt 2): $e");
      return [];
    }
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

  static Future<void> updateUser(String firebaseId, Map<String, dynamic> updatedData) async {
    var result = await userCollection.updateOne(
      where.eq('firebaseId', firebaseId),
      modify.set('fullname', updatedData['fullname'])
          .set('number', updatedData['number'])
          .set('address', updatedData['address'])
          .set('profileImage', updatedData['profileImage'])
    );

    if (result.isSuccess) {
      print("User updated successfully");
    } else {
      print("Failed to update user");
    }
  }

  // Update user data
  static Future<String> updateOne(String firebaseId, String fullname, String address, String number, Map<String, dynamic> updatedData) async {
    try {
      var modifier = ModifierBuilder()
        ..set('fullname', fullname)
        ..set('address', address)
        ..set('number', number);

      updatedData.forEach((key, value) {
        modifier.set(key, value);  // 🔹 Now `key` is always a `String`
      });

      var result = await userCollection.updateOne(
        where.eq('firebaseId', firebaseId),
        modifier,
      );

      if (result.isSuccess) {
        print("✅ User updated successfully: $updatedData");
        return "Document Updated Successfully";
      } else {
        print("❌ Failed to update user: $firebaseId");
        return "Failed to Update Document";
      }
    } catch (e) {
      print("❌ Update Error: $e");
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

  static Future<List<Map<String, dynamic>>> getPassengerRides(String firebaseId) async {
    try {
      var usersCollection = db.collection('ziru');
      var requestsCollection = db.collection('requests');

      var user = await usersCollection.findOne(where.eq("firebaseId", firebaseId));

      if (user == null || !user.containsKey('passengerId')) {
        print("❌ No user found with Firebase ID: $firebaseId");
        return [];
      }

      String passengerId = user['passengerId'];
      print("✅ Found passengerId: $passengerId");

      final rides = await requestsCollection
          .find(where.eq("passengerId", passengerId).oneFrom("status", ["completed", "failed"]))
          .toList();

      List<Map<String, dynamic>> rideList = [];

      for (var ride in rides) {
        if (ride is Map<String, dynamic>) { // Type check!
          rideList.add(ride);
        } else {
          print("⚠️ Warning: Ride data is not a Map<String, dynamic>. Skipping. Data: $ride");
          // Optionally, handle the unexpected data type.  You could try to
          // convert it or log more details for debugging.
        }
      }


      print("📊 Ride requests found: $rideList");

      return rideList;
    } catch (e) {
      print("❌ Error fetching rides: $e");
      return [];
    }
  }

  static Future<WriteResult?> insertDriver(Map<String, dynamic> data) async {
    try {
      var collection = db?.collection(DRIVERS_COLLECTION); // DRIVERS_COLLECTION = "drivers-info"
      var result = await collection?.insertOne(data);
      return result;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverActivityRides(String firebaseId) async {
    try {
      var usersCollection = db.collection('ziru');
      var requestsCollection = db.collection('requests');

      var user = await usersCollection.findOne(where.eq("firebaseId", firebaseId));

      if (user == null || user['driverId'] == null) {
        print("❌ No valid driverId found for Firebase ID: $firebaseId");
        return [];
      }

      String driverId = user['driverId'].toString();
      print("✅ Found driverId: $driverId");

      final rides = await requestsCollection
          .find(where.eq("driverId", driverId).oneFrom("status", ["completed", "failed"]))
          .toList();

      print("📌 Raw Ride Data: $rides");

      return rides.map((ride) {
        String safeDistance = ride["distance"]?.toString() ?? "0.0";
        String safeDuration = ride["duration"]?.toString() ?? "0 min";
        String safeCost = ride["cost"] != null
            ? (double.tryParse(ride["cost"].toString())?.toStringAsFixed(2) ?? "0.00")
            : "0.00";
        String safeStatus = ride["status"]?.toString() ?? "unknown";

        print("🚀 Processed Ride: Distance=$safeDistance, Duration=$safeDuration, Cost=$safeCost, Status=$safeStatus");

        return {
          "distance": safeDistance,
          "duration": safeDuration,
          "cost": safeCost,
          "status": safeStatus,
        };
      }).toList();
    } catch (e, stacktrace) {
      print("❌ Error fetching rides: $e");
      print("Stacktrace: $stacktrace");
      return [];
    }
  }

  static Future<void> updateDriverLocation(String driverId, Map<String, dynamic> locationData) async {
    try {
      var driverCollection = db.collection('driverlocation'); // Ensure the correct collection

      var result = await driverCollection.updateOne(
        where.eq("driverId", driverId),
        modify.set("latitude", locationData["latitude"])
            .set("longitude", locationData["longitude"])
            .set("lastUpdated", locationData["lastUpdated"]),
        upsert: true, // Creates a new document if it doesn't exist
      );

      if (result.isSuccess) {
        print("✅ Driver location updated successfully in MongoDB!");
      } else {
        print("⚠️ No changes made to the driver location.");
      }
    } catch (e) {
      print("❌ Error updating driver location: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getDriversWithLocation() async {
    try {
      var driverCollection = db.collection('pinned_locations'); // Ensure correct collection
      var driverData = await driverCollection.find().toList();

      print("🔍 Fetched drivers: ${driverData.length}");
      print("📍 First Driver Data: ${driverData.isNotEmpty ? driverData.first : 'No data'}");

      return driverData;
    } catch (e) {
      print("❌ Error fetching driver data: $e");
      return [];
    }
  }

  static Future<void> insertPendingDriver(Map<String, dynamic> driverData) async {
    if (db == null) {
      await connect(); // Ensure the connection is established before accessing the collection
    }

    var collection = db.collection('pending-driver');

    var result = await collection.insertOne(driverData);

    if (result.isSuccess) {
      print("✅ Pending driver inserted successfully!");
    } else {
      print("❌ Failed to insert pending driver.");
    }
  }

  // ✅ Fetch completed ride requests using driverId as a string
  static Future<List<Map<String, dynamic>>> getCompletedRequests(ObjectId driverId) async {
    try {
      var collection = db.collection("requests");

      var driverId = "67a4142cb10a9cc0a7000000"; // Keep driverId as a String

      var completedRequests = await collection.find({
        "driverId": driverId, // Ensure driverId is treated as a String
        "status": "completed"
      }).toList();

      print("✅ Completed Requests for Driver ($driverId): $completedRequests");

      return completedRequests.cast<Map<String, dynamic>>();
    } catch (e) {
      print("❌ Error fetching completed requests: $e");
      return [];
    }
  }

  // ✅ Fetch all requests for debugging
  static Future<List<Map<String, dynamic>>> getAllRequests(ObjectId driverId) async {
    try {
      var collection = db.collection("requests");

      var requests = await collection.find({
        "driverId": driverId, // ✅ Query using ObjectId
      }).toList();

      print("📌 All Requests for Driver ($driverId): $requests");

      return requests.cast<Map<String, dynamic>>();
    } catch (e) {
      print("❌ Error fetching all requests: $e");
      return [];
    }
  }

}
