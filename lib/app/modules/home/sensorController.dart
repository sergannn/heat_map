import 'package:get/get.dart';
import 'home_controller.dart'; // Import your controller
import 'package:latlong2/latlong.dart' as cor;
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

void someFunction() {
  // Access the HomeController instance
  final homeController = Get.find<HomeController>();

  // Access the observable variables
  double currentRadius = homeController.radius.value;
  LocationMarkerPosition? currentPosition =
      homeController.currentPosition.value;

  // Use the variables as needed
  print('Current radius: $currentRadius');
  print('Current position: $currentPosition');
}

void main() {
  Get.put(HomeController()); // Register HomeController with GetX
  runApp(MyApp());
}

double increaseOffset() {
  offset_key += 0.001;
  offSetDistance++;
  return offSetDistance;
}

double decreaseOffset() {
  offset_key -= 0.001;
  offSetDistance--;
  return offSetDistance;
}

double increaseRadius() {
  radius.value++;
  print(radius);
  return radius.value;
}

double decreaseRadius() {
  radius.value--;
  return radius.value;
}

void zoomIn() async {
  currentZoom++;
  print(currentZoom);
  mapController.move(
    cor.LatLng(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
    ),
    currentZoom,
  );
}

void zoomOut() async {
  currentZoom--;
  print(currentZoom);
  mapController.move(
    cor.LatLng(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
    ),
    currentZoom,
  );
}

void locateMe() async {
  if (!await Permission.locationWhenInUse.status.isGranted) {
    await requestGPSPermission();
  }
  print(currentPosition.value!.latitude);
  print('moving');
  mapController.move(
    cor.LatLng(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
    ),
    14,
  );
}

void changeQuantity(bool x) {
  var y = x == true ? 2 : 0.5;
  quantity *= y.toInt();
  if (quantity == 0) {
    quantity = 1;
  }
}

void changeIntensity(bool x) {
  var y = x == true ? 2 : 0.5;
  intensity *= y;
  if (intensity == 0) {
    intensity = 0.1;
  }
}
