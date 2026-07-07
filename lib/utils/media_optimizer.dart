class MediaOptimizer {
  /// Carrusel principal
  static String carrusel(String url) {
    if (!url.contains('/storage/v1/object/public/')) return url;

    return "$url"
        "?width=700"
        "&height=350"
        "&resize=cover"
        "&quality=60"
        "&format=webp";
  }

  /// Galerías
  static String galeria(String url) {
    if (!url.contains('/storage/v1/object/public/')) return url;

    return "$url"
        "?width=1200"
        "&quality=70"
        "&format=webp";
  }

  /// Miniaturas
  static String thumbnail(String url) {
    if (!url.contains('/storage/v1/object/public/')) return url;

    return "$url"
        "?width=350"
        "&quality=55"
        "&format=webp";
  }

  /// Imagen grande
  static String fullscreen(String url) {
    if (!url.contains('/storage/v1/object/public/')) return url;

    return "$url"
        "?width=1800"
        "&quality=80"
        "&format=webp";
  }
}