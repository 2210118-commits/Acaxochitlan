import 'package:flutter/material.dart';

class HomeHero extends StatelessWidget {
  final String? fondoHomeUrl;
  final TextEditingController searchController;
  final Function(String) onSearch;

  const HomeHero({
    super.key,
    required this.fondoHomeUrl,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [

        /// HERO
        SizedBox(
          height: 230,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [

              /// IMAGEN
              Image(
                image: fondoHomeUrl != null &&
                        fondoHomeUrl!.isNotEmpty
                    ? NetworkImage(fondoHomeUrl!)
                    : const AssetImage(
                        "assets/images/Acx(2).jpeg",
                      ) as ImageProvider,
                fit: BoxFit.cover,
              ),

              /// DEGRADADO
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [

                      const Color(0xff650B28),

                      Colors.transparent,

                      Colors.black.withOpacity(.45),

                    ],
                  ),
                ),
              ),

              /// TEXTO
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                child: Align(
                  alignment: const Alignment(-1.0, -0.30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Descubre la magia de",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Acaxochitlán",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          height: .9,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        width: 75,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xffD8A72C),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: width * .65,
                        child: const Text(
                          "Pueblo mágico de Hidalgo donde la naturaleza, la cultura y la tradición se encuentran.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// BUSCADOR
        Positioned(
          left: 13,
          right: 13,
          bottom: -20,
          child: Material(
            elevation: 15,
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: TextField(
  controller: searchController,

  onChanged: (value) {
    onSearch(value);
  },

  decoration: InputDecoration(
    border: InputBorder.none,

    prefixIcon: const Icon(
      Icons.search,
      color: Color.fromARGB(255, 122, 122, 122),
      size: 22,
    ),

    suffixIcon: searchController.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              searchController.clear();
              onSearch("");
            },
          )
        : null,

    hintText: "¿Qué quieres explorar en Acaxochitlán?",

    hintStyle: const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 102, 101, 101),
    ),

    isDense: true,

    contentPadding: const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 8,
    ),
  ),
),
            ),
          ),
        ),
      ],
    );
  }
}