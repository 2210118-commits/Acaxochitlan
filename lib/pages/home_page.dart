import 'package:acaxochi/pages/festividades_page.dart';
import 'package:flutter/material.dart';
import 'lugares_page.dart';
import 'cabanas_page.dart';
import 'hoteles_page.dart';
import 'restaurantes_page.dart';
import 'actividades_page.dart';
import '../widgets/carrusel_supabase.dart';
import '../../supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import '../utils/buscador_global.dart';
import '../main.dart';
import 'tienda_hidarte_page.dart';
import 'servicios_emergencia_page.dart';
import 'cerca_de_mi_page.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/ubicacion_helper.dart';
import 'noticias_home_section.dart';
//import para la busqueda
import 'lugar_card.dart';
import 'FavoritosPage.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, RouteAware {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 🔔 CONTADOR DE NOTIFICACIONES
  int notificacionesCount = 0;

  // 🔐 CONTROL ADMIN
  bool esAdmin = false;
  String? fondoHomeUrl;

  bool pausarVideoHome = false;
  

  final TextEditingController _searchController = TextEditingController();
List<dynamic> resultadosBusqueda = [];
bool buscando = false;

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
} 

@override
void didPushNext() {
  setState(() {
    pausarVideoHome = true;
  });
}

@override
void didPopNext() {
  setState(() {
    pausarVideoHome = true;
  });
  cargarFondoHome();
}
  @override
  void initState() {
    super.initState();
    


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    cargarFondoHome();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 🔔 CARGAR NOTIFICACIONES
    cargarNotificaciones();

    // 🔐 VERIFICAR ADMIN
    verificarAdmin();
  }

  Future<void> cargarFondoHome() async {
  try {
    final res = await Supabase.instance.client
        .from('config_app')
        .select('fondo_home')
        .eq('id', 1)
        .single();

    if (!mounted) return;

    setState(() {
      fondoHomeUrl = res['fondo_home'];
    });

  } catch (e) {
    print("Error cargando fondo: $e");
  }
}

  // 🔔 CONSULTA A SUPABASE
  // 🔔 CARGAR NOTIFICACIONES
Future<void> cargarNotificaciones() async {
  try {
    final response = await Supabase.instance.client
        .from('notificaciones')
        .select('id')
        .eq('leida', false);

    if (!mounted) return;

    setState(() {
      notificacionesCount = response.length;
    });
  } catch (e) {
    print('Error al cargar notificaciones: $e');
  }
}

//METODO DE BUSQUEDA
  Future<void> buscarLugares(String texto) async {

  final query = texto.trim();

  if (query.isEmpty) {
    setState(() {
      resultadosBusqueda.clear();
      buscando = false;
    });
    return;
  }

  setState(() {
    buscando = true;
  });

  try {

    final resultados = await BuscadorGlobal.buscar(query);

    if (!mounted) return;

    setState(() {
      resultadosBusqueda = resultados;
      buscando = false;
    });

  } catch (e) {

    print("ERROR BUSQUEDA: $e");

    setState(() {
      buscando = false;
    });

  }
}

  // 🔐 CONSULTA SI EL USUARIO ES ADMIN
  Future<void> verificarAdmin() async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return;

  final res = await SupabaseConfig.client
      .from('admin_profiles')
      .select('id')
      .eq('id', user.id)
      .maybeSingle();

  if (!mounted) return;

  setState(() {
    esAdmin = res != null;
  });
}


  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
  onDrawerChanged: (isOpen) {
    setState(() {
      pausarVideoHome = isOpen;
    });
  },
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
  padding: EdgeInsets.zero,
  child: Stack(
    children: [

      /// IMAGEN DE FONDO
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/menbrete1ho.png"),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeatX,
          ),
        ),
      ),

      /// CAPA OSCURA PARA CONTRASTE
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.60),
              Colors.black.withOpacity(0.30),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
      ),

      /// CONTENIDO
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [

            /// ICONO CIRCULAR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
              child: const Icon(
                Icons.travel_explore,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(width: 15),

            /// TEXTO
             Expanded(
  child: RichText(
    text: const TextSpan(
      children: [
        TextSpan(
          text: "Acaxochitlán\n",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: "\"Pueblo mágico\"",
          style: TextStyle(
            color:  Colors.white,
            fontSize: 26,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
),
          ],
        ),
      ),
    ],
  ),
),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text("Atractivos Turísticos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LugaresPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.house_siding),
              title: const Text("Cabañas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CabanasPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text("Actividades"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActividadesPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.celebration),
              title: const Text("Festividades"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FestividadesPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hotel),
              title: const Text("Hoteles"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HotelesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text("Restaurantes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RestaurantesPage()),
                );
              },
            ),
            ListTile(
  leading: const Icon(Icons.palette),
  title: const Text("Tienda Hidarte"),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TiendaHidartePage(),
      ),
    );
  },
),
ListTile(
  leading: const Icon(Icons.emergency),
  title: const Text("Servicios de emergencia"),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServiciosEmergenciaPage(),
      ),
    );
  },
),
            if (!esAdmin)
  ListTile(
    leading: const Icon(Icons.login),
    title: const Text("Iniciar Sesión"),
    onTap: () {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/login');
    },
  ),

