import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/video_service.dart';
import '../models/video_model.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final VideoService _videoService = VideoService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    if (_cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin camaras disponibles')),
      );
      return;
    }

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesitan permisos para abrir la camara')),
      );
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        await _setVideoFile(File(video.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        await _setVideoFile(File(video.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting video: $e')),
      );
    }
  }

  Future<void> _setVideoFile(File file) async {
    setState(() {
      _videoFile = file;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    
    try {
      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing video controller: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video and add a title')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final uploadedVideo = await _videoService.uploadVideo(
        videoFile: _videoFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        tags: tags,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );

      Navigator.of(context).pop(uploadedVideo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Video'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_videoFile == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.videocam, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Selecciona un video para subir',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _recordVideo,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Grabar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeria'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Column(
                  children: [
                    if (_videoController?.value.isInitialized ?? false)
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_videoController?.value.isPlaying ?? false) {
                                _videoController?.pause();
                              } else {
                                _videoController?.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              (_videoController?.value.isPlaying ?? false)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _videoFile = null;
                                _videoController?.dispose();
                                _videoController = null;
                              });
                            },
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'Example: travel, nature, adventure',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Upload Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}