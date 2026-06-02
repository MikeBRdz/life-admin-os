import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final Map<String, dynamic> appIcons = {
  'prime': FontAwesomeIcons.amazon,
  'spotify': FontAwesomeIcons.spotify,
  'duolingo': FontAwesomeIcons.duolingo,
  'apple': FontAwesomeIcons.apple,
  'xbox': FontAwesomeIcons.xbox,
  'playstation': FontAwesomeIcons.playstation,
  'youtube': FontAwesomeIcons.youtube,
  'uber': FontAwesomeIcons.uber,
  'guitar': FontAwesomeIcons.guitar,
  'renta': Icons.home_work_outlined,
  'internet': Icons.wifi,
  'luz': Icons.electrical_services,
  'agua': Icons.water_drop_outlined,
  'celular': Icons.phone_android,
  'coche': Icons.directions_car_outlined,
  'gym': Icons.fitness_center,
  'tarjeta': Icons.credit_card,
};

Widget buildAppIcon(String key, {Color? color, double? size}) {
  final iconData = appIcons[key] ?? Icons.help_outline;

  if (iconData is IconData) {
    return Icon(iconData, color: color, size: size);
  } else {
    return FaIcon(iconData, color: color, size: size);
  }
}
