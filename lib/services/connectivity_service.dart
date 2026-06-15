import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../pages/no_internet_page.dart';

class ConnectivityService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool mostrandoNoInternet = false;

  static void iniciar() {
    _subscription?.cancel();

    _subscription =
        Connectivity().onConnectivityChanged.listen((_) async {
      final tieneInternet =
          await InternetConnection().hasInternetAccess;

      if (!tieneInternet && !mostrandoNoInternet) {
        mostrandoNoInternet = true;

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const NoInternetPage(),
          ),
          (route) => false,
        );
      }
    });
  }

  static void internetRecuperado() {
    mostrandoNoInternet = false;
  }

  static void dispose() {
    _subscription?.cancel();
  }
}