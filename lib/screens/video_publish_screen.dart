import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';

class VideoPublishScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPublishScreen({super.key, required this.video});

  @override
  State<VideoPublishScreen> createState() => _VideoPublishScreenState();
}

class _VideoPublishScreenState extends State<VideoPublishScreen> {
  final VideoService _videoService = VideoService();
  
  final Map<String, bool> _selectedPlatforms = {
    'facebook': false,
    'instagram': false,
    'youtube': false,
    'tiktok': false,
    'x': false,
    'linkedin': false,
  };

  final Map<String, String> _platformNames = {
    'facebook': 'Facebook',
    'instagram': 'Instagram',
    'youtube': 'YouTube',
    'tiktok': 'TikTok',
    'x': 'X (Twitter)',
    'linkedin': 'LinkedIn',
  };

  final Map<String, IconData> _platformIcons = {
    'facebook': Icons.facebook,
    'instagram': Icons.photo_camera,
    'youtube': Icons.play_circle_filled,
    'tiktok': Icons.music_video,
    'x': Icons.alternate_email,
    'linkedin': Icons.business,
  };

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Pre-select platforms where the video is already published
    for (final platform in widget.video.publishedPlatforms) {
      if (_selectedPlatforms.containsKey(platform)) {
        _selectedPlatforms[platform] = true;
      }
    }
  }

  Future<void> _publishVideo() async {
    final selectedPlatforms = _selectedPlatforms.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one platform')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final success = await _videoService.publishVideo(
        videoId: widget.video.id,
        platforms: selectedPlatforms,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video publicado exitosamente!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar el video: $e')),
      );
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Video'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: widget.video.thumbnailPath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.video.thumbnailPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.video_library, size: 40),
                                  ),
                                )
                              : const Icon(Icons.video_library, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (widget.video.description.isNotEmpty)
                                Text(
                                  widget.video.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.video.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        children: widget.video.tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccionar las plataformas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedPlatforms.length,
                itemBuilder: (context, index) {
                  final platform = _selectedPlatforms.keys.elementAt(index);
                  final isSelected = _selectedPlatforms[platform] ?? false;
                  final isAlreadyPublished = widget.video.publishedPlatforms.contains(platform);
                  
                  return Card(
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(_platformIcons[platform], size: 24),
                          const SizedBox(width: 12),
                          Text(_platformNames[platform] ?? platform),
                          if (isAlreadyPublished) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Publicados',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: isAlreadyPublished 
                          ? const Text('Ya fue publicado en esta plataforma')
                          : null,
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          _selectedPlatforms[platform] = value ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publishVideo,
                child: _isPublishing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Publicando...'),
                        ],
                      )
                    : const Text('Publicar Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}