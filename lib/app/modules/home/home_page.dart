import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'home_controller.dart';
import 'settings.dart';

import 'home_controller_utils.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text('Settings'),
              onTap: () {
                // Navigate to the settings page
                Navigator.of(context).pop(); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            // Add other list tiles for other pages
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('A1'),
        centerTitle: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRowVisible = false;
  HomeController controller = Get.find<HomeController>(); //
  final StreamController<void> _rebuildStream = StreamController.broadcast();
  Map<double, MaterialColor> colorMap = {
    0.0: Colors.red,
    1.0: Colors.blue,
  };
  List<CircleMarker> tap_circles = [];
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
// Usage
  List<CircleMarker> random_circles = [];
  List<Polyline> polylines = [];
  List<HeatMapLayer> heatmaplayers = [];
  List<Polygon> polygons = [];
  List<CircleMarker> generateSmallerCircles(
      LatLng center, double radius, int count, double smallerRadius) {
    List<CircleMarker> smallerCircles = [];
    double angleStep =
        360 / count; // Calculate the angle step for even distribution

    for (int i = 0; i < count; i++) {
      double angle = angleStep * i; // Calculate the angle for this circle
      double radian = angle * (pi / 180); // Convert angle to radian

      // Calculate the offset in meters for the smaller circle
      double offsetX = (radius + smallerRadius) * cos(radian);
      double offsetY = (radius + smallerRadius) * sin(radian);

      // Convert the offset in meters to latitude and longitude
      // Note: This conversion assumes a spherical Earth, which is a simplification.
      // For more accurate results, consider using a library that can handle geographic coordinates.
      double newLatitude =
          center.latitude + (offsetY / 111111); // Approximate conversion
      double newLongitude = center.longitude +
          (offsetX / (111111 * cos(center.latitude * (pi / 180))));
      bool isRandomColorCircle = i == Random().nextInt(count);
      // Create a new CircleMarker for the smaller circle
      smallerCircles.add(CircleMarker(
        point: LatLng(newLatitude, newLongitude),
        radius: smallerRadius, // Example radius for smaller circles
        // color: colors[0].withOpacity(0.2),
        color: //isRandomColorCircle
            //? colors[Random().nextInt(colors.length)]
            //    .withOpacity(Random().nextDouble())
            colors[0].withOpacity(0),

        //color: colors[Random().nextInt(colors.length)].withOpacity(0.5),
        useRadiusInMeter: true,
      ));
    }

    return smallerCircles;
  }

  void _showDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.find<HomeController>().setIntensity(controller.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  initState() {
    //final controller = Get.find<HomeController>();
    super.initState();
  }

  void _toggleRowVisibility() {
    setState(() {
      _isRowVisible = !_isRowVisible;
    });
  }

  @override
  dispose() {
    _rebuildStream.close();
    super.dispose();
  }

  Widget getDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text('Your Name'),
            accountEmail: Text('youremail@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'A',
                style: TextStyle(fontSize: 40.0),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              // Navigate to the home page
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Polygon createPolygonFromOffsetPoints(
      List<WeightedLatLng> weightedLatLngs, double offsetDistance) {
    List<LatLng> points = [];
    for (var weightedLatLng in weightedLatLngs) {
      points.addAll(
          controller.calculateOffsetPoints(weightedLatLng, offsetDistance));
    }
    return Polygon(points: points);
  }

  Widget buttonsRow() {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Row(children: <Widget>[
        /*   Visibility(
            visible: _isRowVisible,
            child: Row(children: [
              Text("От" + controller.from.value.toString()),
              Text("До" + controller.to.value.toString())
            ])),*/
        /*FloatingActionButton(
          onPressed: () {
            controller.increaseRadius();
          },
          child: Text("R+"),
        ),
        FloatingActionButton(
          onPressed: () {
            controller.decreaseRadius();
          },
          child: Text("R-"),
        ),*/
        FloatingActionButton(
          onPressed: controller.locateMe,
          tooltip: 'Switch Gradient',
          child: const Icon(Icons.navigation),
        )
      ]),
      Row(children: [
        FloatingActionButton(
          onPressed: _toggleRowVisibility,
          child: Text("Верхняя панель"),
        ),
        FloatingActionButton(
          onPressed: controller.polygon_widgets.clear,
          child: Text("Clear"),
        ),
        FloatingActionButton(
          onPressed: () {
            controller.zoomIn();
          },
          tooltip: 'Zoom In',
          child: Icon(Icons.zoom_in),
        ),
        SizedBox(height: 10),
        FloatingActionButton(
          onPressed: () {
            controller.zoomOut();
          },
          tooltip: 'Zoom Out',
          child: Icon(Icons.zoom_out),
        )
      ])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _rebuildStream.add(null);
    });
    final position = controller.currentPosition.value;
    double offsetDistance = 0.0033;
    final row = Obx(() {
      return Positioned(
          child: Column(children: [
        Row(children: [
          FloatingActionButton(
              onPressed: () {
                controller.changeQuantity(true);
              },
              child: Text('change quantity plus')),
          FloatingActionButton(
              onPressed: () {
                controller.changeIntensity(true);
              },
              child: Text('change intensity plus')),
          FloatingActionButton(
              onPressed: () {
                controller.changeIntensity(false);
              },
              child: Text('change int -')),
          FloatingActionButton(
              onPressed: () {
                controller.changeQuantity(false);
              },
              child: Text('change Quan -')),
          Text("intensity:${controller.intensity}"),
          Text("quantity:${controller.quantity}")
        ]),
        Row(children: [
          FloatingActionButton(
              onPressed: () {
                //controller.getRandomAcc();
                controller.data1.clear();
              },
              child: Text("очистить")),
          FloatingActionButton(
            onPressed: () => _showDialog(context, 'First Value'),
            child: Icon(Icons.edit),
          ),
          Text(controller.data1.length.toString()),
          Text(
              style: const TextStyle(fontSize: 20, color: Colors.red),
              controller.maxAccSum.value.toString()),
        ]),
        Row(children: [
          SizedBox(
              width: 150,
              child: Text(controller.currentPosition.value!.latLng.toString()))
        ])
      ]));
    });
    //final random_spuren =
    //controller.mapController

    final spuren = Obx(() {
      return CircleLayer(
        circles: controller.data1
            .map((e) => CircleMarker(
                point: LatLng(e.latLng.latitude, e.latLng.longitude),
                color: colors[e.intensity.toInt()].withOpacity(0.4),
                radius: 500,
                useRadiusInMeter: true))
            .toList(),
      );
    });
    final circles = Obx(() {
      final position = controller.currentPosition.value;
      List<CircleMarker> smallerCircles = generateSmallerCircles(
          LatLng(controller.currentPosition.value!.latitude,
              controller.currentPosition.value!.longitude),
          500, // Radius of the larger circle
          10,
          200 // Number of smaller circles
          );

      //double _op = Random().nextDouble();
      double _op = 0.2;

// number of km per degree = ~111km (111.32 in google maps, but range varies
// between 110.567km at the equator and 111.699km at the poles)
//
// 111.32km = 111320.0m (".0" is used to make sure the result of division is
// double even if the "meters" variable can't be explicitly declared as double)

      var rightLeftOffset = offsetDistance * 2;
      LatLng rightLocation =
          LatLng(position!.latitude, position.longitude + rightLeftOffset);
      LatLng leftLocation =
          LatLng(position!.latitude, position!.longitude - rightLeftOffset);
      LatLng topLocation =
          LatLng(position!.latitude + offsetDistance, position!.longitude);
      LatLng bottomLocation =
          LatLng(position!.latitude - offsetDistance, position!.longitude);
      double sub_radius = 40;
      // Calculate corner locations
      /*LatLng topRightLocation = LatLng(position.latitude + offsetDistance,
          position.longitude + offsetDistance * 2);
      LatLng topLeftLocation = LatLng(position.latitude + offsetDistance,
          position.longitude - offsetDistance * 2);
      LatLng bottomRightLocation = LatLng(position.latitude - offsetDistance,
          position.longitude + offsetDistance);
      LatLng bottomLeftLocation = LatLng(position.latitude - offsetDistance,
          position.longitude - offsetDistance);*/

      return CircleLayer(circles: [
        CircleMarker(
          point: LatLng(
            controller.currentPosition.value!.latitude,
            controller.currentPosition.value!.longitude,
          ),
          radius: 1000, // Adjust the radius as needed
          color: colors[0].withOpacity(0.2),
          useRadiusInMeter: true,
          //borderStrokeWidth: 2.0,
          borderColor: const Color.fromARGB(255, 228, 242, 254),
        ),
        CircleMarker(
          point: LatLng(
            controller.currentPosition.value!.latitude,
            controller.currentPosition.value!.longitude,
          ),
          radius: 500, // Adjust the radius as needed
          color: colors[controller.heatColor.value].withOpacity(0.2),
          useRadiusInMeter: true,
          //borderStrokeWidth: 2.0,
          borderColor: const Color.fromARGB(255, 228, 242, 254),
        ),
        ...smallerCircles,
        CircleMarker(
          point: LatLng(
            controller.currentPosition.value!.latitude,
            controller.currentPosition.value!.longitude,
          ),
          //controller.accelerometerDelta.value ??
          radius: 100,
          useRadiusInMeter: true,
          color: Colors.green.withOpacity(0.4), //controller.circleColor.value,
        ),
      ]);
    });

    final map = Obx(() {
      /*controller.positionStream.listen((_) {
        _rebuildStream.add(null);
      });*/
      var datas = controller.datas;
      var polygons = controller.polygon_widgets;
      var markers = controller.marker_widgets;
      print(polygons.length);
      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          //onTap: (TapPosition position, LatLng pos) {},
          initialCenter: controller.currentPosition.value == null
              ? const LatLng(1.8827, -6.0400)
              : LatLng(position!.latitude, position.longitude),
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            //tileProvider: ,
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          //if (random_circles.isNotEmpty) CircleLayer(circles: random_circles),
          //if (controller.data1.isNotEmpty) spuren,
          /*if (controller.data1.isNotEmpty)
            HeatMapLayer(
              heatMapDataSource:
                  InMemoryHeatMapDataSource(data: controller.data1),
              heatMapOptions: HeatMapOptions(
                  radius: 20, blurFactor: 1, gradient: colorMap, minOpacity: 1),
              reset: _rebuildStream.stream,
            ),*/
          // if (polygons.isNotEmpty)

          controller.data1.isNotEmpty
              ? PolygonLayer(
                  polygons: polygons.isEmpty
                      ? [
                          Polygon(
                            label: "Hello",
                            borderStrokeWidth: 40,
                            isFilled: true,
                            points: controller.data1
                                .map((e) => LatLng(
                                    e.latLng.latitude + 0.0,
                                    //  Random().nextDouble() / 10,
                                    e.latLng.longitude))
                                .toList(),
                            color: Colors.green.withOpacity(1),
                          )
                        ]
                      : controller.polygon_widgets)
              : Text('data is empty'),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
          // Convert Iterable<Polygon> to List<Polygon>
          if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),

          //if (controller.polygons.isNotEmpty) polygonsWidget,
          if (controller.data2.isNotEmpty)
            HeatMapLayer(
              heatMapDataSource:
                  InMemoryHeatMapDataSource(data: controller.data2),
              heatMapOptions: HeatMapOptions(
                  radius: 20, blurFactor: 1, gradient: colorMap, minOpacity: 1),
              reset: _rebuildStream.stream,
            ),
          circles,
          controller.headingStream != null
              ? CurrentLocationLayer(
                  followOnLocationUpdate: FollowOnLocationUpdate.always,
                  turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
                  positionStream: controller.positionStream,
                  headingStream: controller.headingStream,
                )
              : Text("loading")
        ],
      );
    });

    return Scaffold(
        drawer: getDrawer(),
        appBar: AppBar(
          title: Text(widget.title),
        ),
        backgroundColor: Colors.pink,
        body: Stack(
          children: [
            Center(
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: Container(child: map)),
            Visibility(
              visible: _isRowVisible,
              child: row, // Your row widget
            ),
          ],
        ),
        floatingActionButton: //Text("a"));
            buttonsRow()); // This trailing comma makes auto-formatting nicer for build methods.
  }
}
