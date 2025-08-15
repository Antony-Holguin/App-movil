import 'package:flutter/material.dart';
import 'package:qh_app/widgets/background_container.dart';
import 'package:qh_app/widgets/stepper_form.dart';
import '../widgets/custom_app_bar.dart';

class Denunciar extends StatefulWidget {
  const Denunciar({super.key});

  @override
  DenunciarState createState() => DenunciarState();
}

class DenunciarState extends State<Denunciar> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: 'Denunciar'),
      resizeToAvoidBottomInset: true,
      body: SafeArea(child: BackgroundContainer(child: StepperForm())),
    );
  }
}
