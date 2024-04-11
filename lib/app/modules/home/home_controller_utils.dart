import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart' as cor;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_controller.dart'; // Import your HomeController to access its properties

extension HomeControllerUtils on HomeController {
  WeightedLatLng noOffset(lats, intensity) {
    //print(offSetDistance);
    //double offset_key = x;
    //double offSetDistanceX = Random().nextDouble() * x - x / 2;
    //double offSetDistanceY = Random().nextDouble() * y - y / 2;
    return WeightedLatLng(
      cor.LatLng(
          lats.latitude, // Apply offset to latitude
          lats.longitude),
      //Random().nextDouble(),
      intensity,
    );
  }

  WeightedLatLng createOffset(lat, lon, lats, intensity) {
    //print(offSetDistance);
    //double offset_key = x;
    //double offSetDistanceX = Random().nextDouble() * x - x / 2;
    //double offSetDistanceY = Random().nextDouble() * y - y / 2;
    return WeightedLatLng(
      cor.LatLng(
          lats.latitude + offSetDistance * lat, // Apply offset to latitude
          lats.longitude + offSetDistance * 2 * lon),
      //Random().nextDouble(),
      intensity,
    );
  }

  Map<double, MaterialColor> generateRandomColorMap() {
    Random random = Random();
    Map<double, MaterialColor> map = {};

    for (int i = 0; i < 1; i++) {
      // Adjust the number of entries as needed
      double key =
          random.nextDouble(); // Generates a random double between 0.0 and 1.0
      MaterialColor value = Colors.primaries[random
          .nextInt(Colors.primaries.length)]; // Selects a random primary color
      map[key] = value;
    }

    return map;
  }

  double increaseRadius() {
    radius.value++;
    print(radius);
    return radius.value;
  }

  double decreaseRadius() {
    radius.value--;
    print(radius);
    return radius.value;
  }

  void zoomIn() async {
    currentZoom++;
    print(currentZoom);
    radius.value = currentZoom * 6;
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
    radius.value = currentZoom * 6;
    mapController.move(
      cor.LatLng(
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
      ),
      currentZoom,
    );
  }

  Map<double, MaterialColor> generateGradient(color) {
    // Logic to generate the gradient map based on the color
    // For example, you could generate a gradient that transitions from the color to a lighter version of it
    return {
      0.0: color.withOpacity(0.0),
      0.5: color.withOpacity(0.5),
      1.0: color.withOpacity(1.0),
    };
  }

  Future requestGPSPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      await Permission.locationWhenInUse.request();
      return;
    }
    if (status.isProvisional) {
      return;
    }
    if (status.isLimited) {
      return;
    }
    if (status.isRestricted) {
      await Permission.locationWhenInUse.request();
      return;
    }

    if (status.isPermanentlyDenied) {
      Get.defaultDialog(
        title: 'GPS access requied',
        onCancel: () => Get.close(1),
        onConfirm: () => openAppSettings(),
        textCancel: 'Close',
        textConfirm: 'Open settings',
      );
      return;
    }
  }

  List<cor.LatLng> calculateOffsetPoints(
      WeightedLatLng weightedLatLng, double offsetDistance) {
    cor.LatLng center =
        weightedLatLng.latLng; // Assuming WeightedLatLng has a latLng property
    double offsetLat = offsetDistance /
        111000; // Approximate conversion from meters to degrees
    double offsetLng = offsetLat / cos(center.latitude * pi / 180);

    // Calculate points to the right and left
    cor.LatLng rightPoint =
        cor.LatLng(center.latitude, center.longitude + offsetLng);
    cor.LatLng leftPoint =
        cor.LatLng(center.latitude, center.longitude - offsetLng);

    return [rightPoint, leftPoint];
  }
// Method to create a polygon from the offset points

  int getRangeNumber(double value) {
    // return Random().nextInt(8);
    if (value >= 0 && value < 1) {
      return 1;
    } else if (value >= 1 && value < 3) {
      return 2;
    } else if (value >= 3 && value < 5) {
      return 3;
    } else if (value >= 5 && value < 7) {
      return 4;
    } else if (value >= 7 && value < 9) {
      return 5;
    } else if (value >= 9 && value < 14) {
      return 6;
    } else if (value >= 15 && value < 17) {
      return 7;
    } else if (value >= 17 && value <= 25) {
      return 8;
    } else {
      // Handle values outside the specified ranges
      // This could be an error case or a default return value
      return 0; // Example: Return 0 for values outside the specified ranges
    }
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

  void setIntensity(value) {
    intensity.value = double.parse(value);
  }

  void changeQuantity(bool x) {
    quantity = x == true ? quantity + 1 : quantity - 1;

    if (quantity == 0) {
      quantity = 1;
    }
  }

  void changeIntensity(bool x) {
    var y = x == true ? 2 : 0.5;
    intensity.value *= y;
    if (intensity.value == 0) {
      intensity.value = 0.1;
    }
  }
}