if (esAdmin) ...[
  ListTile(
    leading: const Icon(Icons.admin_panel_settings),
    title: const Text("Panel Administrador"),
    onTap: () {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/admin');
    },
  ),

  ListTile(
    leading: const Icon(Icons.logout, color: Colors.red),
    title: const Text(
      "Cerrar sesión",
      style: TextStyle(color: Colors.red),
    ),
    onTap: () async {
      Navigator.pop(context);
      await Supabase.instance.client.auth.signOut();

      setState(() {
        esAdmin = false;
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/inicio',
        (route) => false,
      );
    },
  ),
],

          ],
        ),
      ),

      appBar: AppBar(
  iconTheme: const IconThemeData(
    color: Color.fromARGB(255, 253, 252, 252),
    size: 32,
  ),

  title: const FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    "EXPLORANDO ACAXOCHITLÁN",
    style: TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.5,
      shadows: [
        Shadow(
          blurRadius: 8,
          color: Colors.black,
          offset: Offset(2,2),
        ),
      ],
    ),
  ),
),

  centerTitle: true,
  backgroundColor: Colors.transparent,
  elevation: 0,

  flexibleSpace: Container(
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage("assets/images/menbrete.png"),

      // 👇 llena todo el espacio
      fit: BoxFit.fill,

      alignment: Alignment.center,
    ),
  ),
  child: Container(
    color: Colors.black.withOpacity(0.35),
  ),
),

  actions: [
  // 🔔 NOTIFICACIONES
  Stack(
    children: [
      IconButton(
        icon: const Icon(
          Icons.notifications,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          setState(() {
            pausarVideoHome = true;
          });

          Navigator.pushNamed(context, '/notificaciones')
              .then((_) {
            setState(() {
              pausarVideoHome = false;
            });

            cargarNotificaciones();
          });
        },
      ),

      if (notificacionesCount > 0)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              '$notificacionesCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  ),

  // ❤️ FAVORITOS
  IconButton(
    icon: const Icon(
      Icons.favorite,
      color: Colors.white,
      size: 28,
    ),
    onPressed: () {
      setState(() {
        pausarVideoHome = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FavoritosPage(),
        ),
      ).then((_) {
        setState(() {
          pausarVideoHome = false;
        });
      });
    },
  ),
],
),

      body: Stack(
        children: [
          Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: fondoHomeUrl != null && fondoHomeUrl!.isNotEmpty
    ? NetworkImage(fondoHomeUrl!)
    : const AssetImage("assets/images/Acx(2).jpeg") as ImageProvider,
      fit: BoxFit.cover,
    ),
  ),
),
          Container(
            height: size.height,
            width: size.width,
            color: const Color.fromARGB(102, 82, 80, 80),
          ),
          SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    const Text(
                      "DESCUBRE LA MAGIA DE ACAXOCHITLÁN",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Pueblo mágico de Hidalgo donde la naturaleza, cultura y tradición se encuentran.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
  controller: _searchController,
  onChanged: (value) {

  setState(() {
    pausarVideoHome = value.isNotEmpty;
  });

  if (value.trim().isEmpty) {
    setState(() {
      resultadosBusqueda.clear();
      buscando = false;
      pausarVideoHome = false;
    });
  } else {
    buscarLugares(value);
  }

},


  decoration: InputDecoration(
  hintText: "¿Qué quieres explorar en Acaxochitlán?",
  filled: true,
  fillColor: Colors.white,

  prefixIcon: const Icon(Icons.search),

  suffixIcon: _searchController.text.isNotEmpty
      ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
  _searchController.clear();

  setState(() {
    resultadosBusqueda.clear();
    buscando = false;
    pausarVideoHome = false;
  });
}
        )
      : null,

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(25),
    borderSide: BorderSide.none,
  ),
),
),

                    ),

                    const SizedBox(height: 25),

                    if (buscando)
  const Padding(
    padding: EdgeInsets.all(10),
    child: CircularProgressIndicator(),
  ),


if (_searchController.text.trim().isNotEmpty && resultadosBusqueda.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Resultados encontrados",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...resultadosBusqueda.map<Widget>((item) {

          switch (item['origen']) {
            case 'lugares':
            case 'restaurantes':
            case 'hoteles':
            case 'festividades':
            case 'actividades':
            case 'cabanas':
              return LugarCard(lugar: item);

            default:
              return const SizedBox();
          }

        }).toList(),
      ],
    ),
  ),



                    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    /// FESTIVIDADES
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
          icon: const Icon(
            Icons.celebration,
            color: Colors.white,
          ),
          label: const Text(
            "Festividades",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            setState(() {
              pausarVideoHome = true;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FestividadesPage(),
              ),
            ).then((_) {
              setState(() {
                pausarVideoHome = false;
              });
            });
          },
        ),
      ),
    ),

    /// CERCA DE MI
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 20),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
          icon: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
          label: const Text(
            "Cerca de mí",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
  final permitido =
      await UbicacionHelper
          .solicitarPermisoUbicacion(
    context,
  );

  if (!permitido) return;

  if (!mounted) return;

  setState(() {
    pausarVideoHome = true;
  });

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CercaDeMiPage(),
    ),
  );

  if (!mounted) return;

  setState(() {
    pausarVideoHome = false;
  });
},
        ),
      ),
    ),
  ],
),

                    const SizedBox(height: 80),

                    // 🖼️ CARRUSEL + BOTÓN SOLO ADMIN
                    Stack(
                      children: [
                        CarruselSupabase(esAdmin: esAdmin, pausarVideo: pausarVideoHome,),
                        if (esAdmin)
                          Positioned(
                            right: 14,
                            top: 40,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor:
                                  Colors.blueAccent,
                              child: const Icon(
                                  Icons.add_a_photo),
                              onPressed: () {
                                Navigator.pushNamed(
                                    context,
                                    '/subir-imagen');
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const NoticiasHomeSection(),

                    const SizedBox(height: 15),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
