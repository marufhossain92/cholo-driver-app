import 'package:cholo_driver_app/infoHandler/app_info.dart';
import 'package:cholo_driver_app/mainScreens/trips_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EarningTabPage extends StatefulWidget {
  const EarningTabPage({super.key});

  @override
  State<EarningTabPage> createState() => _EarningTabPageState();
}

class _EarningTabPageState extends State<EarningTabPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Column(
        children: [
          //earnings
          Container(
            color: Colors.black,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 80,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  const Text(
                    "Your Earnings",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    "৳ ${Provider.of<AppInfo>(context, listen: false).driverTotalEarnings}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          //total number of trips
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TripsHistoryScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white54,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Image.asset(
                    "images/car_logo.png",
                    width: 100,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  const Text(
                    "Trips Completed",
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: Text(
                        Provider.of<AppInfo>(context, listen: false)
                            .allTripsHistoryInformationList
                            .length
                            .toString(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
