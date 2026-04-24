import 'package:flutter/widgets.dart';

/// Radius tokens. Cards cap at 16, buttons at 12 \u2014 never fully rounded.
class NeoRadius {
  NeoRadius._();

  static const double sm  = 6;
  static const double md  = 10;
  static const double lg  = 12;
  static const double xl  = 16;
  static const double xxl = 20;
  static const double pill = 999;

  static const BorderRadius borderSm  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl  = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
}

class NeoBorderWidth {
  NeoBorderWidth._();

  static const double thin  = 1;
  static const double base  = 2;
  static const double thick = 3;
}
