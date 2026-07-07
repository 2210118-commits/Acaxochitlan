import 'package:flutter/material.dart';

class HomeNews extends StatelessWidget {
  final Widget noticias;
  final VoidCallback onVerTodos;

  const HomeNews({
    super.key,
    required this.noticias,
    required this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Lugares que no te puedes perder",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2B2B2B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xffD8A72C),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),

                  ],
                ),
              ),

              TextButton(
                onPressed: onVerTodos,
                child: const Text(
                  "Ver todos",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 160,
            child: noticias,
          ),

        ],
      ),
    );
  }
}