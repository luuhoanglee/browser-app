import 'package:flutter/material.dart' show TextStyle, FontWeight;
import 'package:sizer/sizer.dart';

class AppStyle {
  static final customSize = 6.sp;
  static const TextStyle customMontserrat = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: 'Montserrat',
  );

  static const TextStyle h6 = TextStyle(

  );

  static const TextStyle customRubik = TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: 'Rubik',
  );

  static final TextStyle h9 = TextStyle(
    fontSize: 12.sp + customSize,
    fontWeight: FontWeight.w500,
    fontFamily: 'Montserrat',
  );
  static final TextStyle h10 = TextStyle(
    fontSize: 14.sp + customSize,
    fontWeight: FontWeight.w300,
    fontFamily: 'Rubik',
  );
  static final TextStyle h11 = TextStyle(
    fontSize: 12.sp + customSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Montserrat',
  );
  static final TextStyle h12 = TextStyle(
    fontSize: 16.sp + customSize,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w500,
  );
  static final TextStyle h13 = TextStyle(
    fontSize: 10.sp + customSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Montserrat',
  );
  static final TextStyle h14 = TextStyle(
    fontSize: 14.sp + customSize,
    fontFamily: 'Rubik',
  );
}