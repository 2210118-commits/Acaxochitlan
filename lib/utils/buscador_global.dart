import 'package:supabase_flutter/supabase_flutter.dart';

class BuscadorGlobal {

  static bool _cacheCargado = false;

  static List<Map<String, dynamic>> _lugares = [];
  static List<Map<String, dynamic>> _festividades = [];
  static List<Map<String, dynamic>> _actividades = [];
  
  static Future<void> _cargarCache() async {

  if (_cacheCargado) return;

  final client = Supabase.instance.client;

  final results = await Future.wait([

    client
    .from('lugares')
    .select('''
      id,
      nombre,
      descripcion,
      tipo,
      imagen_principal,
      platillos
    '''),

    client
        .from('festividades')
        .select('''
          id,
          titulo,
          descripcion,
          imagenes,
          videos,
          fecha_inicio,
          fecha_fin
        '''),

    client
        .from('publicaciones')
        .select('''
          id,
          titulo,
          descripcion,
          videos,
          imagenes
        '''),
  ]);

  _lugares = List<Map<String, dynamic>>.from(results[0]);
  _festividades = List<Map<String, dynamic>>.from(results[1]);
  _actividades = List<Map<String, dynamic>>.from(results[2]);

  _cacheCargado = true;
} 
  static Future<List<Map<String, dynamic>>> buscar(String texto) async {

    final query = texto.trim().toLowerCase();

    if (query.length < 2) return [];

    try {

    await _cargarCache();

    print("Lugares: ${_lugares.length}");
print("Festividades: ${_festividades.length}");
print("Actividades: ${_actividades.length}");

    final response = _lugares;

    final responseFestividades = _festividades;

    final responseActividades = _actividades;

      List<Map<String, dynamic>> resultados = [];

      /// separar palabras de la frase
      final palabras = query
    .split(" ")
    .where((p) => p.trim().isNotEmpty)
    .toList();

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
        /// Buscar por nombre, descripción, platillos y tipo
for (final palabra in palabras) {

  if (nombre.contains(palabra)) {
    score += 5;
  }

  if (descripcion.contains(palabra)) {
    score += 3;
  }

  if (platillos.contains(palabra)) {
    score += 2;
  }

  // También permitir buscar directamente por el tipo
  if (tipo.contains(palabra)) {
    score += 4;
  }
}

// Si el usuario escribió "restaurante", "hotel", etc. y coincide el tipo,
// darle prioridad.
if (filtroTipo != null && tipo == filtroTipo) {
  score += 10;
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

final imagenes = data["imagenes"] as List? ?? [];
final videos = data["videos"] as List? ?? [];
final titulo = (data["titulo"] ?? "").toString().toLowerCase();
final descripcion = (data["descripcion"] ?? "").toString().toLowerCase();

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

"imagen_principal":
    imagenes.isNotEmpty
        ? imagenes.first
        : (videos.isNotEmpty ? videos.first : ""),

"es_video":
    imagenes.isEmpty && videos.isNotEmpty,

"nombre": data["titulo"] ?? "",
"titulo": data["titulo"] ?? "",
"descripcion": data["descripcion"] ?? "",


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

final imagenes = data["imagenes"] as List? ?? [];
final videos = data["videos"] as List? ?? [];
final titulo = (data["titulo"] ?? "").toString().toLowerCase();
final descripcion = (data["descripcion"] ?? "").toString().toLowerCase();

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

"imagen_principal":
    imagenes.isNotEmpty
        ? imagenes.first
        : (videos.isNotEmpty ? videos.first : ""),

"es_video":
    imagenes.isEmpty && videos.isNotEmpty,

"nombre": data["titulo"] ?? "",
"titulo": data["titulo"] ?? "",
"descripcion": data["descripcion"] ?? "",

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

      return resultados.take(20).toList();

    } catch (e) {

      print("ERROR BUSQUEDA GLOBAL: $e");

      return [];
    }
  }
  static void limpiarCache() {
  _cacheCargado = false;
  _lugares.clear();
  _festividades.clear();
  _actividades.clear();
}
}