import 'package:flutter/material.dart';
import '../../models/generation_parameters.dart';
import '../../services/generation_parameters_service.dart';
import '../../utils/design_constants.dart';
import '../design/glass_card.dart';

class GenerationControls extends StatelessWidget {
  const GenerationControls({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GenerationParametersService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, child) {
        final params = service.currentParameters;
        final warnings = service.validateParameters(params);

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(DesignConstants.standardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Generation Parameters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    _buildPresetDropdown(context, service),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSlider(
                  context,
                  label: 'Temperature',
                  value: params.temperature,
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  warning: warnings['temperature'],
                  onChanged: (v) =>
                      service.updateParameters(params.copyWith(temperature: v)),
                  tooltip:
                      'Higher values make the output more random, lower values more deterministic.',
                ),
                _buildSlider(
                  context,
                  label: 'Top-P',
                  value: params.topP,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  warning: warnings['topP'],
                  onChanged: (v) =>
                      service.updateParameters(params.copyWith(topP: v)),
                  tooltip:
                      'Nucleus sampling: considers the tokens with top_p probability mass.',
                ),
                _buildSlider(
                  context,
                  label: 'Top-K',
                  value: params.topK.toDouble(),
                  min: 1.0,
                  max: 100.0,
                  divisions: 100,
                  warning: warnings['topK'],
                  onChanged: (v) => service
                      .updateParameters(params.copyWith(topK: v.toInt())),
                  tooltip: 'Sample from the top K most likely tokens.',
                ),
                _buildSlider(
                  context,
                  label: 'Max Tokens',
                  value: params.maxTokens.toDouble(),
                  min: 64.0,
                  max: 8192.0,
                  divisions: 127,
                  warning: warnings['maxTokens'],
                  onChanged: (v) => service
                      .updateParameters(params.copyWith(maxTokens: v.toInt())),
                  tooltip: 'The maximum number of tokens to generate.',
                ),
                _buildSlider(
                  context,
                  label: 'Presence Penalty',
                  value: params.presencePenalty,
                  min: -2.0,
                  max: 2.0,
                  divisions: 40,
                  onChanged: (v) => service
                      .updateParameters(params.copyWith(presencePenalty: v)),
                  tooltip:
                      'Positive values penalize new tokens based on whether they appear in the text so far.',
                ),
                _buildSlider(
                  context,
                  label: 'Frequency Penalty',
                  value: params.frequencyPenalty,
                  min: -2.0,
                  max: 2.0,
                  divisions: 40,
                  onChanged: (v) => service
                      .updateParameters(params.copyWith(frequencyPenalty: v)),
                  tooltip:
                      'Positive values penalize new tokens based on their existing frequency in the text so far.',
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: service.resetToDefaults,
                    child: const Text('Reset to Defaults',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? warning,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (tooltip != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Tooltip(
                      message: tooltip,
                      child: const Icon(Icons.info_outline,
                          size: 14, color: Colors.white54),
                    ),
                  ),
              ],
            ),
            Text(
              value is int ? value.toString() : value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:
                warning != null ? Colors.orange : Colors.blueAccent,
            thumbColor: warning != null ? Colors.orange : Colors.blueAccent,
            overlayColor: (warning != null ? Colors.orange : Colors.blueAccent)
                .withAlpha(32),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            semanticFormatterCallback: (double value) =>
                '$label: ${value.toStringAsFixed(2)}',
          ),
        ),
        if (warning != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              warning,
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildPresetDropdown(
      BuildContext context, GenerationParametersService service) {
    return DropdownButton<String>(
      dropdownColor: Colors.grey[900],
      underline: Container(),
      icon: const Icon(Icons.tune, color: Colors.white70),
      hint: const Text('Presets',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      items: ['Balanced', 'Creative', 'Precise', 'Fast'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          service.applyPreset(value);
        }
      },
    );
  }
}
