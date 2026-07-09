import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';
import '../main.dart';

import '../utils/buscador_global.dart';
import '../utils/ubicacion_helper.dart';


import '../widgets/bottom_nav.dart';
import '../widgets/carrusel_supabase.dart';
import '../widgets/home/home_drawer.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_hero.dart';
import '../widgets/home/home_buttons.dart';
import 'lugar_card.dart';

import 'FavoritosPage.dart';
import 'cerca_de_mi_page.dart';
import 'festividades_page.dart';
import 'noticias_home_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, RouteAware {

  late AnimationController _controller;

  int notificacionesCount = 0;

  bool esAdmin = false;

  bool pausarVideoHome = false;

  String? fondoHomeUrl;

  final ScrollController _scrollController =
      ScrollController();

  final TextEditingController _searchController =
      TextEditingController();

  List<dynamic> resultadosBusqueda = [];

  bool buscando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    routeObserver.subscribe(
      this,
      ModalRoute.of(context)! as PageRoute,
    );
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
      pausarVideoHome = false;
    });

    cargarFondoHome();
  }

  Future<void> cargarFondoHome() async {

    final res = await Supabase.instance.client
        .from("config_app")
        .select("fondo_home")
        .eq("id", 1)
        .single();

    if (!mounted) return;

    setState(() {
      fondoHomeUrl = res["fondo_home"];
    });

  }

  Future<void> cargarNotificaciones() async {

    final response =
        await Supabase.instance.client
            .from("notificaciones")
            .select("id")
            .eq("leida", false);

    if (!mounted) return;

    setState(() {
      notificacionesCount = response.length;
    });

  }

  Future<void> verificarAdmin() async {

    final user =
        SupabaseConfig.client.auth.currentUser;

    if (user == null) return;

    final res = await SupabaseConfig.client
        .from("admin_profiles")
        .select("id")
        .eq("id", user.id)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      esAdmin = res != null;
    });

  }

  Future<void> buscarLugares(String texto) async {

  print("Buscando: $texto");

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

  final resultados = await BuscadorGlobal.buscar(query);

  print("Resultados: ${resultados.length}");

  if (!mounted) return;

  setState(() {
    resultadosBusqueda = resultados;
    buscando = false;
  });
}

@override
void initState() {
  super.initState();

  _searchController.addListener(() {
    setState(() {});
  });

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  cargarFondoHome();
  cargarNotificaciones();
  verificarAdmin();

  _controller.forward();
}

  @override
  void dispose() {

    routeObserver.unsubscribe(this);

    _scrollController.dispose();

    _searchController.dispose();

    _controller.dispose();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF7F5F1),

      drawer: HomeDrawer(
        esAdmin: esAdmin,
      ),

      onDrawerChanged: (value) {

        setState(() {

          pausarVideoHome = value;

        });

      },

      bottomNavigationBar: BottomNav(

        currentIndex: 0,

        onHomePressed: () {

          _scrollController.animateTo(

            0,

            duration: const Duration(
                milliseconds: 500),

            curve: Curves.easeInOut,

          );

        },

      ),

      body: Column(

        children: [

          Builder(

            builder: (context) {

              return HomeHeader(

                notificacionesCount:
                    notificacionesCount,

                onMenu: () {

                  Scaffold.of(context)
                      .openDrawer();

                },

                onNotifications: () {

                  Navigator.pushNamed(
                    context,
                    "/notificaciones",
                  );

                },

                onFavorites: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>
                          const FavoritosPage(),

                    ),

                  );

                },

              );

            },

          ),

          Expanded(

            child: SingleChildScrollView(

              controller: _scrollController,

              child: Column(

                children: [
                  /// =====================================================
/// HERO
/// =====================================================
HomeHero(
  fondoHomeUrl: fondoHomeUrl,
  searchController: _searchController,
  onSearch: buscarLugares,
),

const SizedBox(height: 35),

if (buscando || resultadosBusqueda.isNotEmpty || _searchController.text.isNotEmpty) ...[

  if (buscando)
    const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: CircularProgressIndicator(),
      ),
    )

  else if (resultadosBusqueda.isEmpty)
    const Padding(
      padding: EdgeInsets.all(25),
      child: Text("No se encontraron resultados"),
    )

  else
    ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: resultadosBusqueda.length,
  itemBuilder: (context, index) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.90,
        child: LugarCard(
          lugar: resultadosBusqueda[index],
        ),
      ),
    );
  },
),

] else ...[

/// =====================================================
/// BOTONES
/// =====================================================
HomeButtons(
  onFestividades: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FestividadesPage(),
      ),
    );
  },
  onCercaDeMi: () async {

    final permitido =
        await UbicacionHelper.solicitarPermisoUbicacion();

    if (!permitido) return;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CercaDeMiPage(),
      ),
    );
  },
),


const SizedBox(height: 5),

/// =====================================================
/// CARRUSEL PRINCIPAL
/// =====================================================
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 5,
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: CarruselSupabase(
      esAdmin: esAdmin,
      pausarVideo: pausarVideoHome,
    ),
  ),
),

const SizedBox(height: 1),

/// =====================================================
/// TITULO
/// =====================================================
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 20,
  ),
  child: Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
    children: [

      const Text(
        "Lugares que no te puedes perder",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),

      TextButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/noticias",
          );
        },
        child: const Text(
          "Ver todos",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

    ],
  ),
),

const SizedBox(height: 2),

/// =====================================================
/// NOTICIAS
const NoticiasHomeSection(),

const SizedBox(height: 10),

              ],
              ],
            ),
          ),
        ),
        ]
      ),
    );
  }
}