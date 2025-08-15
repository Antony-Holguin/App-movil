import 'package:flutter/material.dart';
import 'package:qh_app/screens/transparencia_colaborativa.dart';
import 'package:qh_app/widgets/background_container.dart';
import '../widgets/custom_app_bar.dart';
import 'denunciar.dart';
import 'qh_cifras.dart';
import '../widgets/custom_button.dart';
import '../widgets/social_media_row.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '',
        showBackButton: false,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BackgroundContainer(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Image.asset('assets/logoQH.png'),
                  ),
                  const SizedBox(height: 50),
                  const CustomButton(
                    label: 'DENUNCIAR',
                    icon: Icons.assignment,
                    page: Denunciar(),
                    description: 'Informar sobre una actuación ilegal',
                  ),
                  const SizedBox(height: 20),
                  const CustomButton(
                    label: 'TRANSPARENCIA',
                    icon: Icons.group,
                    page: TransparenciaColaborativa(),
                    description: 'Solicitar información que debería publicarse',
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'QH EN CIFRAS',
                    icon: Icons.bar_chart,
                    page: QhCifras(),
                    description: 'Reportes de la gestión de QH',
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    'Síguenos en nuestras redes sociales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const SocialMediaRow()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
