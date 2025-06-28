import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotification();
  await initializeService();
  runApp(const MyApp());
}

Future<void> _initializeNotification() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 1,
      notificationChannelId: 'location_channel_id',
      initialNotificationTitle: 'Background Location Service',
      initialNotificationContent: 'Tracking location in background...',
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await notificationPlugin.initialize(initSettings);

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Location Tracking",
      content: "Tracking your location...",
    );
  }

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await notificationPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '📍 Location Update',
        'Lat: ${position.latitude}, Lng: ${position.longitude}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'location_channel_id',
            'Location Updates',
            channelDescription:
                'This channel is used for background location tracking',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      print("Location Error: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Location Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String location = "Press the button to get location";

  Future<void> _getPermissionAndLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (await Permission.locationAlways.isDenied) {
      await openAppSettings();
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      location = "Latitude: ${pos.latitude}, Longitude: ${pos.longitude}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background Location Service')),
      body: Center(child: Text(location)),
      floatingActionButton: FloatingActionButton(
        onPressed: _getPermissionAndLocation,
        child: const Icon(Icons.location_on),
      ),
    );
  }
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await initializeService();
//   runApp(const MyApp());
// }
//
// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       isForegroundMode: true,
//       autoStart: true,
//       foregroundServiceNotificationId: 1,
//       notificationChannelId: 'location_service',
//       initialNotificationTitle: 'Background Location Service',
//       initialNotificationContent: 'Tracking location in background...',
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
//
//   await service.startService();
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();
//
//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: "Location Tracking",
//       content: "Tracking your location...",
//     );
//   }
//
//   Timer.periodic(const Duration(seconds: 3), (timer) async {
//     /*if (service is AndroidServiceInstance &&
//         !(await service.isForegroundService())) return;*/
//
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       print(
//           "📍 Background Location: ${position.latitude}, ${position.longitude}");
//     } catch (e) {
//       print("Location Error: $e");
//     }
//   });
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Background Location Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const HomeScreen(),
//     );
//   }
// }
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   String location = "Press the button to get location";
//
//   Future<void> _getPermissionAndLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }
//
//     if (await Permission.locationAlways.isDenied) {
//       await openAppSettings(); // Navigate to system settings
//     }
//
//     Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//
//     setState(() {
//       location = "Latitude: ${pos.latitude}, Longitude: ${pos.longitude}";
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Background Location Service')),
//       body: Center(child: Text(location)),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _getPermissionAndLocation,
//         child: const Icon(Icons.location_on),
//       ),
//     );
//   }
// }
