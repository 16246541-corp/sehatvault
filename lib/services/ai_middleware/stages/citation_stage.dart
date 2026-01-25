import '../pipeline_stage.dart';
import '../pipeline_context.dart';
import '../../citation_service.dart';

/// Pipeline stage for injecting citations into the AI output.
class CitationStage extends PipelineStage {
  final CitationService _citationService;

  CitationStage(this._citationService);

  @override
  String get id => 'citation_injection';

  @override
  int get priority => 50; // Run after initial cleanup but before final formatting

  @override
  Future<void> process(PipelineContext context) async {
    final citations = _citationService.generateCitationsFromText(context.content);
    
    if (citations.isNotEmpty) {
      context.citations.addAll(citations);
      
      // Save citations to storage
      for (final citation in citations) {
        await _citationService.addCitation(citation);
      }
      
      // Format and append citations to content
      final formatted = _citationService.formatCitations(citations, style: 'reference');
      if (formatted.isNotEmpty) {
        context.content += '\n\nReferences:\n$formatted';
      }
    }
  }
}
