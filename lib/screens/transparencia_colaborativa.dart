import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:qh_app/widgets/background_container.dart';
import '../widgets/custom_app_bar.dart';

class TransparenciaColaborativa extends StatefulWidget {
  const TransparenciaColaborativa({super.key});

  @override
  TransparenciaColaborativaState createState() =>
      TransparenciaColaborativaState();
}

class TransparenciaColaborativaState extends State<TransparenciaColaborativa> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inquiryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDialog();
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'LA COMISIÓN METROPOLITANA DE LUCHA CONTRA LA CORRUPCIÓN ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Invita a representantes de: sociedad civil, organizaciones sociales, empresas, instituciones académicas y gremios, para que presenten sus necesidades específicas de información hacia nuestra institución, que serán respondidas en nuestros eventos mensuales de Transparencia Colaborativa.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Aceptar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _isButtonDisabled = true;
      });

      const username =
          'quitohonestoapp@gmail.com'; // Reemplaza con tu correo electrónico
      const password = 'vusjaatfvtrdzzgj'; // Reemplaza con tu contraseña

      // Configuración del servidor SMTP
      final smtpServer = gmail(username, password);

      // Creación del mensaje de correo
      final message = Message()
        ..from = const Address(username)
        ..recipients.add('comunicacion@quitohonesto.gob.ec')
        ..subject = 'Transparencia Colaborativa | App'
        ..text = '''
        Nombre: ${_nombreController.text}
        Email: ${_emailController.text}
        Requerimiento: ${_inquiryController.text}
      ''';

      try {
        await send(message, smtpServer);
        showSnackbar('Correo enviado correctamente');
      } catch (e) {
        showSnackbar('Error al enviar el correo: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Transparencia Colaborativa'),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BackgroundContainer(
          child: Stack(children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 25, horizontal: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                labelText: 'Nombre y Apellido',
                                hintText: 'Ingrese su nombre y apellido',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color:
                                      const Color(0xFF094780).withOpacity(0.7),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese su nombre y apellido';
                                }

                                List<String> parts = value.trim().split(' ');
                                if (parts.length < 2) {
                                  return 'Por favor, ingrese su nombre y apellido';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                labelText: 'Correo Electrónico',
                                hintText: 'Ingrese su correo',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color:
                                      const Color(0xFF094780).withOpacity(0.7),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese su correo';
                                }
                                final emailExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailExp.hasMatch(value)) {
                                  return 'Ingrese un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _inquiryController,
                              maxLines: 13,
                              decoration: InputDecoration(
                                labelText: 'Requerimiento de Información',
                                hintText: 'Ingrese su requerimiento',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese su requerimiento';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _isButtonDisabled ? null : _sendEmail,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 42)),
                        child: const Text('Enviar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                  child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )),
          ]),
        ),
      ),
    );
  }
}
