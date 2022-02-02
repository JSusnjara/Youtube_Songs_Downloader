import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class MyTheme{
  ThemeData getThemeData(){
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(25, 7, 97, 1),
      selectedItemColor: Color.fromRGBO(205, 220, 57, 1),),
    );
  }
}