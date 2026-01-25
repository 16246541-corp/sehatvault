import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/education_content.dart';
import 'local_storage_service.dart';
import 'analytics_service.dart';

class EducationService {
  static final EducationService _instance = EducationService._internal();
  factory EducationService() => _instance;
  EducationService._internal();

  final LocalStorageService _localStorageService = LocalStorageService();
  final Map<String, EducationContent> _contentCache = {};
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<EducationContent?> loadContent(String contentId) async {
    if (_contentCache.containsKey(contentId)) {
      return _contentCache[contentId];
    }

    try {
      final jsonString = await rootBundle
          .loadString('assets/data/education_content/$contentId.json');
      final jsonMap = json.decode(jsonString);
      final content = EducationContent.fromJson(jsonMap);
      _contentCache[contentId] = content;
      return content;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isEducationCompleted(String contentId) async {
    final content = await loadContent(contentId);
    if (content == null) {
      return true;
    }

    final settings = _localStorageService.getAppSettings();
    final storedVersion = settings.completedEducationVersions[contentId];
    if (storedVersion != null && storedVersion >= content.version) {
      return true;
    }

    if (settings.completedEducationIds.contains(contentId) &&
        content.version <= 1) {
      await _migrateLegacyCompletion(contentId, content.version);
      return true;
    }

    return false;
  }

  Future<void> markEducationCompleted(String contentId) async {
    final content = await loadContent(contentId);
    if (content == null) {
      return;
    }

    final settings = _localStorageService.getAppSettings();
    final newVersions =
        Map<String, int>.from(settings.completedEducationVersions);
    newVersions[contentId] = content.version;
    settings.completedEducationVersions = newVersions;
    if (settings.completedEducationIds.contains(contentId)) {
      final legacyIds = Set<String>.from(settings.completedEducationIds);
      legacyIds.remove(contentId);
      settings.completedEducationIds = legacyIds;
    }
    await _localStorageService.saveAppSettings(settings);
    await _analyticsService.logEvent(
      'education_completed',
      parameters: {
        'contentId': contentId,
        'version': content.version,
      },
    );
  }

  Future<void> _migrateLegacyCompletion(String contentId, int version) async {
    final settings = _localStorageService.getAppSettings();
    final newVersions =
        Map<String, int>.from(settings.completedEducationVersions);
    newVersions[contentId] = version;
    settings.completedEducationVersions = newVersions;
    if (settings.completedEducationIds.contains(contentId)) {
      final legacyIds = Set<String>.from(settings.completedEducationIds);
      legacyIds.remove(contentId);
      settings.completedEducationIds = legacyIds;
    }
    await _localStorageService.saveAppSettings(settings);
  }

  Future<void> logEducationDisplayed(String contentId) async {
    final content = await loadContent(contentId);
    if (content == null) {
      return;
    }
    await _analyticsService.logEvent(
      'education_displayed',
      parameters: {
        'contentId': contentId,
        'version': content.version,
      },
    );
  }

  Future<EducationContent?> getContentIfUnseen(String contentId) async {
    if (await isEducationCompleted(contentId)) {
      return null;
    }
    return loadContent(contentId);
  }

  Future<EducationContent?> getFirstPendingEducation(
      List<String> contentIds) async {
    for (final id in contentIds) {
      if (!await isEducationCompleted(id)) {
        return loadContent(id);
      }
    }
    return null;
  }
}
