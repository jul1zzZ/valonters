import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showSuccess(String message) {
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: Colors.green,
    textColor: Colors.white,
    toastLength: Toast.LENGTH_SHORT,
  );
}

void showError(String message) {
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    toastLength: Toast.LENGTH_LONG,
  );
}
