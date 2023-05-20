import 'package:flutter/material.dart';

double screenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double screenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double viewInsetBottom(BuildContext context) {
  return MediaQuery.of(context).viewInsets.bottom;
}

double defaultHorizontalPadding(BuildContext context) {
  return MediaQuery.of(context).size.width * 0.042;
}

double defaultVerticalPadding(BuildContext context) {
  return MediaQuery.of(context).size.height * 0.039;
}
