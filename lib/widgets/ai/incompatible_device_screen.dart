import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class IncompatibleDeviceScreen extends StatelessWidget {
  final double detectedRam;
  final double requiredRam;

  const IncompatibleDeviceScreen({
    super.key,
    required this.detectedRam,
    this.requiredRam = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withOpacity(0.8),
                Colors.black,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.memory_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                'Incompatible Device',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'SehatLocker provides privacy-first, local AI processing that requires significant device resources.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRamInfoRow('Required RAM', '${requiredRam.toStringAsFixed(1)} GB'),
                    const Divider(color: Colors.white24, height: 24),
                    _buildRamInfoRow(
                      'Detected RAM', 
                      '${detectedRam.toStringAsFixed(1)} GB',
                      isError: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Unfortunately, this device does not meet the minimum requirements to ensure a stable experience.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (detectedRam > 0) // Only show if we actually detected it
                TextButton(
                  onPressed: () {
                    // In a real app, this could link to a support page
                  },
                  child: const Text(
                    'Learn More about Offline AI',
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRamInfoRow(String label, String value, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            color: isError ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
