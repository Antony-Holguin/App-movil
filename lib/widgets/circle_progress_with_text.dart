import 'package:flutter/material.dart';
import 'circle_progress.dart';

class CircleProgressWithText extends StatelessWidget {
  final int stepCircle;
  final double size;
  final List<String> titles;
  final List<String> subtitles;

  const CircleProgressWithText({
    super.key,
    required this.stepCircle,
    required this.size,
    required this.titles,
    required this.subtitles,
  });

  @override
  Widget build(BuildContext context) {
    int index = stepCircle - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleProgress(stepCircle: stepCircle, size: size),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[index],
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitles[index],
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
