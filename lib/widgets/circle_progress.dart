import 'package:flutter/material.dart';
import 'dart:math';

class CircleProgress extends StatelessWidget {
  final int stepCircle;
  final double size;

  const CircleProgress({
    super.key,
    required this.stepCircle,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CirclePainter(
        stepCircle: stepCircle,
        size: size,
        primaryColor:
            Theme.of(context).colorScheme.primary, // Pasar el color primario
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final int stepCircle;
  final double size;
  final Color primaryColor; // Añadir un campo para el color primario

  CirclePainter({
    required this.stepCircle,
    required this.size,
    required this.primaryColor, // Incluir el color primario en el constructor
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint outerCircle = Paint()
      ..strokeWidth = 15
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke;

    Paint progressCircle = Paint()
      ..strokeWidth = 15
      ..color = primaryColor // Usar el color primario pasado
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double center = size.width / 2;
    double radius = this.size / 2 - 5;

    canvas.drawCircle(Offset(center, center), radius, outerCircle);

    double arcAngle = 2 * pi * (stepCircle / 6);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      -pi / 2,
      arcAngle,
      false,
      progressCircle,
    );

    // Agregar texto de fracción
    TextSpan span = TextSpan(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      text: '$stepCircle/6', // Mostrar la fracción correspondiente
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    tp.layout();
    tp.paint(
      canvas,
      Offset(center - tp.width / 2, center - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
