import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'video_list_screen.dart';
import 'video_upload_screen.dart';

class SecondHomePage extends StatelessWidget{
    const SecondHomePage({super.key});

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(
                title: Text('SocialManApp'),
                actions: [
                    IconButton(icon: Icon(Icons.search),
                        onPressed: (){
                            print('Button pressed');
                        }
                    )
                ],

            ),

          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.video_library,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  'SocialManApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Plataforma para subida de videos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VideoListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: const Text('Mis Videos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VideoUploadScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Subir videos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
}