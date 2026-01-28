import 'package:flutter/material.dart';
import '../models/health_record.dart';

class CategoryUtils {
  static const Map<HealthCategory, IconData> categoryIcons = {
    HealthCategory.medicalRecords: Icons.description,
    HealthCategory.labResults: Icons.science,
    HealthCategory.prescriptions: Icons.medication,
    HealthCategory.vaccinations: Icons.vaccines,
    HealthCategory.insurance: Icons.card_membership,
    HealthCategory.geneticTestResults: Icons.biotech, // 🧬
    HealthCategory.imagingReports: Icons.image,
    HealthCategory.remoteMonitoring: Icons.monitor_heart, // 📡
    HealthCategory.pathologyReports: Icons.coronavirus,
    HealthCategory.clinicalNotes: Icons.note_alt,
    HealthCategory.allergyDocumentation: Icons.warning_amber,
    HealthCategory.surgicalReports: Icons.local_hospital,
    HealthCategory.doctorVisitReport: Icons.medical_services,
    HealthCategory.other: Icons.folder_open,
  };

  static IconData getIcon(HealthCategory category) {
    return categoryIcons[category] ?? Icons.folder;
  }

  static bool isSensitive(HealthCategory category) {
    const sensitiveCategories = {
      HealthCategory.geneticTestResults,
      HealthCategory.pathologyReports,
      HealthCategory.surgicalReports,
      HealthCategory.clinicalNotes,
      HealthCategory.medicalRecords,
      HealthCategory.prescriptions, // Depending on definition, but usually yes
    };
    return sensitiveCategories.contains(category);
  }
}

extension HealthCategoryUI on HealthCategory {
  IconData get icon => CategoryUtils.getIcon(this);
  bool get isSensitive => CategoryUtils.isSensitive(this);
}
