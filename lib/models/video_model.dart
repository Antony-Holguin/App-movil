class VideoModel {
  final String id;
  final String title;
  final String description;
  final String filePath;
  final String s3Url;
  final List<String> tags;
  final DateTime uploadDate;
  final int duration;
  final String thumbnailPath;
  final bool isPublished;
  final List<String> publishedPlatforms;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.filePath,
    required this.s3Url,
    required this.tags,
    required this.uploadDate,
    required this.duration,
    required this.thumbnailPath,
    this.isPublished = false,
    this.publishedPlatforms = const [],
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      filePath: json['file_path'] ?? '',
      s3Url: json['s3_url'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      uploadDate: DateTime.parse(json['upload_date'] ?? DateTime.now().toIso8601String()),
      duration: json['duration'] ?? 0,
      thumbnailPath: json['thumbnail_path'] ?? '',
      isPublished: json['is_published'] ?? false,
      publishedPlatforms: List<String>.from(json['published_platforms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_path': filePath,
      's3_url': s3Url,
      'tags': tags,
      'upload_date': uploadDate.toIso8601String(),
      'duration': duration,
      'thumbnail_path': thumbnailPath,
      'is_published': isPublished,
      'published_platforms': publishedPlatforms,
    };
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    String? s3Url,
    List<String>? tags,
    DateTime? uploadDate,
    int? duration,
    String? thumbnailPath,
    bool? isPublished,
    List<String>? publishedPlatforms,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      s3Url: s3Url ?? this.s3Url,
      tags: tags ?? this.tags,
      uploadDate: uploadDate ?? this.uploadDate,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isPublished: isPublished ?? this.isPublished,
      publishedPlatforms: publishedPlatforms ?? this.publishedPlatforms,
    );
  }
}