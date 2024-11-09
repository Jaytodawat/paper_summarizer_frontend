// ignore_for_file: file_names

import 'package:flutter/material.dart';

class ResponseProvider extends ChangeNotifier {
  final _responseText = StringBuffer();
  bool _isLoading = false;

  String get responseText => _responseText.toString();

  void addResponse(String response) {
    _responseText.write(response);
    notifyListeners();
  }

  void clearResponse() {
    _responseText.clear();
    notifyListeners();
  }

  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
}
