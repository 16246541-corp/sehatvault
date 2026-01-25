class EducationContent {
  final String id;
  final String title;
  final List<EducationPage> pages;
  final int version;

  EducationContent({
    required this.id,
    required this.title,
    required this.pages,
    required this.version,
  });

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      id: json['id'] as String,
      title: json['title'] as String,
      pages: (json['pages'] as List)
          .map((e) => EducationPage.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['version'] as int? ?? 1,
    );
  }
}

class EducationPage {
  final String title;
  final String description;
  final String? imageAsset;
  final String? iconName;

  EducationPage({
    required this.title,
    required this.description,
    this.imageAsset,
    this.iconName,
  });

  factory EducationPage.fromJson(Map<String, dynamic> json) {
    return EducationPage(
      title: json['title'] as String,
      description: json['description'] as String,
      imageAsset: json['imageAsset'] as String?,
      iconName: json['iconName'] as String?,
    );
  }
}
