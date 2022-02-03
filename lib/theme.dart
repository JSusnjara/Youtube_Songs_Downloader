import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class MyTheme{
  ThemeData getThemeData(){
    return ThemeData(
      brightness: Brightness.dark,

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(25, 7, 97, 1),
          selectedItemColor: Color.fromRGBO(205, 220, 57, 1),),

      textButtonTheme: TextButtonThemeData(style: ButtonStyle(
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.00),)),
        backgroundColor: MaterialStateProperty.all(Color.fromRGBO(25, 7, 97, 1)),
        foregroundColor: MaterialStateProperty.all(Color.fromRGBO(205, 220, 57, 1)),
        textStyle: MaterialStateProperty.all(TextStyle(
          fontWeight: FontWeight.bold
        ))
      )),
    );
  }
}