import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaRow extends StatelessWidget {
  const SocialMediaRow({super.key});

  // Mapa combinado de URLs y rutas de imagen
  static const Map<String, Map<String, String>> socialMediaData = {
    "Youtube": {
      "url": "https://www.youtube.com/@quitohonesto9401",
      "image": "assets/social_media/youtube_logo.png",
    },
    "Tiktok": {
      "url": "https://www.tiktok.com/@quitohonesto",
      "image": "assets/social_media/tiktok_logo.png",
    },
    "Twitter": {
      "url": "https://twitter.com/quitohonesto",
      "image": "assets/social_media/x_logo.png",
    },
    "Facebook": {
      "url": "https://www.facebook.com/quitohonesto/?locale=es_LA",
      "image": "assets/social_media/facebook_logo.png",
    },
    "Instagram": {
      "url": "https://www.instagram.com/quitohonesto/",
      "image": "assets/social_media/instagram_logo.png",
    },
  };

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: socialMediaData.entries.map((entry) {
        final String title = entry.key;
        final String url = entry.value["url"]!;
        final String imagePath = entry.value["image"]!;

        return IconButton(
          icon: Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
          onPressed: () => _launchURL(url),
          tooltip: title,
        );
      }).toList(),
    );
  }
}
