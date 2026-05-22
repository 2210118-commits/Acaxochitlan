import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';

// IMPORTS ORIGINALES
import 'pages/home_page.dart';
import 'pages/lugares_page.dart';
import 'pages/cabanas_page.dart';
import 'pages/actividades_page.dart';
import 'pages/festividades_page.dart';
import 'pages/hoteles_page.dart';
import 'pages/restaurantes_page.dart';
import 'pages/login_page.dart';
import 'pages/notificaciones_page.dart';
import 'pages/tienda_hidarte_page.dart';
import '../pages/servicios_emergencia_page.dart';
import 'pages/admin/admin_fondo_home_page.dart';

// NUEVOS IMPORTS
import 'supabase/supabase_client.dart';
import 'pages/admin/admin_home_page.dart';
import 'pages/admin/crear_publicacion_page.dart';
import 'pages/publicaciones/publicaciones_page.dart';
import 'pages/subir_imagen_carrucel_page.dart';
import 'pages/HotelesCabanasPage.dart';
import 'pages/admin/admin_servicios_emergencia_page.dart';
import 'pages/subir_tienda_hidarte_page.dart';
import 'pages/admin/admin_noticias_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'pages/no_internet_page.dart';

// 🔥 FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 🔔 Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// 🔔 Handler para notificaciones en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WINDOWS
  if (Platform.isWindows) {
    try {
      await SupabaseConfig.initialize();
      print("✅ Supabase Windows iniciado");
    } catch (e) {
      print("❌ Supabase Windows error: $e");
    }

    runApp(const TurismoApp());
    return;
  }

  // FIREBASE separado
  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones importantes.',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("✅ Firebase iniciado");
  } catch (e) {
    print("❌ Firebase error: $e");
  }

  // SUPABASE separado
  try {
    await SupabaseConfig.initialize();
    print("✅ Supabase iniciado");
  } catch (e) {
    print("❌ Supabase error: $e");
  }

  runApp(const TurismoApp());
}

class TurismoApp extends StatefulWidget {
  const TurismoApp({super.key});

  @override
  State<TurismoApp> createState() => _TurismoAppState();
}

class _TurismoAppState extends State<TurismoApp> {
  @override
  void initState() {
    super.initState();
    _configurarFCM();
  }

  Future<void> _configurarFCM() async {
    if (Platform.isWindows) return;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 🔔 Pedir permisos
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print("🔔 Permiso: ${settings.authorizationStatus}");

      // 📱 Obtener token
      String? token = await messaging.getToken();
      print("🔥 TOKEN FCM: $token");

      // ✅ Guardar token
      await _guardarTokenEnSupabase(token);

      // ✅ Topic global
      await FirebaseMessaging.instance.subscribeToTopic("all");

      // 🔔 Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 Notificación en foreground");

        if (message.notification != null) {
          flutterLocalNotificationsPlugin.show(
            message.hashCode,
            message.notification!.title,
            message.notification!.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Notificaciones Importantes',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("❌ Error configurando FCM: $e");
    }
  }

  Future<void> _guardarTokenEnSupabase(String? token) async {
    if (token == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? dispositivoId = prefs.getString('dispositivo_id');

      if (dispositivoId == null) {
        dispositivoId = const Uuid().v4();
        await prefs.setString('dispositivo_id', dispositivoId);
      }

      await SupabaseConfig.client.from('dispositivos').upsert({
        'dispositivo_id': dispositivoId,
        'fcm_token': token,
      });
    } catch (e) {
      print("❌ Error guardando token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explorando Acaxochitlán',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      locale: const Locale('es'),

      supportedLocales: const [
        Locale('es'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: FutureBuilder<List<ConnectivityResult>>(
  future: Connectivity().checkConnectivity(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final resultados = snapshot.data!;

    final conectado =
        resultados.contains(
          ConnectivityResult.wifi,
        ) ||
        resultados.contains(
          ConnectivityResult.mobile,
        ) ||
        resultados.contains(
          ConnectivityResult.ethernet,
        );

    return conectado
        ? const HomePage()
        : const NoInternetPage();
  },
),

      navigatorObservers: [routeObserver],

      onGenerateRoute: (settings) {
        final session = Supabase.instance.client.auth.currentSession;

        switch (settings.name) {
          case '/admin':
            return MaterialPageRoute(
              builder: (_) =>
                  session == null ? const LoginPage() : const AdminHomePage(),
            );

          case '/crear_publicacion':
            return MaterialPageRoute(
              builder: (_) => session == null
                  ? const LoginPage()
                  : CrearPublicacionPage(),
            );

          case '/publicaciones':
            return MaterialPageRoute(
              builder: (_) => session == null
                  ? const LoginPage()
                  : PublicacionesPage(),
            );

          case '/actividades':
            return MaterialPageRoute(
              builder: (_) => const ActividadesPage(),
            );

          case '/festividades':
            return MaterialPageRoute(
              builder: (_) => const FestividadesPage(),
            );
        }

        return null;
      },

      routes: {
        '/inicio': (context) => const HomePage(),
        '/lugares': (context) => const LugaresPage(),
        '/cabanas': (context) => const CabanasPage(),
        '/actividades': (context) => const ActividadesPage(),
        '/festividades': (context) => const FestividadesPage(),
        '/hoteles': (context) => const HotelesPage(),
        '/restaurantes': (context) => const RestaurantesPage(),
        '/login': (context) => const LoginPage(),
        '/notificaciones': (context) => const NotificacionesPage(),
        '/subir-imagen': (context) => const SubirImagenCarrucelPage(),
        '/hoteles_cabanas': (_) => const HotelesCabanasPage(),
        '/tienda_hidarte': (context) => const TiendaHidartePage(),
        '/servicios_emergencia': (context) =>
            const ServiciosEmergenciaPage(),
        '/admin_servicios_emergencia': (context) =>
            const AdminServiciosEmergenciaPage(),
        '/admin_tienda_hidarte': (context) =>
            const SubirTiendaHidartePage(),
        '/cambiar_fondo_home': (context) =>
            const AdminFondoHomePage(),
        '/admin_noticias': (_) => const AdminNoticiasPage(),
      },
    );
  }
}