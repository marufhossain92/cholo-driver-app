import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cholo_driver_app/global/global.dart';
import 'package:cholo_driver_app/models/user_ride_request_information.dart';
import 'package:cholo_driver_app/pushNotification/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializedCloudMessaging(BuildContext context) async {
    // 1. Terminated
    // When the app is completely closed and open directly from push notification
    FirebaseMessaging.instance.getInitialMessage().then(
      (RemoteMessage? remoteMessage) {
        if (remoteMessage != null) {
          // Display ride request information - user information who request a ride
          //readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
          readUserRideRequestInformation(
              remoteMessage.data["rideRequestId"], context);
        }
      },
    );

    // 2. Foreground
    // When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage? remoteMessage) {
        // Display ride request information - user information who request a ride
        readUserRideRequestInformation(
            remoteMessage!.data["rideRequestId"], context);
      },
    );

    // 3. Background
    // When the app is in the background and open directly from push notification
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage? remoteMessage) {
        // Display ride request information - user information who request a ride
        readUserRideRequestInformation(
            remoteMessage!.data["rideRequestId"], context);
      },
    );
  }

  readUserRideRequestInformation(
      String userRideRequestId, BuildContext context) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(userRideRequestId)
        .once()
        .then(
      (snapData) {
        if (snapData.snapshot.value != null) {
          audioPlayer.open(Audio("music/music_notification.mp3"));
          audioPlayer.play();

          double originLat = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["latitude"].toString(),
          );
          double originLng = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["longitude"].toString(),
          );
          String originAddress =
              (snapData.snapshot.value! as Map)["originAddress"];

          double destinationLat = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["latitude"],
          );
          double destinationLng = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["longitude"],
          );
          String destinationAddress =
              (snapData.snapshot.value! as Map)["destinationAddress"];

          String userName = (snapData.snapshot.value! as Map)["userName"];
          String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

          String? rideRequestId = snapData.snapshot.key;

          UserRideRequestInformation userRideRequestDetails =
              UserRideRequestInformation();

          userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
          userRideRequestDetails.originAddress = originAddress;

          userRideRequestDetails.destinationLatLng =
              LatLng(destinationLat, destinationLng);
          userRideRequestDetails.destinationAddress = destinationAddress;

          userRideRequestDetails.userName = userName;
          userRideRequestDetails.userPhone = userPhone;

          userRideRequestDetails.rideRequestId = rideRequestId;

          showDialog(
            context: context,
            builder: (BuildContext context) => NotificationDialogBox(
              userRideRequestDetails: userRideRequestDetails,
            ),
          );
        } else {
          Fluttertoast.showToast(
            msg: "This Ride Request ID do not exist",
          );
        }
      },
    );
  }

  Future generateAndGetToken() async {
    String? registrationToken = await messaging.getToken();
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}
