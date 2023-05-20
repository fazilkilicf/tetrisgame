// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Pixel extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  var color;

  Pixel({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
    );
  }
}
