import 'package:sehatlocker/services/medical_field_extractor.dart';
import 'package:sehatlocker/services/reference_range_service.dart';

/// Example demonstrating the integration of MedicalFieldExtractor and ReferenceRangeService.
///
/// This shows a complete workflow:
/// 1. Extract lab values from OCR text using MedicalFieldExtractor
/// 2. Evaluate extracted values against reference ranges using ReferenceRangeService
/// 3. Generate a comprehensive health report with recommendations
void main() {
  print('=== Integrated Medical Data Extraction & Evaluation ===\n');

  // Simulated OCR extracted text from a lab report
  const ocrText = '''
    COMPREHENSIVE HEALTH PANEL
    Patient: Jane Doe (Female, 35 years)
    Date: January 23, 2026
    
    COMPLETE BLOOD COUNT
    Hemoglobin: 11.8 g/dL
    WBC: 8.5 x10^3/µL
    RBC: 4.3 x10^6/µL
    Platelets: 220 x10^3/µL
    Hematocrit: 36.5 %
    
    METABOLIC PANEL
    Glucose: 115 mg/dL
    HbA1c: 6.2 %
    Creatinine: 0.9 mg/dL
    Sodium: 140 mEq/L
    Potassium: 4.2 mEq/L
    
    LIPID PANEL
    Total Cholesterol: 235 mg/dL
    LDL Cholesterol: 155 mg/dL
    HDL Cholesterol: 55 mg/dL
    Triglycerides: 180 mg/dL
    
    THYROID FUNCTION
    TSH: 4.5 µIU/mL
    
    VITAMINS
    Vitamin D: 22 ng/mL
    Vitamin B12: 350 pg/mL
  ''';

  print('📄 Processing Lab Report...\n');

  // Step 1: Extract lab values using MedicalFieldExtractor
  final extractedData = MedicalFieldExtractor.extractLabValues(ocrText);
  final labValues = extractedData['values'] as List<Map<String, String>>;

  print('✓ Extracted ${labValues.length} lab values\n');

  // Step 2: Evaluate all extracted values against reference ranges
  final evaluation = ReferenceRangeService.evaluateMultipleLabValues(
    labValues: labValues,
    gender: 'female', // Specify patient gender for accurate ranges
  );

  // Step 3: Generate comprehensive report
  generateHealthReport(evaluation);
}

