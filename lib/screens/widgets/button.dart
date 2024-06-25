import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget createButton(
    double containerWidth,
    double containerHeight,
    void Function()? func,
    String text,
    Color textColor,
    double fontSize,
    Color primary,
    Color secondary,
    Color background,
    Color shadow) {
  return Container(
    width: containerWidth,
    height: containerHeight,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30.0),
      gradient: LinearGradient(colors: [primary, secondary]),
    ),
    child: ElevatedButton(
      onPressed: func,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        shadowColor: shadow,
      ),
      child: Text(
        text,
        style: GoogleFonts.inriaSans(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
