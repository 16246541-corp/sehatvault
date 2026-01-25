import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/document_extraction.dart';
import '../models/health_record.dart';
import 'citation_service.dart';
import 'local_storage_service.dart';

class PdfExportService {
  final CitationService _citationService =
      CitationService(LocalStorageService());

  Future<String> generatePdf({
    required DocumentExtraction extraction,
    HealthRecord? record,
    String? outputPath,
  }) async {
    final pdf = pw.Document();

    // Load image
    final imageFile = File(extraction.originalImagePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file not found: ${extraction.originalImagePath}');
    }
    final imageBytes = await imageFile.readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    // Create a page with image and data
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            if (record != null) ...[
              pw.Header(
                level: 0,
                child: pw.Text(
                  record.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Category: ${record.category}'),
                  pw.Text('Date: ${record.createdAt.toString().split(' ')[0]}'),
                ],
              ),
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Notes: ${record.notes}'),
              ],
              pw.Divider(),
              pw.SizedBox(height: 10),
            ] else ...[
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Document Extraction',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text('Date: ${extraction.createdAt.toString().split(' ')[0]}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],

            // Image Section
            pw.Container(
              constraints: const pw.BoxConstraints(maxHeight: 400),
              alignment: pw.Alignment.center,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 20),

            // Structured Data Section
            if (extraction.structuredData.isNotEmpty) ...[
              pw.Text(
                'Extracted Data',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: extraction.structuredData.entries.map((entry) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _formatKey(entry.key),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(entry.value.toString()),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Raw Text Section
            pw.Text(
              'Original Text',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                color: PdfColors.grey200,
              ),
              child: pw.Text(
                extraction.extractedText,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            if (extraction.citations != null &&
                extraction.citations!.isNotEmpty) ...[
              ...() {
                final references = _citationService.formatCitations(
                  extraction.citations!,
                  style: 'reference',
                );
                if (references.isEmpty) return <pw.Widget>[];
                return [
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'References',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    references,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ];
              }(),
            ],
          ];
        },
      ),
    );

    // Save
    File file;
    if (outputPath != null) {
      file = File(outputPath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      final fileName =
          'sehatlocker_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      file = File('${output.path}/$fileName');
    }
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((str) => str.isNotEmpty
            ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