void generateHealthReport(Map<String, dynamic> evaluation) {
  final summary = evaluation['summary'] as Map<String, dynamic>;
  final results = evaluation['results'] as List<Map<String, dynamic>>;

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('                  HEALTH REPORT SUMMARY');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  print('Total Tests Analyzed: ${summary['total']}');
  print('✓ Normal Values: ${summary['normal']}');
  print('↑ High Values: ${summary['high']}');
  print('↓ Low Values: ${summary['low']}');
  print('? Unknown/Unmatched: ${summary['unknown']}');
  print('');

  // Separate results by status
  final criticalHigh = <Map<String, dynamic>>[];
  final criticalLow = <Map<String, dynamic>>[];
  final borderlineHigh = <Map<String, dynamic>>[];
  final borderlineLow = <Map<String, dynamic>>[];
  final normal = <Map<String, dynamic>>[];

  for (var result in results) {
    if (result['status'] == 'normal') {
      normal.add(result);
    } else if (result['status'] == 'high') {
      final value = result['value'] as double;
      final max = result['normalRange']['max'] as double;
      // Consider critical if >20% above normal
      if (value > max * 1.2) {
        criticalHigh.add(result);
      } else {
        borderlineHigh.add(result);
      }
    } else if (result['status'] == 'low') {
      final value = result['value'] as double;
      final min = result['normalRange']['min'] as double;
      // Consider critical if >20% below normal
      if (value < min * 0.8) {
        criticalLow.add(result);
      } else {
        borderlineLow.add(result);
      }
    }
  }

  // Display critical values first
  if (criticalHigh.isNotEmpty || criticalLow.isNotEmpty) {
    print('🚨 CRITICAL VALUES (Require Immediate Attention)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (var result in [...criticalHigh, ...criticalLow]) {
      final icon = result['status'] == 'high' ? '↑↑' : '↓↓';
      print('  $icon ${result['message']}');
    }
    print('');
  }

  // Display borderline values
  if (borderlineHigh.isNotEmpty || borderlineLow.isNotEmpty) {
    print('⚠️  BORDERLINE VALUES (Monitor Closely)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (var result in [...borderlineHigh, ...borderlineLow]) {
      final icon = result['status'] == 'high' ? '↑' : '↓';
      print('  $icon ${result['message']}');
    }
    print('');
  }

  // Display normal values (collapsed)
  if (normal.isNotEmpty) {
    print('✓ NORMAL VALUES (${normal.length} tests)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (var result in normal) {
      print('  ✓ ${result['testName']}: ${result['value']} ${result['unit']}');
    }
    print('');
  }

  // Generate health insights and recommendations
  print('💡 HEALTH INSIGHTS & RECOMMENDATIONS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final insights = <String>[];
  final recommendations = <String>[];

  // Analyze patterns and provide insights
  for (var result in [
    ...criticalHigh,
    ...criticalLow,
    ...borderlineHigh,
    ...borderlineLow
  ]) {
    final testName = result['testName'].toString().toLowerCase();
    final status = result['status'] as String;

    if (testName.contains('hemoglobin') && status == 'low') {
      insights.add('Low hemoglobin may indicate anemia');
      recommendations.add(
          'Consider iron-rich foods (spinach, red meat, lentils) and consult your doctor about iron supplementation');
    }

    if (testName.contains('glucose') && status == 'high') {
      insights.add(
          'Elevated glucose suggests impaired glucose tolerance or pre-diabetes');
      recommendations.add(
          'Reduce sugar and refined carbohydrate intake, increase physical activity, and monitor blood sugar regularly');
    }

    if (testName.contains('hba1c') && status == 'high') {
      insights.add(
          'Elevated HbA1c indicates poor blood sugar control over the past 2-3 months');
      recommendations.add(
          'Work with your healthcare provider to develop a diabetes management plan');
    }

    if (testName.contains('cholesterol') && status == 'high') {
      insights.add('High cholesterol increases cardiovascular disease risk');
      recommendations.add(
          'Adopt a heart-healthy diet (reduce saturated fats, increase omega-3s), exercise regularly, and discuss statin therapy with your doctor');
    }

    if (testName.contains('ldl') && status == 'high') {
      insights.add(
          'Elevated LDL ("bad cholesterol") contributes to arterial plaque buildup');
      recommendations.add(
          'Focus on soluble fiber (oats, beans), plant sterols, and regular aerobic exercise');
    }

    if (testName.contains('triglycerides') && status == 'high') {
      insights.add('High triglycerides may indicate metabolic syndrome');
      recommendations.add(
          'Limit alcohol, reduce simple sugars, and increase omega-3 fatty acids (fish, flaxseed)');
    }

    if (testName.contains('tsh') && status == 'high') {
      insights
          .add('Elevated TSH suggests hypothyroidism (underactive thyroid)');
      recommendations.add(
          'Consult an endocrinologist for thyroid function evaluation and potential levothyroxine therapy');
    }

    if (testName.contains('vitamin d') && status == 'low') {
      insights.add(
          'Vitamin D deficiency can affect bone health and immune function');
      recommendations.add(
          'Increase sun exposure (15-20 min daily), consume vitamin D-rich foods (fatty fish, fortified milk), and consider supplementation (1000-2000 IU daily)');
    }
  }

  // Remove duplicates and display
  final uniqueInsights = insights.toSet().toList();
  final uniqueRecommendations = recommendations.toSet().toList();

  if (uniqueInsights.isNotEmpty) {
    print('');
    print('Key Findings:');
    for (var i = 0; i < uniqueInsights.length; i++) {
      print('  ${i + 1}. ${uniqueInsights[i]}');
    }
  }

  if (uniqueRecommendations.isNotEmpty) {
    print('');
    print('Recommended Actions:');
    for (var i = 0; i < uniqueRecommendations.length; i++) {
      print('  ${i + 1}. ${uniqueRecommendations[i]}');
    }
  }

  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('⚕️  IMPORTANT: This analysis is for informational purposes only.');
  print('   Always consult with a qualified healthcare professional for');
  print('   medical advice, diagnosis, and treatment decisions.');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
