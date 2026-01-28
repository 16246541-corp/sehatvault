import 'package:flutter/material.dart';
import '../../../models/document_extraction.dart';
import '../../../services/reference_range_service.dart';
import '../../../widgets/design/glass_card.dart';

class VerifiedExtractionCard extends StatefulWidget {
  final DocumentExtraction extraction;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final bool isDesktop;
  final String? patientGender;

  const VerifiedExtractionCard({
    super.key,
    required this.extraction,
    required this.onDataChanged,
    this.isDesktop = false,
    this.patientGender,
  });

  @override
  State<VerifiedExtractionCard> createState() => _VerifiedExtractionCardState();
}

class _VerifiedExtractionCardState extends State<VerifiedExtractionCard> {
  static const String _complianceTooltip =
      'Verify against original document – system cannot interpret medical values';

  final List<String> _availableTestNames =
      ReferenceRangeService.getAllTestNames();
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.extraction.structuredData);
    _data['lab_values'] = _ensureListOfMaps(_data['lab_values']);
    _data['medications'] = _ensureListOfMaps(_data['medications']);
    _data['vitals'] = _ensureListOfMaps(_data['vitals']);
    _data['dates'] = _ensureList(_data['dates']);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged(_data);
    });
  }

  List _ensureList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  List<Map<String, dynamic>> _ensureListOfMaps(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  void _notify() {
    widget.onDataChanged(_data);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildLabValuesSection(context),
        const SizedBox(height: 16),
        _buildMedicationsSection(context),
        const SizedBox(height: 16),
        _buildVitalsSection(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final confidence = widget.extraction.confidenceScore;
    final isLowConfidence = confidence < 0.7;

    return Row(
      children: [
        Icon(
          isLowConfidence
              ? Icons.warning_amber_rounded
              : Icons.verified_user_outlined,
          color: isLowConfidence ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(
          'Extraction Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: isLowConfidence ? Colors.orange : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLabValuesSection(BuildContext context) {
    final values = _ensureListOfMaps(_data['lab_values']);
    _data['lab_values'] = values;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: widget.extraction.confidenceScore < 0.7
          ? Colors.orange.withOpacity(0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lab Values',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  values.add({'field': '', 'value': '', 'unit': ''});
                  _notify();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (values.isEmpty)
            const Text(
              'No lab values detected.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ...values.asMap().entries.map((entry) {
            return _buildLabValueRow(
              context: context,
              index: entry.key,
              item: entry.value,
              parentList: values,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLabValueRow({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> item,
    required List<Map<String, dynamic>> parentList,
  }) {
    final fieldName = (item['field'] ?? '').toString();
    final valueText = (item['value'] ?? '').toString();
    final unitText = (item['unit'] ?? '').toString();

    final parsedValue = double.tryParse(valueText);
    Map<String, dynamic>? evaluation;
    if (fieldName.trim().isNotEmpty && parsedValue != null) {
      evaluation = ReferenceRangeService.evaluateLabValue(
        testName: fieldName,
        value: parsedValue,
        unit: unitText.isEmpty ? null : unitText,
        gender: widget.patientGender,
      );
    }
    final status = evaluation?['status']?.toString();
    final isAbnormal = status == 'high' || status == 'low';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 20,
            ),
            onPressed: () {
              parentList.removeAt(index);
              _notify();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: fieldName),
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.trim();
                if (q.isEmpty) return const Iterable<String>.empty();
                return _availableTestNames.where(
                  (option) => option.toLowerCase().contains(q.toLowerCase()),
                );
              },
              onSelected: (selection) {
                item['field'] = selection;
                _notify();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                controller.addListener(() {
                  item['field'] = controller.text;
                });
                return Tooltip(
                  message: _complianceTooltip,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: () {
                      onEditingComplete();
                      _notify();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Test Name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: _complianceTooltip,
              child: TextField(
                controller: TextEditingController(text: valueText)
                  ..selection =
                      TextSelection.collapsed(offset: valueText.length),
                onChanged: (val) {
                  item['value'] = val;
                  _notify();
                },
                decoration: InputDecoration(
                  labelText: 'Value',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: isAbnormal
                      ? Tooltip(
                          message: evaluation?['message']?.toString() ?? '',
                          child: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 16,
                          ),
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: _complianceTooltip,
              child: TextField(
                controller: TextEditingController(text: unitText)
                  ..selection =
                      TextSelection.collapsed(offset: unitText.length),
                onChanged: (val) {
                  item['unit'] = val;
                  _notify();
                },
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsSection(BuildContext context) {
    final medications = _ensureListOfMaps(_data['medications']);
    _data['medications'] = medications;

    final dosageRegex = RegExp(r'^\\d+\\.?\\d*\\s*(mg|mcg|g|IU)$');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medications',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  medications.add({'name': '', 'dosage': '', 'frequency': ''});
                  _notify();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (medications.isEmpty)
            const Text(
              'No medications detected.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ...medications.asMap().entries.map((entry) {
            final item = entry.value;
            final dosage = (item['dosage'] ?? '').toString().trim();
            final hasDosage = dosage.isNotEmpty;
            final isDosageValid = !hasDosage || dosageRegex.hasMatch(dosage);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      medications.removeAt(entry.key);
                      _notify();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(
                            text: (item['name'] ?? '').toString())
                          ..selection = TextSelection.collapsed(
                            offset: (item['name'] ?? '').toString().length,
                          ),
                        onChanged: (val) {
                          item['name'] = val;
                          _notify();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Medication',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(text: dosage)
                          ..selection =
                              TextSelection.collapsed(offset: dosage.length),
                        onChanged: (val) {
                          item['dosage'] = val;
                          _notify();
                        },
                        decoration: InputDecoration(
                          labelText: 'Dosage',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          errorText: isDosageValid ? null : 'Invalid dosage',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(
                            text: (item['frequency'] ?? '').toString())
                          ..selection = TextSelection.collapsed(
                            offset: (item['frequency'] ?? '').toString().length,
                          ),
                        onChanged: (val) {
                          item['frequency'] = val;
                          _notify();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(BuildContext context) {
    final vitals = _ensureListOfMaps(_data['vitals']);
    _data['vitals'] = vitals;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vitals', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  vitals.add({'name': '', 'value': '', 'unit': ''});
                  _notify();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vitals.isEmpty)
            const Text(
              'No vitals detected.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ...vitals.asMap().entries.map((entry) {
            final item = entry.value;
            final nameText = (item['name'] ?? '').toString();
            final valueText = (item['value'] ?? '').toString();
            final unitText = (item['unit'] ?? '').toString();

            final isHeartRate = nameText.toLowerCase().contains('hr') ||
                nameText.toLowerCase().contains('heart');
            final parsed = int.tryParse(valueText);
            final showHrWarning = isHeartRate && parsed != null && parsed > 200;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      vitals.removeAt(entry.key);
                      _notify();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(text: nameText)
                          ..selection =
                              TextSelection.collapsed(offset: nameText.length),
                        onChanged: (val) {
                          item['name'] = val;
                          _notify();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Vital',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(text: valueText)
                          ..selection =
                              TextSelection.collapsed(offset: valueText.length),
                        onChanged: (val) {
                          item['value'] = val;
                          _notify();
                        },
                        decoration: InputDecoration(
                          labelText: 'Value',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: showHrWarning
                              ? const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: _complianceTooltip,
                      child: TextField(
                        controller: TextEditingController(text: unitText)
                          ..selection =
                              TextSelection.collapsed(offset: unitText.length),
                        onChanged: (val) {
                          item['unit'] = val;
                          _notify();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
