import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'experiencia_magica_detalle_page.dart';
import 'editar_experiencia_magica_page.dart';
import 'package:acaxochi/widgets/texto_expandable.dart';

class ExperienciaMagicaPage extends StatefulWidget {
  const ExperienciaMagicaPage({super.key});

  @override
  State<ExperienciaMagicaPage> createState() =>
      _ExperienciaMagicaPageState();
}

class _ExperienciaMagicaPageState
    extends State<ExperienciaMagicaPage>
    with AutomaticKeepAliveClientMixin {

  final supabase =
      Supabase.instance.client;

  List<dynamic> lugares = [];
  List<dynamic> lugaresFiltrados = [];

String categoriaSeleccionada = 'Todos';

  Map<String, dynamic>
      configuracion = {};

  bool cargando = true;

  bool sinInternet = false;

  bool get esAdmin {

  final user =
      Supabase.instance.client.auth.currentUser;

  return user != null;
}

List<String> get categorias {
  final lista = lugares
      .map((e) => e['categoria']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  lista.sort();

  return ['Todos', ...lista];
}

void filtrarCategoria(String categoria) {
  setState(() {
    categoriaSeleccionada = categoria;

    if (categoria == 'Todos') {
      lugaresFiltrados = lugares;
    } else {
      lugaresFiltrados = lugares.where((e) {
        return e['categoria'] == categoria;
      }).toList();
    }
  });
}

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {

    try {

      setState(() {

        cargando = true;

        sinInternet = false;

      });

      final lugaresResponse =
    await supabase
        .from('experiencia_magica')
        .select()
        .order(
          'orden',
          ascending: true,
          nullsFirst: false,
        )
        .order(
          'id',
          ascending: false,
        );

      final configResponse =
          await supabase
              .from(
                  'experiencia_magica_config')
              .select()
              .eq('id', 1)
              .maybeSingle();

      if (!mounted) return;

      setState(() {

        lugares = lugaresResponse;
        lugaresFiltrados = lugaresResponse;

        configuracion =
            configResponse ?? {};

        cargando = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        cargando = false;

        sinInternet = true;

      });
    }
  }
  Future<void> eliminarLugar(dynamic item) async {

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) {

      return AlertDialog(

        title: const Text(
          "Eliminar establecimiento",
        ),

        content: Text(
          "¿Deseas eliminar '${item['nombre']}'?\n\nEsta acción no se puede deshacer.",
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancelar"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              "Eliminar",
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  try {

    await supabase
        .from('experiencia_magica')
        .delete()
        .eq('id', item['id']);

    cargarDatos();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Establecimiento eliminado",
        ),
      ),
    );

  } catch (e) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "Error: $e",
        ),
      ),
    );
  }
}
Future<int?> mostrarDialogoOrden(
    dynamic item) async {

  final controller =
      TextEditingController(
    text:
        (item['orden'] ?? '')
            .toString(),
  );

  return showDialog<int>(
    context: context,
    builder: (context) {

      return AlertDialog(
        title: const Text(
          "Asignar orden",
        ),
        content: TextField(
          controller: controller,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText:
                "Número de orden",
          ),
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child:
                const Text("Cancelar"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                int.tryParse(
                  controller.text,
                ),
              );
            },
            child:
                const Text("Guardar"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    
    super.build(context);
    return Scaffold(

      backgroundColor:
          Colors.white,

      appBar: AppBar(

        backgroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(

          "Experiencia Mágica",

          style: TextStyle(

            color: Colors.black,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),

        centerTitle: true,
      ),

      body: cargando

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : sinInternet

              ? pantallaSinInternet()

              : lugares.isEmpty

                  ? pantallaVacia()

                  : contenido(),
    );
  }

  Widget pantallaSinInternet() {

    return Center(

      child: tarjetaMensaje(

        icono: Icons.wifi_off,

        titulo:
            "Sin conexión a internet",

        descripcion:
            "Necesitas conexión para cargar los establecimientos.",
      ),
    );
  }

  Widget pantallaVacia() {

    return Center(

      child: tarjetaMensaje(

        icono:
            Icons.storefront_outlined,

        titulo:
            "Aún no hay establecimientos",

        descripcion:
            "Próximamente aparecerán nuevos lugares disponibles.",
      ),
    );
  }

  Widget tarjetaMensaje({

    required IconData icono,

    required String titulo,

    required String descripcion,

  }) {

    return Container(

      margin:
          const EdgeInsets.all(2),

      padding:
          const EdgeInsets.all(2),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          5,
        ),

        boxShadow: const [

          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),

      child: Column(

        mainAxisSize:
            MainAxisSize.min,

        children: [

          Icon(

            icono,

            size: 70,

            color: Colors.black,
          ),

          const SizedBox(
              height: 20),

          Text(

            titulo,

            textAlign:
                TextAlign.center,

            style: const TextStyle(

              fontSize: 14,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
              height: 15),

          Text(

            descripcion,

            textAlign:
                TextAlign.center,

            style: const TextStyle(

              color: Colors.black54,

              height: 1.5,

              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget contenido() {

    return Container(

      color: Colors.white,

      child:
          SingleChildScrollView(

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [

            portada(),

            const SizedBox(
                height: 12),

            const Padding(
  padding: EdgeInsets.symmetric(
    horizontal: 2,
  ),
),

            const SizedBox(
                height: 10),

                SizedBox(
  height: 50,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
    ),
    itemCount: categorias.length,
    itemBuilder: (context, index) {
      final categoria = categorias[index];

      final seleccionada =
          categoriaSeleccionada == categoria;

      return Padding(
        padding: const EdgeInsets.only(
          right: 8,
        ),
        child: ChoiceChip(
  label: Text(
    categoria,
    style: TextStyle(
      color: seleccionada
          ? Colors.white
          : Colors.black87,
      fontWeight: FontWeight.w600,
    ),
  ),
  selected: seleccionada,
  selectedColor: const Color.fromARGB(
    255,
    37,
    185,
    230,
  ),
  backgroundColor: Colors.grey.shade200,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  ),
  onSelected: (_) {
    filtrarCategoria(categoria);
  },
)
      );
    },
  ),
),

const SizedBox(height: 15),

            ListView.builder(

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 5,
              ),

              itemCount: lugaresFiltrados.length,

              itemBuilder:
                  (context, index) {

                final item = lugaresFiltrados[index];
                return cardLugar(
                  item,
                );
              },
            ),

            const SizedBox(
                height: 40),
          ],
        ),
      ),
    );
  }

  Widget portada() {

  return Container(

    width: double.infinity,

    margin: const EdgeInsets.all(2),

    padding: const EdgeInsets.all(2),

    decoration: BoxDecoration(

      color: Colors.white,

      borderRadius:
          BorderRadius.circular(5),

      boxShadow: const [

        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
        ),
      ],
    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          configuracion['titulo'] ??
              'Experiencia Mágica',

          style: const TextStyle(

            fontSize: 24,

            fontWeight:
                FontWeight.bold,

            color: Colors.black,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        TextoExpandable(
  texto: configuracion['descripcion'] ?? '',
  maxLineas: 5,
  fontSize: 14,
),
      ],
    ),
  );
}

  Widget cardLugar(dynamic item) {
  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    height: 165,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.015),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ExperienciaMagicaDetallePage(
              lugar: item,
            ),
          ),
        );
      },
      child: Row(
        children: [

          /// IMAGEN IZQUIERDA
          /// IMAGEN IZQUIERDA
Stack(
  children: [

    ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        bottomLeft: Radius.circular(8),
      ),
      child: Image.network(
        (item['imagenes'] != null &&
                (item['imagenes'] as List).isNotEmpty)
            ? item['imagenes'][0]
            : '',
        width: 130,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 130,
            height: 170,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.image,
              size: 40,
            ),
          );
        },
      ),
    ),

    if (esAdmin)
  Positioned(
    top: 4,
    left: 4,
    child: Row(
      children: [

        /// EDITAR
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.blue,
              size: 18,
            ),
            constraints:
                const BoxConstraints(
              minWidth: 35,
              minHeight: 35,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditarExperienciaMagicaPage(
                    lugar: item,
                  ),
                ),
              ).then((_) {
                cargarDatos();
              });
            },
          ),
        ),

        const SizedBox(width: 1),

        /// ELIMINAR
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
              size: 18,
            ),
            constraints:
                const BoxConstraints(
              minWidth: 35,
              minHeight: 35,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {
              eliminarLugar(item);
            },
          ),
        ),

        const SizedBox(width: 1),

        /// ORDENAR
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.reorder,
              color: Colors.orange,
              size: 18,
            ),
            constraints:
                const BoxConstraints(
              minWidth: 35,
              minHeight: 35,
            ),
            padding: EdgeInsets.zero,
            onPressed: () async {

              final numero =
                  await mostrarDialogoOrden(
                item,
              );

              if (numero != null) {

                await supabase
                    .from(
                      'experiencia_magica',
                    )
                    .update({
                  'orden': numero,
                }).eq(
                  'id',
                  item['id'],
                );

                cargarDatos();
              }
            },
          ),
        ),
      ],
    ),
  ),
  ],
),


          /// INFORMACIÓN DERECHA
          Expanded(
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        /// NOMBRE
        Text(
          item['nombre'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),

        /// DESCRIPCIÓN
        if ((item['descripcion'] ?? '')
            .toString()
            .trim()
            .isNotEmpty) ...[

          const SizedBox(height: 8),

          Text(
            item['descripcion'],
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],

  const Spacer(),

        /// CATEGORÍA
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              37,
              185,
              230,
            ).withOpacity(.10),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            item['categoria'] ?? '',
            style: const TextStyle(
              color: Color.fromARGB(
                255,
                37,
                185,
                230,
              ),
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        /// VER MÁS
        Align(
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              const Text(
                'Ver más',
                style: TextStyle(
                  color: Color.fromARGB(
                    255,
                    37,
                    185,
                    230,
                  ),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color.fromARGB(
                  255,
                  37,
                  185,
                  230,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
        ],
      ),
    ),
  );
}
Widget botonAccion(
  IconData icon,
) {

  return Container(

    width: 40,

    height: 40,

    decoration: BoxDecoration(

      color: Colors.white10,

      borderRadius:
          BorderRadius.circular(
        12,
      ),
    ),

    child: Icon(

      icon,

      color: Colors.white,

      size: 20,
    ),
  );
}

  Widget chipInfo(

    IconData icon,

    String texto,

  ) {

    return Container(

      padding:
          const EdgeInsets.symmetric(

        horizontal: 14,

        vertical: 10,
      ),

      decoration: BoxDecoration(

        color:
            Colors.grey.shade100,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Row(

        mainAxisSize:
            MainAxisSize.min,

        children: [

          Icon(

            icon,

            color: Colors.black,

            size: 18,
          ),

          const SizedBox(
              width: 8),

          Text(

            texto,

            style:
                const TextStyle(
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  @override
bool get wantKeepAlive => true;
}