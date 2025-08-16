import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class VideoService {
  static const String baseUrl = 'https://18.228.5.49:443';
  
  Future<List<VideoModel>> getVideos({String? search, String? sortBy}) async {
    try {
      // Usar endpoints disponibles según el tipo de video
      var uri = Uri.parse('$baseUrl/videos/uploaded');
      
      // Configurar headers para HTTPS
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        
        // Manejo flexible del formato de respuesta
        List<dynamic> videoList;
        if (jsonData is List) {
          videoList = jsonData;
        } else if (jsonData is Map && jsonData['data'] != null) {
          videoList = jsonData['data'];
        } else if (jsonData is Map && jsonData['videos'] != null) {
          videoList = jsonData['videos'];
        } else {
          videoList = [];
        }
        
        List<VideoModel> videos = videoList.map((json) {
          try {
            return VideoModel.fromJson(json);
          } catch (e) {
            // Crear modelo básico si hay error en el parsing
            return VideoModel(
              id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: json['title']?.toString() ?? 'Video sin título',
              description: json['description']?.toString() ?? '',
              filePath: json['file_path']?.toString() ?? '',
              s3Url: json['s3_url']?.toString() ?? json['url']?.toString() ?? '',
              tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
              uploadDate: DateTime.tryParse(json['upload_date']?.toString() ?? '') ?? DateTime.now(),
              duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
              thumbnailPath: json['thumbnail_path']?.toString() ?? json['thumbnail']?.toString() ?? '',
              isPublished: json['is_published'] == true || json['published'] == true,
              publishedPlatforms: json['published_platforms'] is List 
                  ? List<String>.from(json['published_platforms']) 
                  : [],
            );
          }
        }).toList();
        
        // Aplicar filtros localmente si son necesarios
        if (search != null && search.isNotEmpty) {
          videos = videos.where((video) {
            return video.title.toLowerCase().contains(search.toLowerCase()) ||
                   video.description.toLowerCase().contains(search.toLowerCase()) ||
                   video.tags.any((tag) => tag.toLowerCase().contains(search.toLowerCase()));
          }).toList();
        }
        
        // Aplicar ordenamiento
        if (sortBy == 'title') {
          videos.sort((a, b) => a.title.compareTo(b.title));
        } else {
          videos.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        }
        
        return videos;
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }

  Future<List<VideoModel>> getPublishedVideos({String? search, String? sortBy}) async {
    try {
      var uri = Uri.parse('$baseUrl/videos/published');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        
        List<dynamic> videoList;
        if (jsonData is List) {
          videoList = jsonData;
        } else if (jsonData is Map && jsonData['data'] != null) {
          videoList = jsonData['data'];
        } else if (jsonData is Map && jsonData['videos'] != null) {
          videoList = jsonData['videos'];
        } else {
          videoList = [];
        }
        
        List<VideoModel> videos = videoList.map((json) {
          try {
            return VideoModel.fromJson(json);
          } catch (e) {
            return VideoModel(
              id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: json['title']?.toString() ?? 'Video sin título',
              description: json['description']?.toString() ?? '',
              filePath: json['file_path']?.toString() ?? '',
              s3Url: json['s3_url']?.toString() ?? json['url']?.toString() ?? '',
              tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
              uploadDate: DateTime.tryParse(json['upload_date']?.toString() ?? '') ?? DateTime.now(),
              duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
              thumbnailPath: json['thumbnail_path']?.toString() ?? json['thumbnail']?.toString() ?? '',
              isPublished: true, // Son videos publicados
              publishedPlatforms: json['published_platforms'] is List 
                  ? List<String>.from(json['published_platforms']) 
                  : [],
            );
          }
        }).toList();
        
        return videos;
      } else {
        throw Exception('Failed to load published videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching published videos: $e');
    }
  }

  Future<VideoModel> uploadVideo({
    required File videoFile,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/videos/upload'));
      
      request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['tags'] = json.encode(tags);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return VideoModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to upload video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  Future<bool> publishVideo({
    required String videoId,
    required List<String> platforms,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/publish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'platforms': platforms}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error publishing video: $e');
    }
  }

  Future<bool> deleteVideo(String videoId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/videos/$videoId'));
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting video: $e');
    }
  }
}