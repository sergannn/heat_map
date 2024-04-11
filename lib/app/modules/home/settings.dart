import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settingsController.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController settingsController = Get.put(SettingsController());
  String x = '';
  String y = '';
  String z = '';
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    x = await settingsController.getX();
    y = await settingsController.getY();
    setState(() {
      // x = xValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Радиус:'),
            TextField(
              controller: TextEditingController(text: z),
              onChanged: (value) => settingsController.z = value,
            ),
            Text('От:'),
            TextField(
              controller: TextEditingController(text: x),
              onChanged: (value) => settingsController.x = value,
            ),
            Text('До:'),
            TextField(
              controller: TextEditingController(text: y),
              onChanged: (value) => settingsController.y = value,
            ),
            /*Text('Z:'),
            TextField(
              onChanged: (value) => settingsController.z = value,
            ),*/
            ElevatedButton(
              onPressed: () async {
                await settingsController.saveData();
                final String data = await settingsController.getData();
                print(data);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
