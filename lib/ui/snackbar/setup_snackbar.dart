import 'package:flutter/material.dart';
import 'package:mobileraker/app/app_setup.locator.dart';
import 'package:stacked_services/stacked_services.dart';

/// The type of snackbar to show
enum SnackbarType { error }

void setupSnackbarUi() {
  final service = locator<SnackbarService>();

  // Registers a config to be used when calling showSnackbar
  service.registerSnackbarConfig(SnackbarConfig(
    titleColor: Colors.white,
    messageColor: Colors.white70,
  ));

  service.registerCustomSnackbarConfig(
      variant: SnackbarType.error,
      config: SnackbarConfig(
        backgroundColor: Colors.red
      ));
}
