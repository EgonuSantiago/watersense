import 'package:flutter/material.dart';

class WaterLevelWidget extends StatelessWidget {
  final double percentage;
  final double liters;

  const WaterLevelWidget({
    required this.percentage,
    required this.liters,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = percentage.clamp(0.0, 100.0);
    final heightContainer = 280.0;
    final fillHeight = (pct / 100.0) * heightContainer;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 140,
              height: heightContainer,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Container(
              width: 140,
              height: fillHeight,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${liters.toStringAsFixed(1)} L',
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
