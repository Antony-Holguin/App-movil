import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import 'video_upload_screen.dart';
import 'video_publish_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> with SingleTickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<VideoModel> _uploadedVideos = [];
  List<VideoModel> _publishedVideos = [];
  List<VideoModel> _filteredUploadedVideos = [];
  List<VideoModel> _filteredPublishedVideos = [];
  
  bool _isLoadingUploaded = true;
  bool _isLoadingPublished = true;
  String _sortBy = 'date';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    // Cargar videos subidos y publicados en paralelo
    await Future.wait([
      _loadUploadedVideos(),
      _loadPublishedVideos(),
    ]);
  }

  Future<void> _loadUploadedVideos() async {
    setState(() {
      _isLoadingUploaded = true;
    });

    try {
      final videos = await _videoService.getVideos(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
      );
      setState(() {
        _uploadedVideos = videos;
        _filteredUploadedVideos = videos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading uploaded videos: $e')),
      );
    } finally {
      setState(() {
        _isLoadingUploaded = false;
      });
    }
  }

  Future<void> _loadPublishedVideos() async {
    setState(() {
      _isLoadingPublished = true;
    });

    try {
      final videos = await _videoService.getPublishedVideos(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
      );
      setState(() {
        _publishedVideos = videos;
        _filteredPublishedVideos = videos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading published videos: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPublished = false;
      });
    }
  }

  void _filterVideos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUploadedVideos = _uploadedVideos;
        _filteredPublishedVideos = _publishedVideos;
      } else {
        _filteredUploadedVideos = _uploadedVideos.where((video) {
          return video.title.toLowerCase().contains(query.toLowerCase()) ||
                 video.description.toLowerCase().contains(query.toLowerCase()) ||
                 video.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
        
        _filteredPublishedVideos = _publishedVideos.where((video) {
          return video.title.toLowerCase().contains(query.toLowerCase()) ||
                 video.description.toLowerCase().contains(query.toLowerCase()) ||
                 video.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _sortVideos(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      
      _filteredUploadedVideos.sort((a, b) {
        switch (sortBy) {
          case 'title':
            return a.title.compareTo(b.title);
          case 'date':
          default:
            return b.uploadDate.compareTo(a.uploadDate);
        }
      });
      
      _filteredPublishedVideos.sort((a, b) {
        switch (sortBy) {
          case 'title':
            return a.title.compareTo(b.title);
          case 'date':
          default:
            return b.uploadDate.compareTo(a.uploadDate);
        }
      });
    });
  }

  Future<void> _deleteVideo(VideoModel video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Video'),
        content: Text('Estas seguro que quieres eliminar el video "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _videoService.deleteVideo(video.id);
        setState(() {
          _uploadedVideos.removeWhere((v) => v.id == video.id);
          _publishedVideos.removeWhere((v) => v.id == video.id);
          _filteredUploadedVideos.removeWhere((v) => v.id == video.id);
          _filteredPublishedVideos.removeWhere((v) => v.id == video.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting video: $e')),
        );
      }
    }
  }

  Widget _buildVideoList(List<VideoModel> videos, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se han encontrado videos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoListItem(
          video: video,
          onDelete: () => _deleteVideo(video),
          onPublish: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoPublishScreen(video: video),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Videos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: _sortVideos,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Ordenar por fecha'),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Text('Ordenar por titulo'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Subidos', icon: Icon(Icons.upload)),
            Tab(text: 'Publicados', icon: Icon(Icons.public)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar videos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterVideos,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoList(_filteredUploadedVideos, _isLoadingUploaded),
                _buildVideoList(_filteredPublishedVideos, _isLoadingPublished),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const VideoUploadScreen(),
            ),
          );
          if (result != null) {
            _loadVideos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class VideoListItem extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onDelete;
  final VoidCallback onPublish;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onDelete,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: video.thumbnailPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnailPath,
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
                        video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(video.uploadDate)} • ${_formatDuration(video.duration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (video.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: video.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (video.isPublished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Published',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Publish'),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}