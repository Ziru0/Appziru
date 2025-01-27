import 'dart:developer';

import 'package:lage/dbHelper/MongoDBModeluser.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'constant.dart';

class MongoDatabase {

  static var db , userCollection;

  static connect() async{
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    inspect(db);
    userCollection = db.collection(PROFILE_COLLECTION);
  }

  static Future<String> insertUser(MongoDbModelUser data) async{
    try{
      var result2 = await userCollection.insertOne(data.toJson());
      if(result2.isSuccess){
        return "Data Inserted";
      }else{
        return "Something wrong";
      }

      return result2;
    } catch(e) {
      print(e.toString());
      return e.toString();
    }
  }

  static Future<String> updateOne(
      String firebaseId,
      String fullname,
      String address,
      String number,
      Map<Object, dynamic> updatedData) async {
    try {
      var modifier = ModifierBuilder()
        ..set('fullname', fullname)
        ..set('address', address)
        ..set('number', number);

      // Add role if it's in the updatedData map
      if (updatedData.containsKey('role')) {
        modifier.set('role', updatedData['role']);
      }

      // Apply additional fields from updatedData
      updatedData.forEach((key, value) {
        modifier.set(key as String, value);
      });

      var result = await userCollection.updateOne(
        // where.eq(ObjectId.parse(firebaseId)), // Match the document by ObjectId
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

  static Future<Map<String, dynamic>?> getOne(String firebaseId) async {
    return await userCollection.findOne(where.eq('firebaseId', firebaseId));
  }

}

// class MongoDatabase {
//   static var db, userCollection;
//

// }