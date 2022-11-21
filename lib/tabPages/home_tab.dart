import 'dart:async';
import 'package:cholo_driver_app/assistants/assistant_methods.dart';
import 'package:cholo_driver_app/assistants/black_theme_google_map.dart';
import 'package:cholo_driver_app/global/global.dart';
import 'package:cholo_driver_app/pushNotification/push_notification_system.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _contentPro = CameraPosition(
    target: LatLng(23.777900799525852, 90.411270193219),
    zoom: 14.4746,
  );

  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;

  double topPaddingOfMap = 0;

  StreamSubscription<Position>? streamSubscriptionPosition;

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverCurrentPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    driverCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        // ignore: use_build_context_synchronously
        await AssistantMethods.searchAddressForGeographicCoordinates(
            driverCurrentPosition!, context);
    print("This is your address = " + humanReadableAddress);

    // ignore: use_build_context_synchronously
    AssistantMethods.readDriverRatings(context);
  }

  readCurrentDriverInformation() async {
    currentFirebaseUser = fAuth.currentUser;

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .once()
        .then(
      (snap) {
        if (snap.snapshot.value != null) {
          onlineDriverData.id = (snap.snapshot.value as Map)["id"];
          onlineDriverData.name = (snap.snapshot.value as Map)["name"];
          onlineDriverData.email = (snap.snapshot.value as Map)["email"];
          onlineDriverData.phone = (snap.snapshot.value as Map)["phone"];
          onlineDriverData.car_model =
              (snap.snapshot.value as Map)["car_details"]["car_model"];
          onlineDriverData.car_color =
              (snap.snapshot.value as Map)["car_details"]["car_color"];
          onlineDriverData.car_number =
              (snap.snapshot.value as Map)["car_details"]["car_number"];

          driverVehicleType =
              (snap.snapshot.value as Map)["car_details"]["type"];
        }
      },
    );

    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializedCloudMessaging(context);
    pushNotificationSystem.generateAndGetToken();

    AssistantMethods.readDriverEarnings(context);
  }

  @override
  void initState() {
    super.initState();

    checkIfLocationPermissionAllowed();
    readCurrentDriverInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: EdgeInsets.only(top: topPaddingOfMap),
          mapType: MapType.normal,
          myLocationEnabled: true,
          initialCameraPosition: _contentPro,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;

            blackThemeGoogleMap(newGoogleMapController);

            setState(
              () {
                topPaddingOfMap = 30;
              },
            );

            locateDriverCurrentPosition();
          },
        ),

        // UI for online/offline driver
        statusText != "Now online"
            ? Container(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                color: Colors.black87,
              )
            : Container(),

        //Button for online/offline driver
        Positioned(
          top: statusText != "Now online"
              ? MediaQuery.of(context).size.height * 0.50
              : 25,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (isDriverActive != true) {
                    driverIsOnlineNow();
                    updateDriversLocationAtRealTime();

                    setState(
                      () {
                        statusText = "Now online";
                        isDriverActive = true;

                        buttonColor = Colors.transparent;
                      },
                    );

                    // Display Toast
                    Fluttertoast.showToast(
                      msg: "You are online now!",
                    );
                  } else {
                    driverIsOffLineNow();

                    setState(
                      () {
                        statusText = "Now offline";
                        isDriverActive = false;

                        buttonColor = Colors.grey;
                      },
                    );

                    // Display Toast
                    Fluttertoast.showToast(msg: "You are offline now!");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: statusText != "Now online"
                    ? Text(
                        statusText,
                        style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )
                    : const Icon(
                        Icons.phonelink_ring,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  driverIsOnlineNow() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = pos;

    Geofire.initialize("activeDrivers");

    Geofire.setLocation(currentFirebaseUser!.uid,
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    ref.set("idle"); // Searching for ride request
    ref.onValue.listen((event) {});
  }

  updateDriversLocationAtRealTime() {
    streamSubscriptionPosition = Geolocator.getPositionStream().listen(
      (Position position) {
        driverCurrentPosition = position;

        if (isDriverActive == true) {
          Geofire.setLocation(
            currentFirebaseUser!.uid,
            driverCurrentPosition!.latitude,
            driverCurrentPosition!.longitude,
          );
        }

        LatLng latLng = LatLng(
          driverCurrentPosition!.latitude,
          driverCurrentPosition!.longitude,
        );

        newGoogleMapController!.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
      },
    );
  }

  driverIsOffLineNow() {
    Geofire.removeLocation(currentFirebaseUser!.uid);

    DatabaseReference? ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");
    ref.onDisconnect();
    ref.remove();
    ref = null;

    Future.delayed(
      const Duration(milliseconds: 2000),
      () {
        // SystemChannels.platform.invokeMethod("SystemNavigator.pop");
        SystemNavigator.pop();
      },
    );
  }
}
