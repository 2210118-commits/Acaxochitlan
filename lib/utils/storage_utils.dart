// lib/utils/storage_utils.dart

String obtenerRutaStorage(String url) {
  final uri = Uri.parse(url);

  // Nombre del bucket
  const bucket = 'restaurantes';

  final index = uri.path.indexOf('$bucket/');
  if (index == -1) return '';

  return uri.path.substring(
    index + bucket.length + 1,
  );
}
