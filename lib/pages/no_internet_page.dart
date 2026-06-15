import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:acaxochi/services/connectivity_service.dart';
import '../supabase/supabase_client.dart';
import 'home_page.dart';

class NoInternetPage extends StatefulWidget {
  const NoInternetPage({super.key});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  bool verificando = false;

  /// Verifica que exista conexión REAL a Internet.
  Future<bool> tieneInternet() async {
    final resultados = await Connectivity().checkConnectivity();

    final hayRed =
        resultados.contains(ConnectivityResult.wifi) ||
        resultados.contains(ConnectivityResult.mobile) ||
        resultados.contains(ConnectivityResult.ethernet);

    if (!hayRed) {
      return false;
    }

    return await InternetConnection().hasInternetAccess;
  }

  Future<void> verificarConexion() async {
    setState(() {
      verificando = true;
    });

    final conectado = await tieneInternet();

    if (!mounted) return;

    if (conectado) {
      try {
        await SupabaseConfig.initialize();
      } catch (_) {
        // Ignorar si ya está inicializado
      }

      if (!mounted) return;
      ConnectivityService.internetRecuperado();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        verificando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aún no hay conexión a Internet.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 70,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sin conexión a internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Se requiere conexión a internet para acceder a la aplicación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: verificando ? null : verificarConexion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: verificando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Reintentar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}