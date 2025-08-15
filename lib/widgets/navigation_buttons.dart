import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:qh_app/widgets/stepper_form.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class NavigationButtons extends StatefulWidget {
  final PageController pageController;
  final GlobalKey<FormState> formKey;
  final StepperFormState stepperFormState;

  const NavigationButtons({
    super.key,
    required this.pageController,
    required this.formKey,
    required this.stepperFormState,
  });

  @override
  NavigationButtonsState createState() => NavigationButtonsState();
}

class NavigationButtonsState extends State<NavigationButtons> {
  int _currentStep = 0;
  bool _isButtonDisabled = false;

  Future<void> _nextStep() async {
    if (_isButtonDisabled) return;
    setState(() {
      _isButtonDisabled = true;
    });

    if (widget.formKey.currentState!.validate()) {
      if (_currentStep == 0 &&
          widget.stepperFormState.tipoIdentificacion == 'Cédula') {
        await widget.stepperFormState.sendRequest();
        if (widget.stepperFormState.responseRequest.contains("Nombre") ==
            false) {
          setState(() {
            _isButtonDisabled = false;
          });
          return;
        }
        await showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Identificación'),
              content: Text(widget.stepperFormState.responseRequest),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }

      if (_currentStep == 2 &&
          !widget.stepperFormState.validateGruposPrioritarios()) {
        showSnackbar(
            'Por favor, seleccione al menos un grupo de atención prioritaria.');
        setState(() {
          _isButtonDisabled = false;
        });
        return;
      }

      if (_currentStep < 5) {
        await widget.pageController.nextPage(
          duration: const Duration(milliseconds: 150),
          curve: Curves.ease,
        );
        setState(() {
          _currentStep += 1;
        });
      } else {
        if (widget.stepperFormState.isCheckedTerminosCondiciones == false) {
          showSnackbar('Es necesario aceptar los términos y condiciones');
          setState(() {
            _isButtonDisabled = false;
          });
          return;
        }
        _submitDenuncia();
        setState(() {
          _isButtonDisabled = true;
        });
        return;
      }
    }

    setState(() {
      _isButtonDisabled = false;
    });
  }

  void showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration:
              const Duration(seconds: 4), // Duración opcional del Snackbar
        ),
      );
    }
  }

  String concatenarGruposPrioritarios(Map<String, bool> mapa) {
    List<String> gruposPrioritariosElegidos = [];
    mapa.forEach((clave, valor) {
      if (valor) {
        if (clave == 'Otro (especifique)') {
          gruposPrioritariosElegidos
              .add(widget.stepperFormState.otroController.text);
        } else {
          gruposPrioritariosElegidos.add(clave);
        }
      }
    });
    return gruposPrioritariosElegidos.join(", ");
  }

  Future<void> _submitDenuncia() async {
    widget.stepperFormState.setState(() {
      widget.stepperFormState.isLoading = true;
    });

    var url = Uri.parse('https://quitohonesto.ec/api/denuncias/');
    var request = http.MultipartRequest('POST', url)
      ..fields['canal_denuncia'] = 'App'
      ..fields['tipoIdDenunciante_denuncia'] =
          widget.stepperFormState.tipoIdentificacion!
      ..fields['numIdDenunciante_denuncia'] =
          widget.stepperFormState.numeroIdentificacionController.text
      ..fields['nombreDenunciante_denuncia'] =
          widget.stepperFormState.nombreDenuncianteController.text
      ..fields['telefonoDenunciante_denuncia'] =
          widget.stepperFormState.telefonoController.text
      ..fields['emailDenunciante_denuncia'] =
          widget.stepperFormState.emailController.text
      ..fields['direccionDenunciante_denuncia'] =
          widget.stepperFormState.direccionController.text
      ..fields['etniaDenunciante_denuncia'] = widget.stepperFormState.etnia!
      ..fields['generoDenunciante_denuncia'] = widget.stepperFormState.genero!
      ..fields['rangoEdadDenunciante_denuncia'] = widget.stepperFormState.edad!
      ..fields['APDenunciante_denuncia'] =
          widget.stepperFormState.perteneceGrupo == 'si' ? 'true' : 'false'
      ..fields['GPDenunciante_denuncia'] = concatenarGruposPrioritarios(
          widget.stepperFormState.gruposPrioritarios)
      ..fields['informacion_denuncia'] =
          widget.stepperFormState.hechosController.text
      ..fields['nombreDenunciado_denuncia'] =
          widget.stepperFormState.servidorMunController.text
      ..fields['dependencias_municipales_id_dependencia'] =
          widget.stepperFormState.idEntidad
      ..fields['infoExtra_denunciado'] =
          widget.stepperFormState.infoAdicionalController.text
      ..fields['RDPD_denuncia'] =
          widget.stepperFormState.isCheckedDatosPersonales.toString();

    if (widget.stepperFormState.filePath != '') {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          File(widget.stepperFormState.filePath).path,
        ),
      );
    }

    try {
      final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioClient);
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // final data = jsonDecode(response.body);
        showDialog(
            // ignore: use_build_context_synchronously
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: const Text('Denuncia creada'),
                  content: const Text(
                      'Se ha enviado un código de verificación a su correo electrónico'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Aceptar'),
                    )
                  ]);
            });
      } else {
        showSnackbar('Error al crear la denuncia: ${response.statusCode}');
        showSnackbar('Cuerpo de la respuesta: ${response.body}');
      }
    } catch (e) {
      showSnackbar("Error al enviar la denuncia: $e");
    } finally {
      widget.stepperFormState.setState(() {
        widget.stepperFormState.isLoading = false;
      });
    }
  }

  void _previousStep() {
    if (_isButtonDisabled || _currentStep == 0) return;
    setState(() {
      _isButtonDisabled = true;
    });

    widget.pageController.previousPage(
      duration: const Duration(milliseconds: 150),
      curve: Curves.ease,
    );
    setState(() {
      _currentStep -= 1;
      _isButtonDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentStep > 0
            ? ElevatedButton(
                onPressed: _isButtonDisabled ? null : _previousStep,
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
                child: const Text('Anterior'),
              )
            : const SizedBox.shrink(),
        ElevatedButton(
          onPressed: _isButtonDisabled ? null : _nextStep,
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
          child: Text(_currentStep == 5 ? 'Enviar' : 'Siguiente'),
        ),
      ],
    );
  }
}
