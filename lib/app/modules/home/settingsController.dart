import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  // Initialize variables
  String _x = '';
  String _y = '';
  String _z = '';

  // Getters
  String get x => _x;
  String get y => _y;
  String get z => _z;

  // Setters
  set x(String value) => _x = value;
  set y(String value) => _y = value;
  set z(String value) => _z = value;

  // Function to save data
  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('from', _x);
    await prefs.setString('to', _y);
    await prefs.setString('z', _z);
  }

  Future<String> getX() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String x = prefs.getString('from') ?? "5";
    return x;
  }

  Future<String> getY() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String y = prefs.getString('to') ?? "100";
    return y;
  }

  // Function to retrieve data
  Future<String> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String x = prefs.getString('from') ?? '';
    String y = prefs.getString('to') ?? '';
    String z = prefs.getString('z') ?? '';
    return 'X: $x, Y: $y, Z: $z';
  }
}
