import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class VideoService {
  static const String baseUrl = 'https://your-backend-url.com/api';
  
  Future<List<VideoModel>> getVideos({String? search, String? sortBy}) async {
    try {
      var uri = Uri.parse('$baseUrl/videos');
      var params = <String, String>{};
      
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        params['sort_by'] = sortBy;
      }
      
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
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