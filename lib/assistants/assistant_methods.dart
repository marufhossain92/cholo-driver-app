import 'package:cholo_driver_app/assistants/request_assistant.dart';
import 'package:cholo_driver_app/global/global.dart';
import 'package:cholo_driver_app/global/map_key.dart';
import 'package:cholo_driver_app/infoHandler/app_info.dart';
import 'package:cholo_driver_app/models/direction_details_info.dart';
import 'package:cholo_driver_app/models/directions.dart';
import 'package:cholo_driver_app/models/trips_history_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class AssistantMethods {
  static Future<String> searchAddressForGeographicCoordinates(
      Position position, context) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if (requestResponse != "Error occurred, Failed. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo?>
      obtainOriginToDestinationDirectionDetails(
          LatLng originPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";

    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

    if (responseDirectionApi == "Error Occurred, Failed. No Response.") {
      return null;
    }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static pauseLiveLocationUpdates() {
    streamSubscriptionPosition!.pause();
    Geofire.removeLocation(currentFirebaseUser!.uid);
  }

  static resumeLiveLocationUpdates() {
    streamSubscriptionPosition!.resume();
    Geofire.setLocation(currentFirebaseUser!.uid,
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
  }

  static double calculateFareAmountFromOriginToDestination(
      DirectionDetailsInfo directionDetailsInfo) {
    double timeTraveledFareAmountPerMinute =
        (directionDetailsInfo.duration_value! / 60) *
            20; // 20 Taka per kilometer
    double distanceTraveledFareAmountPerKilometer =
        (directionDetailsInfo.duration_value! / 1000) *
            20; // 20 Taka per kilometer

    // BDT
    double totalFareAmount = timeTraveledFareAmountPerMinute +
        distanceTraveledFareAmountPerKilometer;

    if (driverVehicleType == "bike") {
      double resultFareAmount = (totalFareAmount.truncate()) / 2.0;
      return resultFareAmount;
    } else if (driverVehicleType == "economy") {
      return totalFareAmount.truncate().toDouble();
    } else if (driverVehicleType == "premium") {
      double resultFareAmount = (totalFareAmount.truncate()) * 2.0;
      return resultFareAmount;
    } else {
      return totalFareAmount.truncate().toDouble();
    }
  }

  //retrieve the trips KEYS for online user
  //trip key = ride request key
  static void readTripsKeysForOnlineDriver(context) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .orderByChild("driverId")
        .equalTo(fAuth.currentUser!.uid)
        .once()
        .then(
      (snap) {
        if (snap.snapshot.value != null) {
          Map keysTripsId = snap.snapshot.value as Map;

          //count total number trips and share it with Provider
          int overAllTripsCounter = keysTripsId.length;
          Provider.of<AppInfo>(context, listen: false)
              .updateOverAllTripsCounter(overAllTripsCounter);

          //share trips keys with Provider
          List<String> tripsKeysList = [];
          keysTripsId.forEach(
            (key, value) {
              tripsKeysList.add(key);
            },
          );
          Provider.of<AppInfo>(context, listen: false)
              .updateOverAllTripsKeys(tripsKeysList);

          //get trips keys data - read trips complete information
          readTripsHistoryInformation(context);
        }
      },
    );
  }

  static void readTripsHistoryInformation(context) {
    var tripsAllKeys =
        Provider.of<AppInfo>(context, listen: false).historyTripsKeysList;

    for (String eachKey in tripsAllKeys) {
      FirebaseDatabase.instance
          .ref()
          .child("All Ride Request")
          .child(eachKey)
          .once()
          .then(
        (snap) {
          var eachTripHistory = TripsHistoryModel.fromSnapshot(snap.snapshot);

          if ((snap.snapshot.value as Map)["status"] == "ended") {
            //update-add each history to OverAllTrips History Data List
            Provider.of<AppInfo>(context, listen: false)
                .updateOverAllTripsHistoryInformation(eachTripHistory);
          }
        },
      );
    }
  }

  //readDriverEarnings
  static void readDriverEarnings(context) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(fAuth.currentUser!.uid)
        .child("earnings")
        .once()
        .then(
      (snap) {
        if (snap.snapshot.value != null) {
          String driverEarnings = snap.snapshot.value.toString();
          Provider.of<AppInfo>(context, listen: false)
              .updateDriverTotalEarnings(driverEarnings);
        }
      },
    );

    readTripsKeysForOnlineDriver(context);
  }

  static void readDriverRatings(context) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(fAuth.currentUser!.uid)
        .child("ratings")
        .once()
        .then(
      (snap) {
        if (snap.snapshot.value != null) {
          String driverRatings = snap.snapshot.value.toString();
          Provider.of<AppInfo>(context, listen: false)
              .updateDriverAverageRatings(driverRatings);
        }
      },
    );
  }
}
