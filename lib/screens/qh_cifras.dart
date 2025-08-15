import 'package:flutter/material.dart';
import 'package:qh_app/widgets/background_container.dart';
import '../widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class QhCifras extends StatelessWidget {
  final List<Map<String, String>> submenuItems = [
    {
      "title": "Control Contratación Pública",
      "url":
          "https://app.powerbi.com/view?r=eyJrIjoiODRjYWI1ODYtMmJkMS00YWQ5LWI5YzAtMGY3YTBjMTAxZjc0IiwidCI6ImI5OWFhM2QzLTZiYjktNGUyOS05NmI4LWFkODM3NWY2ODBlNyIsImMiOjR9"
    },
    {
      "title": "Eventos de Capacitación",
      "url":
          "https://app.powerbi.com/view?r=eyJrIjoiZWY4YmQ0OTEtM2EyOS00MTBiLWE4YzItMTQwYTMyYjFjZjRmIiwidCI6ImI5OWFhM2QzLTZiYjktNGUyOS05NmI4LWFkODM3NWY2ODBlNyIsImMiOjR9"
    },
    {
      "title": "Gestión Denuncias",
      "url":
          "https://app.powerbi.com/view?r=eyJrIjoiZGE2NzdkMzItMjM0YS00ZGIwLWJjOTUtNjQ1N2RhNjFkMDU1IiwidCI6ImI5OWFhM2QzLTZiYjktNGUyOS05NmI4LWFkODM3NWY2ODBlNyIsImMiOjR9"
    },
    {
      "title": "Procesos Administrativos",
      "url":
          "https://app.powerbi.com/view?r=eyJrIjoiODYxMGY5ZTgtYmY4NC00NGY1LThlNWYtZWExNDg4ZGMzOTdlIiwidCI6ImI5OWFhM2QzLTZiYjktNGUyOS05NmI4LWFkODM3NWY2ODBlNyIsImMiOjR9"
    },
    {
      "title": "Seguimiento de Recomendaciones",
      "url":
          "https://app.powerbi.com/view?r=eyJrIjoiZmEzMmJkMjktN2FmZi00Y2NlLWIzNDYtMGZlNTMxM2I4ZDhkIiwidCI6ImI5OWFhM2QzLTZiYjktNGUyOS05NmI4LWFkODM3NWY2ODBlNyIsImMiOjR9"
    },
  ];

  QhCifras({super.key});

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'QH en Cifras'),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BackgroundContainer(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: submenuItems.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        item["title"]!,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(Icons.launch,
                          color: Theme.of(context).colorScheme.primary),
                      onTap: () => _launchURL(item["url"]!),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
