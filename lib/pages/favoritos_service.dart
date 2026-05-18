import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritosService {
  static const String _localKey = 'favoritos_locales';
  static final supabase = Supabase.instance.client;

  static Future<bool> esFavorito(String lugarId) async {
    final user = supabase.auth.currentUser;

    // Usuario sin login
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final favoritos = prefs.getStringList(_localKey) ?? [];
      return favoritos.contains(lugarId);
    }

    // Usuario con login
    final response = await supabase
        .from('favoritos')
        .select()
        .eq('user_id', user.id)
        .eq('lugar_id', lugarId)
        .maybeSingle();

    return response != null;
  }

  static Future<void> toggleFavorito(String lugarId) async {
    final user = supabase.auth.currentUser;

    // Usuario sin login
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final favoritos = prefs.getStringList(_localKey) ?? [];

      if (favoritos.contains(lugarId)) {
        favoritos.remove(lugarId);
      } else {
        favoritos.add(lugarId);
      }

      await prefs.setStringList(_localKey, favoritos);
      return;
    }

    // Usuario con login
    final existe = await supabase
        .from('favoritos')
        .select()
        .eq('user_id', user.id)
        .eq('lugar_id', lugarId)
        .maybeSingle();

    if (existe != null) {
      await supabase
          .from('favoritos')
          .delete()
          .eq('user_id', user.id)
          .eq('lugar_id', lugarId);
    } else {
      await supabase.from('favoritos').insert({
        'user_id': user.id,
        'lugar_id': lugarId,
      });
    }
  }

  static Future<List<String>> obtenerFavoritosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_localKey) ?? [];
  }
}