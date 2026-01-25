import 'model_metadata.dart';
import '../services/model_quantization_service.dart';

class ModelOption {
  final String id;
  final String name;
  final double ramRequired; // in GB (base for 4-bit)
  final double storageRequired; // in GB (base for 4-bit)
  final String description;
  final bool isDesktopOnly;
  final ModelMetadata metadata;
  final DateTime? knowledgeCutoffDate;
  final String license;
  final List<QuantizationFormat> supportedQuantizations;

  const ModelOption({
    required this.id,
    required this.name,
    required this.ramRequired,
    required this.storageRequired,
    required this.description,
    required this.metadata,
    this.isDesktopOnly = false,
    this.knowledgeCutoffDate,
    this.license = 'Apache 2.0',
    this.supportedQuantizations = const [
      QuantizationFormat.q3_k_m,
      QuantizationFormat.q4_k_m,
      QuantizationFormat.q5_k_m,
      QuantizationFormat.q8_0,
    ],
  });

  static final List<ModelOption> availableModels = [
    ModelOption(
      id: 'tiny_llama_1b',
      name: 'TinyLlama-1.1B',
      ramRequired: 1.5,
      storageRequired: 0.8,
      description:
          'Ultra-lightweight model for basic summaries and text processing. Ideal for low-end mobile devices.',
      metadata: ModelMetadata(
        version: '1.1.0',
        checksum:
            'sha256:698d4dcaf18fd53be2aa83fc8d4f28ade85224dc767b9566aee84bf341d6f9ae',
        releaseDate: DateTime(2024, 1, 15),
        signature: 'sig_tiny_llama_v110',
        publicKey: 'pub_key_sehat_locker_2024',
      ),
      isDesktopOnly: false,
      knowledgeCutoffDate: DateTime(2023, 9, 1),
      license: 'Apache 2.0',
      supportedQuantizations: [
        QuantizationFormat.q4_k_m,
        QuantizationFormat.q5_k_m,
        QuantizationFormat.q8_0,
      ],
    ),
    ModelOption(
      id: 'med_gemma_4b',
      name: 'MedGemma-4B',
      ramRequired: 4.0,
      storageRequired: 2.6,
      description:
          'Medical-tuned Gemma model balancing performance and speed. Suitable for mid-range mobile devices.',
      metadata: ModelMetadata(
        version: '2.0.1',
        checksum:
            'sha256:471dee562f00d4a6107e6d6849523b82fe6d3a02f802af31c166b349e4822498',
        releaseDate: DateTime(2024, 3, 10),
        signature: 'sig_med_gemma_v201',
        publicKey: 'pub_key_sehat_locker_2024',
      ),
      isDesktopOnly: false,
      knowledgeCutoffDate: DateTime(2023, 11, 15),
      license: 'Gemma Terms of Use',
      supportedQuantizations: [
        QuantizationFormat.q3_k_m,
        QuantizationFormat.q4_k_m,
        QuantizationFormat.q5_k_m,
        QuantizationFormat.q6_k,
      ],
    ),
    ModelOption(
      id: 'advanced_8b',
      name: 'Advanced-8B',
      ramRequired: 8.0,
      storageRequired: 5.2,
      description:
          'Powerful Llama-3 based model for complex medical reasoning and detailed analysis. Recommended for high-end devices.',
      metadata: ModelMetadata(
        version: '3.0.0',
        checksum:
            'sha256:25a4a070e37b0ffb6dd17283a58675a451797e68e4b6bfcedf67fcceb11caa86',
        releaseDate: DateTime(2024, 5, 20),
        signature: 'sig_advanced_8b_v300',
        publicKey: 'pub_key_sehat_locker_2024',
      ),
      isDesktopOnly: false,
      knowledgeCutoffDate: DateTime(2024, 3, 1),
      license: 'Llama 3 Community License',
      supportedQuantizations: [
        QuantizationFormat.q4_k_m,
        QuantizationFormat.q5_k_m,
        QuantizationFormat.q6_k,
        QuantizationFormat.q8_0,
      ],
    ),
    ModelOption(
      id: 'research_13b',
      name: 'Research-13B',
      ramRequired: 16.0,
      storageRequired: 9.5,
      description:
          'Expert-level model for deep medical research and heavy multi-document analysis. Available on desktop only.',
      metadata: ModelMetadata(
        version: '1.5.2',
        checksum:
            'sha256:438c22607c159766465e60d2640d5b23cd5b3e31be5abc3367e18037002bc9c3',
        releaseDate: DateTime(2024, 6, 05),
        signature: 'sig_research_13b_v152',
        publicKey: 'pub_key_sehat_locker_2024',
      ),
      isDesktopOnly: true,
      knowledgeCutoffDate: DateTime(2024, 4, 15),
      license: 'Apache 2.0',
      supportedQuantizations: [
        QuantizationFormat.q4_k_m,
        QuantizationFormat.q5_k_m,
        QuantizationFormat.q6_k,
        QuantizationFormat.q8_0,
        QuantizationFormat.f16,
      ],
    ),
  ];
}
