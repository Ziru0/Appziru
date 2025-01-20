import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_colors.dart';
import '../utils/app_constants.dart'; // For LatLng class
import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng class
import 'controllerconstants.dart';
import 'package:lage/components/controller/controllerconstants.dart';

List<LatLng> polyList = [];
bool internet = true;

getPolylines(LatLng pickUp, LatLng drop) async {
  polyList.clear();
  String pickLat = pickUp.latitude.toString();
  String pickLng = pickUp.longitude.toString();
  String dropLat = drop.latitude.toString();
  String dropLng = drop.longitude.toString();

  try {
    var response = await http.get(Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=${AppConstants0.kOpenRouteServiceApiKey}&start=$pickLng,$pickLat&end=$dropLng,$dropLat'));
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      var steps = decodedResponse['features'][0]['geometry']['coordinates'];

      // OpenRouteService provides coordinates directly
      for (var coord in steps) {
        double lon = coord[0];
        double lat = coord[1];
        polyList.add(LatLng(lat, lon));
      }

      // Add polyline to the map
      polyline.add(
        Polyline(
          polylineId: const PolylineId('1'),
          color: AppColors.greenColor,
          visible: true,
          width: 4,
          points: polyList,
        ),
      );
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return polyList;
}

Set<Polyline> polyline = {};

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      : assert(latitude != null),
        assert(longitude != null),
        this.latitude = latitude,
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees.
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}
