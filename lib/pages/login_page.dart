import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 🔁 CAMBIO: emailCtrl -> userCtrl
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  String errorMessage = "";

  bool _obscurePassword = true;

  Future<void> loginAdmin() async {
    // 🔁 CAMBIO: email -> username
    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Ingresa usuario y contraseña.");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      final supabase = Supabase.instance.client;

      // 🔍 NUEVO: buscar email por username
      final data = await supabase
          .from('admin_profiles')
          .select('email')
          .eq('username', username)
          .single();

      final email = data['email'];

      // 🔐 Login real con email (Supabase Auth)
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.session != null) {
        FocusScope.of(context).unfocus();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin',
          (route) => false,
        );
      }
    } on PostgrestException {
      setState(() => errorMessage = "Usuario no encontrado.");
    } on AuthException {
      setState(() => errorMessage = "Contraseña incorrecta.");
    } catch (_) {
      setState(() => errorMessage = "Error inesperado. Intenta nuevamente.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Icon(
                  Icons.admin_panel_settings,
                  size: 70,
                  color: Theme.of(context).primaryColor,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Acceso Administrador",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                // 🔁 CAMBIO SOLO EN EL LABEL Y CONTROLLER
                TextField(
                  controller: userCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Usuario",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: passCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enableSuggestions: false,
                  autocorrect: false,
                  onSubmitted: (_) => loginAdmin(),
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (errorMessage.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : loginAdmin,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Ingresar",
                            style: TextStyle(fontSize: 16),
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
