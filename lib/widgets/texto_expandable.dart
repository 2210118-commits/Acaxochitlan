import 'package:flutter/material.dart';

class TextoExpandable extends StatefulWidget {
  final String texto;
  final int maxLineas;
  final double fontSize;
  final Color colorLink;

  const TextoExpandable({
    super.key,
    required this.texto,
    this.maxLineas = 4,
    this.fontSize = 14,
    this.colorLink = const Color.fromARGB(255, 99, 176, 243),
  });

  @override
  State<TextoExpandable> createState() => _TextoExpandableState();
}

class _TextoExpandableState extends State<TextoExpandable> {
  bool _expandido = false;
  bool _mostrarBoton = false;

  @override
  Widget build(BuildContext context) {
    final texto = widget.texto;

    final span = TextSpan(
      text: texto,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.4,
      ),
    );

    final tp = TextPainter(
      text: span,
      maxLines: widget.maxLineas,
      textDirection: TextDirection.ltr,
    );

    tp.layout(maxWidth: MediaQuery.of(context).size.width - 32);

    _mostrarBoton = tp.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          maxLines: _expandido ? null : widget.maxLineas,
          overflow:
              _expandido ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: widget.fontSize,
            height: 1.4,
          ),
        ),

        if (_mostrarBoton)
          GestureDetector(
            onTap: () {
              setState(() {
                _expandido = !_expandido;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expandido ? 'Ver menos' : 'Ver más',
                style: TextStyle(
                  color: widget.colorLink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
