import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminServiciosEmergenciaPage extends StatefulWidget {
  const AdminServiciosEmergenciaPage({super.key});

  @override
  State<AdminServiciosEmergenciaPage> createState() =>
      _AdminServiciosEmergenciaPageState();
}

class _AdminServiciosEmergenciaPageState
    extends State<AdminServiciosEmergenciaPage> {

  final supabase = Supabase.instance.client;

  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  String icono = "police";
  String color = "blue";

  Future<void> guardarServicio() async {

  try {

    /// validar campos
    if (nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el nombre del servicio")),
      );
      return;
    }

    if (telefonoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el teléfono")),
      );
      return;
    }

    /// insertar en supabase
    await supabase.from('servicios_emergencia').insert({
      "nombre": nombreCtrl.text.trim(),
      "telefono": telefonoCtrl.text.trim(),
      "descripcion": descripcionCtrl.text.trim(),
      "icono": icono,
      "color": color,
      "activo": true
    });

    /// limpiar campos
    nombreCtrl.clear();
    telefonoCtrl.clear();
    descripcionCtrl.clear();

    /// refrescar lista
    setState(() {});

    /// mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Servicio registrado correctamente"),
        backgroundColor: Colors.green,
      ),
    );

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error al guardar: $e"),
        backgroundColor: Colors.red,
      ),
    );

    print("ERROR SUPABASE: $e");
  }
}

  Future<List<Map<String,dynamic>>> obtenerServicios() async {

    final data = await supabase
        .from('servicios_emergencia')
        .select()
        .order('created_at');

    return List<Map<String,dynamic>>.from(data);
  }

  Future<void> eliminarServicio(String id) async {

    await supabase
        .from('servicios_emergencia')
        .delete()
        .eq("id", id);

    setState(() {});
  }

  void editarServicio(Map servicio){

    nombreCtrl.text = servicio["nombre"];
    telefonoCtrl.text = servicio["telefono"];
    descripcionCtrl.text = servicio["descripcion"] ?? "";

    icono = servicio["icono"];
    color = servicio["color"];

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          title: const Text("Editar servicio"),

          actions: [

            TextButton(
              child: const Text("Cancelar"),
              onPressed: (){
                Navigator.pop(context);
              },
            ),

            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () async {

                await supabase
                    .from('servicios_emergencia')
                    .update({
                      "nombre": nombreCtrl.text,
                      "telefono": telefonoCtrl.text,
                      "descripcion": descripcionCtrl.text,
                      "icono": icono,
                      "color": color
                    })
                    .eq("id", servicio["id"]);

                Navigator.pop(context);

                setState(() {});
              },
            )

          ],
        );
      },
    );
  }

  Widget listaServicios(){

    return FutureBuilder(
      future: obtenerServicios(),
      builder: (context, snapshot) {

        if(!snapshot.hasData){
          return const Center(child: CircularProgressIndicator());
        }

        final servicios = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: servicios.length,
          itemBuilder: (context,index){

            final servicio = servicios[index];

            return Card(
              child: ListTile(

                title: Text(servicio["nombre"]),

                subtitle: Text(servicio["telefono"]),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    IconButton(
                      icon: const Icon(Icons.edit,color: Colors.orange),
                      onPressed: (){
                        editarServicio(servicio);
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete,color: Colors.red),
                      onPressed: (){
                        eliminarServicio(servicio["id"]);
                      },
                    )

                  ],
                ),

              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Servicios de emergencia"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [

            const Text(
              "Registrar servicio",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height:20),

            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder()
              ),
            ),

            const SizedBox(height:15),

            TextField(
              controller: telefonoCtrl,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder()
              ),
            ),

            const SizedBox(height:15),

            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder()
              ),
            ),

            const SizedBox(height:15),

            DropdownButtonFormField(
              value: icono,
              items: const [

                DropdownMenuItem(
                    value: "police",
                    child: Text("Policía")
                ),

                DropdownMenuItem(
                    value: "hospital",
                    child: Text("Hospital")
                ),

                DropdownMenuItem(
                    value: "fire",
                    child: Text("Bomberos")
                ),

                DropdownMenuItem(
                    value: "civil",
                    child: Text("Protección civil")
                ),

              ],
              onChanged: (value){
                setState(() {
                  icono = value!;
                });
              },
            ),

            const SizedBox(height:15),

            DropdownButtonFormField(
              value: color,
              items: const [

                DropdownMenuItem(
                    value: "blue",
                    child: Text("Azul")
                ),

                DropdownMenuItem(
                    value: "red",
                    child: Text("Rojo")
                ),

                DropdownMenuItem(
                    value: "orange",
                    child: Text("Naranja")
                ),

                DropdownMenuItem(
                    value: "green",
                    child: Text("Verde")
                ),

              ],
              onChanged: (value){
                setState(() {
                  color = value!;
                });
              },
            ),

            const SizedBox(height:20),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Guardar servicio"),
              onPressed: guardarServicio,
            ),

            const SizedBox(height:40),

            const Text(
              "Servicios registrados",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height:20),

            listaServicios()

          ],
        ),
      ),
    );
  }
}