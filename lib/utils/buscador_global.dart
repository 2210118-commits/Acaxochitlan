import 'package:supabase_flutter/supabase_flutter.dart';

class BuscadorGlobal {

  static Future<List<Map<String, dynamic>>> buscar(String texto) async {

    final query = texto.trim().toLowerCase();

    if (query.isEmpty) return [];

    final client = Supabase.instance.client;

    try {

      final response = await client
          .from('lugares')
          .select()
          .limit(100);

      final responseFestividades = await client
    .from('festividades')
    .select()
    .limit(100);

    final responseActividades = await client
    .from('publicaciones')
    .select()
    .limit(100);

      List<Map<String, dynamic>> resultados = [];

      /// separar palabras de la frase
      List<String> palabras = query.split(" ");

      /// detectar intención
      String? filtroTipo;

      if (query.contains("comer") ||
          query.contains("restaurante") ||
          query.contains("restaurantes") ||
          query.contains("restau") ||
          query.contains("comida") ||
          query.contains("cenar")) {
        filtroTipo = "restaurante";
      }

      if (query.contains("visitar") ||
          query.contains("ir") ||
          query.contains("lugar") ||
          query.contains("viajar") ||
          query.contains("atractivo") ||
          query.contains("turistico")) {
        filtroTipo = "lugar_turistico";
      }

      if (query.contains("hotel") ||
          query.contains("dormir") ||
          query.contains("hospedar") ||
          query.contains("hospedaje")) {
        filtroTipo = "hotel";
      }

      if (query.contains("fiesta") ||
    query.contains("festival") ||
    query.contains("festejando") ||
    query.contains("evento") ||
    query.contains("celebracion") ||
    query.contains("festividad")) {
  filtroTipo = "festividad";
}      

      if (query.contains("actividad") ||
    query.contains("evento") ||
    query.contains("cosas") ||
    query.contains("hacer") ||
    query.contains("plan")) {
  filtroTipo = "actividad";
}

      if (query.contains("cabaña") ||
          query.contains("cabana")) {
        filtroTipo = "cabana";
      }

      for (final item in response) {

        final data = Map<String, dynamic>.from(item);

        final nombre = (data["nombre"] ?? "").toString().toLowerCase();
        final descripcion = (data["descripcion"] ?? "").toString().toLowerCase();
        final tipo = (data["tipo"] ?? "").toString().toLowerCase();

  
        final platillos = (data["platillos"] ?? "").toString().toLowerCase();

        int score = 0;

        /// coincidencia por intención
        if (filtroTipo != null && tipo == filtroTipo) {
          score += 6;
        }

        /// buscar cada palabra dentro del lugar
        for (String palabra in palabras) {

          if (nombre.contains(palabra)) score += 5;

          if (descripcion.contains(palabra)) score += 3;

          if (platillos.contains(palabra)) score += 2;
        }

        if (score > 0) {

          String categoria = "📍 Lugar";

          if (tipo == "hotel") categoria = "🏨 Hotel";
          if (tipo == "cabana") categoria = "🏡 Cabaña";
          if (tipo == "restaurante") categoria = "🍽 Restaurante";
          if (tipo == "lugar_turistico") categoria = "📍 Lugar turístico";

          resultados.add({
            ...data,
            "titulo": data["nombre"],
            "imagen": data["imagen_principal"],
            "categoria": categoria,
            "origen": "lugares",
            "score": score
          });
        }
      }

      for (final item in responseFestividades) {

  final data = Map<String, dynamic>.from(item);

  final titulo = (data["titulo"] ?? "").toString().toLowerCase();
  final descripcion = (data["descripcion"] ?? "").toString().toLowerCase();

  final imagenes = (data["imagenes"] as List?)
      ?.where((e) => e != null && e.toString().isNotEmpty)
      .toList();

  final videos = (data["videos"] as List?)
      ?.where((e) => e != null && e.toString().isNotEmpty)
      .toList();

  /// 🔥 MISMA LOGICA INTELIGENTE
  String imagenPrincipal = "";

  if (imagenes != null && imagenes.isNotEmpty) {
    imagenPrincipal = imagenes.first.toString();
  } else if (videos != null && videos.isNotEmpty) {
    imagenPrincipal = videos.first.toString();
  }

  int score = 0;

  if (filtroTipo == "festividad") {
    score += 6;
  }

  for (String palabra in palabras) {
    if (titulo.contains(palabra)) score += 5;
    if (descripcion.contains(palabra)) score += 3;
  }

  if (score > 0) {

    resultados.add({
      ...data,

      "imagen_principal": imagenPrincipal,
      "es_video": (imagenes == null || imagenes.isEmpty) &&
            (videos != null && videos.isNotEmpty),
      "nombre": data["titulo"] ?? "",
      "titulo": data["titulo"] ?? "",
      "descripcion": data["descripcion"] ?? "",

      "imagenes": imagenes ?? [],
      "videos": videos ?? [],

      "fecha_inicio": data["fecha_inicio"] ?? "",
      "fecha_fin": data["fecha_fin"] ?? "",

      "categoria": "🎉 Festividad",
      "origen": "festividades",
      "score": score
    });
  }
}

for (final item in responseActividades) {

  final data = Map<String, dynamic>.from(item);

  final titulo = (data["titulo"] ?? "").toString().toLowerCase();
  final descripcion = (data["descripcion"] ?? "").toString().toLowerCase();

  final imagenes = (data["imagenes"] as List?)
      ?.where((e) => e != null && e.toString().isNotEmpty)
      .toList();

  final videos = (data["videos"] as List?)
      ?.where((e) => e != null && e.toString().isNotEmpty)
      .toList();

  /// 🔥 LOGICA INTELIGENTE
  String imagenPrincipal = "";

  if (imagenes != null && imagenes.isNotEmpty) {
    imagenPrincipal = imagenes.first.toString();
  } else if (videos != null && videos.isNotEmpty) {
    imagenPrincipal = videos.first.toString(); // 👈 video como fallback
  }

  int score = 0;

  if (filtroTipo == "actividad") {
    score += 6;
  }

  for (String palabra in palabras) {
    if (titulo.contains(palabra)) score += 5;
    if (descripcion.contains(palabra)) score += 3;
  }

  if (score > 0) {

    resultados.add({
      ...data,

      "imagen_principal": imagenPrincipal,
      "es_video": (imagenes == null || imagenes.isEmpty) &&
            (videos != null && videos.isNotEmpty),
      "nombre": data["titulo"] ?? "",
      "titulo": data["titulo"] ?? "",
      "descripcion": data["descripcion"] ?? "",

      "imagenes": imagenes ?? [],
      "videos": videos ?? [],

      "categoria": "🎯 Actividad",
      "origen": "actividades",
      "score": score
    });
  }
}

      /// ordenar resultados por relevancia
      resultados.sort(
        (a, b) => (b["score"] as int).compareTo(a["score"] as int),
      );

      return resultados;

    } catch (e) {

      print("ERROR BUSQUEDA GLOBAL: $e");

      return [];
    }
  }
}