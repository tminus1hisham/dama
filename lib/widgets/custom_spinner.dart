import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

final customSpinner = SpinKitWave(
  itemBuilder: (BuildContext context, int index) {
    return DecoratedBox(decoration: BoxDecoration(color: kBlue));
  },
);
