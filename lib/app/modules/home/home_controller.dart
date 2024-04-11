import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geodesy/geodesy.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as cor;
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'home_controller_utils.dart';
import 'settingsController.dart';

class HomeController extends GetxController {
  late MapController mapController;
  double currentZoom = 14;

  late final Stream<LocationMarkerPosition?> positionStream;
  late final Stream<LocationMarkerHeading?> headingStream;
  final StreamController<AccelerometerEvent> _accelerometerStreamController =
      StreamController<AccelerometerEvent>();

  @override
  void onInit() {
    print("home initing");
    mapController = MapController();

    mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        //print("Map is being dragged");
        // You can add your logic here to handle the drag event
      }
    });
    const factory = LocationMarkerDataStreamFactory();
    positionStream = factory.fromGeolocatorPositionStream().asBroadcastStream();
    headingStream = factory.fromCompassHeadingStream().asBroadcastStream();

    super.onInit();
  }

  @override
  void onReady() {
    getAccelerometerValues();
    super.onReady();
  }

  @override
  void onClose() {
    print("closing");
    mapController.dispose();
    for (StreamSubscription subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    // Clear the list of subscriptions
    _streamSubscriptions.clear();
    super.onClose();
  }

  Future<HomeController> init() async {
    print("init");
    await getLocation();

    // await getData();
    updateCurrentPosition();
    return this;
  }

  RxDouble maxAccSum = 0.0.obs;
  RxInt current_data = 0.obs;
  RxDouble offset_key = 0.20.obs;
  late double offSetDistance =
      Random().nextDouble() * offset_key.value - offset_key.value / 2;

  RxList<double> accelerometerListValues = <double>[].obs;
  RxnDouble accelerometerDelta = RxnDouble();
  List<StreamSubscription> _streamSubscriptions = [];
  RxnDouble accSum = RxnDouble();
  RxnDouble max_acc = RxnDouble();
  Rxn<LocationMarkerPosition> currentPosition = Rxn<LocationMarkerPosition>();
  LocationMarkerPosition? lastPosition;

  RxDouble radius = 200.0.obs;
  var quantity = 1;
  RxDouble intensity = 1.0.obs;
  Rx<Color> circleColor = Colors.transparent.obs;
  Rx<int> heatColor = 0.obs;
  RxDouble speed = 0.0.obs;
  late final bounds;

  late List<Map<double, MaterialColor>> colorMaps;

  List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];
  final RxList<WeightedLatLng> data1 = <WeightedLatLng>[].obs;
  final RxList<WeightedLatLng> data2 = <WeightedLatLng>[].obs;
  final RxList<List<WeightedLatLng>> datas = <List<WeightedLatLng>>[].obs;
  final RxList<List<WeightedLatLng>> polygons_data =
      <List<WeightedLatLng>>[].obs;
  final RxList<LatLng> polygon_points = <LatLng>[].obs;
  List<Map<String, LatLng?>> last_points = [];

  final RxList<Polygon> polygon_widgets = <Polygon>[].obs;
  final RxList<Marker> marker_widgets = <Marker>[].obs;
  RxList<WeightedLatLng> layerList = RxList<WeightedLatLng>();
  //List<<List>WeightedLatLng>> cache_data = [];
  String? direction;
  //RxList<WeightedLatLng> data = [].obs;
  DateTime _lastPostTime = DateTime.now();
  Rx<Color> heat_color = Colors.red.obs;
  final SettingsController _settingsController = Get.put(SettingsController());

  RxList<HeatMapLayer> heatmapLayers = RxList();

  // The minimum time interval between http.post calls.
  final Duration _debounceTime = const Duration(milliseconds: 2000);
  late cor.LatLng lastCircleLatLng;

  Map<String, cor.LatLng?> getPolygonPoints() {
    double metersToDegrees = 1 / 111000;
    double halfSizeInDegrees = 50 * metersToDegrees;

    // Calculate the corner coordinates
    cor.LatLng topLeft = cor.LatLng(
        currentPosition.value!.latitude + halfSizeInDegrees,
        currentPosition.value!.longitude - halfSizeInDegrees);
    cor.LatLng topRight = cor.LatLng(
        currentPosition.value!.latitude + halfSizeInDegrees,
        currentPosition.value!.longitude + halfSizeInDegrees);
    cor.LatLng bottomRight = cor.LatLng(
        currentPosition.value!.latitude - halfSizeInDegrees,
        currentPosition.value!.longitude + halfSizeInDegrees);
    cor.LatLng bottomLeft = cor.LatLng(
        currentPosition.value!.latitude - halfSizeInDegrees,
        currentPosition.value!.longitude - halfSizeInDegrees);

    Map<String, cor.LatLng?> polygonPoints = {
      "tl": topLeft,
      "tr": topRight,
      "br": bottomRight,
      "bl": bottomLeft,
    };

    if (last_points.isNotEmpty) {
      Map<String, LatLng?> lastPolygon = last_points.last;
      if (direction != null) {
        switch (direction) {
          case "up":
            polygonPoints = {
              "tl": topLeft,
              "tr": topRight,
              "br": lastPolygon["tr"],
              "bl": lastPolygon["tl"],
            };
            break;
          case "down":
            polygonPoints = {
              "tl": lastPolygon["bl"],
              "tr": lastPolygon["br"],
              "br": bottomRight,
              "bl": bottomLeft
            };
            break;
          case "left":
            polygonPoints = {
              "tl": topLeft,
              "tr": lastPolygon["tl"],
              "br": lastPolygon['bl'],
              "bl": bottomLeft,
            };
            break;
          case "right":
            polygonPoints = {
              "tl": lastPolygon["tr"],
              "tr": topRight,
              "br": bottomRight,
              "bl": lastPolygon["br"],
            };
            break;
        }
      } else {
        print("no direction");
      }
      // Assuming marker_widgets is a list of widgets to be added to your UI
      /*   marker_widgets.add(Marker(
          child: CircleAvatar(child: Text('0')), point: polygonPoints["tl"]!));
      marker_widgets.add(Marker(
          child: CircleAvatar(child: Text('1')), point: polygonPoints["tr"]!));
      marker_widgets.add(Marker(
          child: CircleAvatar(child: Text('2')), point: polygonPoints["br"]!));
      marker_widgets.add(Marker(
          child: CircleAvatar(child: Text('3')), point: polygonPoints["bl"]!));
    */
    }

    last_points.add(polygonPoints);

    return polygonPoints;
  }

  void updateData(event) async {
    print("checking ranges");
    // Determine the heatColor and circleColor based on accSum.value
    int range = 0;
    if (accSum.value != null) {
      print('accSum.value is ' + accSum.value.toString());

      range = getRangeNumber(accSum.value!);
    } else {
      print("speed is " + speed.value.toString());
      range = getRangeNumber(speed.value);
      print("range is " + range.toString());
    }
// Calculate the distance in degrees for 50 meters to the north, south, east, and west
    //getPolygonPoints();
    //datas.add(data1);
    if (polygon_widgets.isEmpty && data1.isEmpty) {
      print("adding first");
      firstPolygon(range);
    }
    if (heatColor.value == range) {
      print('same');
    } else {
      //getPolygonPoints(false);
    }

    //getPolygonPoints();
    var lastData = data1;
    //data1.clear();

    // Add the starting point to the new points

    var polygone = Polygon(
      label: accSum.value.toString(), //speed.value.toString(),
      borderColor: Colors.red,
      borderStrokeWidth: 0,
      isFilled: true,
      //strokeJoin: StrokeJoin.miter,
      disableHolesBorder: true,
      points: getPolygonPoints()
          .values
          .where((latLng) => latLng != null)
          .map((latLng) => latLng!)
          .toList(),
      //      map((e) => cor.LatLng(e.latLng.latitude, e.latLng.longitude))
      //      .toList(),
      color: colors[range].withOpacity(0.7),
    );
    //polygone.strokeJoin = [];
    print("bound");
    //print(polygone.boundingBox);
    polygon_widgets.add(polygone);

    //polygon_widgets.add(polygone);
    /*} else {
      print("adding new polygon?");
      data1.clear;
      polygon_widgets.add(Polygon(
        label: polygon_widgets.length.toString() + ":" + speed.value.toString(),
        borderStrokeWidth: 0,
        isFilled: true,
        points: data1
            .map((e) => cor.LatLng(e.latLng.latitude, e.latLng.longitude))
            .toList(),
        color: colors[range].withOpacity(0.7),
      ));
    }*/
    /*} else {
      //data1.clear();
      // Clear data1 for the next polygon
      print(heatColor.value);
      print('and');
      print(range);
      print('same');
    }*/
    heatColor.value = range;
    if (range >= 1 && range <= 8) {
      await getData(data1, range);
    }
  }

  String determineDirection(LatLng currentPosition, LatLng previousPosition) {
    double deltaLat = currentPosition.latitude - previousPosition.latitude;
    double deltaLng = currentPosition.longitude - previousPosition.longitude;

    // Calculate the absolute values of the changes
    double absDeltaLat = deltaLat.abs();
    double absDeltaLng = deltaLng.abs();

    // Determine the main direction based on the largest change
    if (absDeltaLat > absDeltaLng) {
      return deltaLat > 0 ? 'up' : 'down';
    } else {
      return deltaLng > 0 ? 'right' : 'left';
    }
  }

  void updateCurrentPosition() async {
    print("updating");
    if (!await Permission.locationWhenInUse.status.isGranted) {
      return;
    }
    //print('listening');
    Geolocator.getPositionStream().listen((position) {
      //print(position.rotation);
      double speedMps = position.speed; // This
      print(speedMps); //is your speed

      speed.value = speedMps;
      print("speed value is" + speed.value.toString());
    });
    mapController.mapEventStream.listen((event) {
      // print(event);
    });
    _streamSubscriptions.add(positionStream.listen((event) {
      //event!.speed;

      if (DateTime.now().difference(_lastPostTime) > _debounceTime) {
        print("reload...");
        // print(accSum.value);
        // Call the http.post function.
        if (currentPosition.value != lastPosition) {
          updateData(event);
          lastCircleLatLng = currentPosition.value!.latLng;
          //print(lastCircleLatLng);
          if (lastPosition != null) {
            direction = determineDirection(
                currentPosition.value!.latLng, lastPosition!.latLng);
            print('direction is ' + (direction ?? 'no'));
          }
          lastPosition = currentPosition.value;
          _lastPostTime = DateTime.now();
        } else {
          // print('no move');
        }
      }
      currentPosition.value = event;
    }));
  }

  void firstPolygon(range) {
    final newPolygon = Polygon(
      label: accSum.value.toString(), //speed.value.toString(),
      borderStrokeWidth: 0,
      isFilled: true,
      points: getPolygonPoints()
          .values
          .where((latLng) => latLng != null)
          .map((latLng) => latLng!)
          .toList(),

      /*   data1
          .map((e) => cor.LatLng(e.latLng.latitude, e.latLng.longitude))
          .toList(),*/
      color: Colors.green.withOpacity(0.7),
    );
    print(polygon_widgets.length);
    print("<<");
    //polygon_widgets.clear();
    polygon_widgets.add(newPolygon);
  }

  void getRandomAcc() {
    accSum.value = 50.0;
  }

  void getAccelerometerValues() async {
    print("getting acc..");

    _streamSubscriptions.add(userAccelerometerEvents.listen(
//    _streamSubscriptions.add(accelerometerEvents.listen(
      (UserAccelerometerEvent event) async {
        final double sum = event.x.abs() + event.y.abs() + event.z.abs();
        accSum.value = sum.roundToDouble();
        if (sum > maxAccSum.value) {
          maxAccSum.value = sum;
        }
        if (DateTime.now().difference(_lastPostTime) > _debounceTime) {
          print("reload...");
          // print(accSum.value);
          // Call the http.post function.
          if (currentPosition.value != lastPosition) {
            updateData(event);
            lastCircleLatLng = currentPosition.value!.latLng;
            //print(lastCircleLatLng);
            if (lastPosition != null) {
              direction = determineDirection(
                  currentPosition.value!.latLng, lastPosition!.latLng);
              print('direction is ' + (direction ?? 'no'));
            }
            lastPosition = currentPosition.value;
            _lastPostTime = DateTime.now();
          } else {
            // print('no move');
          }
        }
        //switch off
        //_handleAccelerometerEvent(event);
      },
      onError: (error) {
        print('some error');
        debugPrint(error);
      },
      cancelOnError: true,
    ));
  }

  void _handleAccelerometerEvent(UserAccelerometerEvent event) async {
    // Check if enough time has passed since the last http.post call.
    if (DateTime.now().difference(_lastPostTime) > _debounceTime) {
      print("reload...");
      print(accSum.value);
      // Call the http.post function.
      if (currentPosition.value != lastPosition) {
        updateData(event);
        lastPosition = currentPosition.value;
        // Update the last post time.
        _lastPostTime = DateTime.now();
      } else {
        print('no move');
      }
    }
  }

  Future getData(some_data, range) async {
    print(polygon_widgets.length);
    print('getting data');

    List<List<double>> new_data = List.generate(
        //quantity,
        quantity,
        (index) => [
              currentPosition.value?.latitude ?? 0.0 + offSetDistance,
              currentPosition.value?.longitude ?? 0.0 + offSetDistance,
              heatColor.value.toDouble()
//              getRandomColor(),
//              intensity.value,
            ]);
    some_data.addAll(new_data
        .map((e) => e as List<dynamic>)
        .map((e) => noOffset(cor.LatLng(e[0], e[1]), e[2]))
        .toList());
    //some_data.addAll(getPolygonPoints());
  }

  // Assign
  Future getLocation() async {
    if (!await Permission.locationWhenInUse.status.isGranted) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();

    currentPosition.value = LocationMarkerPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  getRandomColor() {
    final random = Random();
    final values = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0];
    print(values[random.nextInt(values.length)]);
    return values[random.nextInt(values.length)];
  }

  double sumAccelerometerValues() {
    return accelerometerListValues.fold(
        0.0, (previous, current) => previous + current);
  }
}
