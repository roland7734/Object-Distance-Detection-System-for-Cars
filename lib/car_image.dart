import 'package:flutter/material.dart';

Widget buildCarImage(double carImageHeight) {
  return  Image.asset(
      'assets/images/car.png',
      width: 300,
      height: carImageHeight,
      fit: BoxFit.contain,
    );
}


