import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/io_client.dart';
import 'package:qh_app/models/entidad.dart';
import 'package:qh_app/widgets/circle_progress_with_text.dart';
import 'package:qh_app/widgets/navigation_buttons.dart';

class StepperForm extends StatefulWidget {
  const StepperForm({super.key});

  @override
  StepperFormState createState() => StepperFormState();
}

class StepperFormState extends State<StepperForm> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? tipoIdentificacion, genero, etnia, edad;
  String _entidadMunicipal = "Desconozco";
  String idEntidad = '1';
  String perteneceGrupo = 'si';
  bool? isCheckedDatosPersonales = false;
  bool? isCheckedTerminosCondiciones = false;
  String responseRequest = '';
  bool isLoading = false;

  Map<String, bool> gruposPrioritarios = {
    'Embarazada': false,
    'Con discapacidad': false,
    'Tercera edad': false,
    'Otro (especifique)': false,
  };

  final TextEditingController nombreDenuncianteController =
      TextEditingController();
  final TextEditingController servidorMunController = TextEditingController();
  final TextEditingController infoAdicionalController = TextEditingController();
  final TextEditingController hechosController = TextEditingController();
  final TextEditingController otroController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController numeroIdentificacionController =
      TextEditingController();

  String filePath = '';
  List<Entidad> entidades = [];
  String errorMessageFetch = '';

  Future<void> fetchEntidades() async {
    HttpClient client = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    try {
      final uri = Uri.parse('https://quitohonesto.ec/api/entidades/');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);

        if (mounted) {
          setState(() {
            entidades = data
                .map((e) => Entidad(
                    idDependencia: e['id_dependencia'].toString(),
                    entidadDependencia: e['entidad_dependencia'] as String))
                .toList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessageFetch = 'Error: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessageFetch = 'Error: $e';
        });
      }
    } finally {
      client.close();
    }
  }

  Future<void> sendRequest() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://quitohonesto.ec/api/dinardap/ciudadano/verificar/identificacion');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "tipoIdDenunciante_denuncia": tipoIdentificacion,
      "numIdDenunciante_denuncia": numeroIdentificacionController.text,
      "fecha_expedicion": _dateController.text
    });

    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    final client = IOClient(ioClient);

    try {
      final response = await client.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          responseRequest =
              'Nombre: ${responseData['nombreDenunciante_denuncia']}';
          nombreDenuncianteController.text =
              responseData['nombreDenunciante_denuncia'];
        });
      } else {
        setState(() {
          // responseRequest = 'Error: ${response.statusCode}';
          responseRequest = "No se encontró al ciudadano";
        });
      }
    } catch (e) {
      setState(() {
        responseRequest = "Revisar su conexión a internet";
        // responseRequest = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openFileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        filePath = result.files.single.path!;
      });
    } else {
      setState(() {
        filePath = ''; // El usuario ha cancelado la selección
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  String? _validarIdentificacion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingrese su identificación';
    }

    if (tipoIdentificacion == 'Pasaporte') {
      // Ejemplo de validación para pasaporte (alfanumérico y de 8 a 9 caracteres)
      if (!RegExp(r'^[A-Za-z0-9]{8,10}$').hasMatch(value)) {
        return 'Número de pasaporte no válido';
      }
    } else if (tipoIdentificacion == 'Cédula') {
      // Ejemplo de validación para cédula (solo números y de 10 caracteres)
      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
        return 'Número de cédula no válido';
      }
    }

    return null;
  }

  bool validateGruposPrioritarios() {
    if (perteneceGrupo == 'si' && !gruposPrioritarios.containsValue(true)) {
      return false;
    }
    return true;
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Términos y Condiciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Estimado usuario: previo a realizar el envío de su denuncia, le recordamos que es de su entera responsabilidad proporcionar información e identidad verídica, la cual será sometida a un proceso de validación. Además, al marcar esta casilla, Usted acepta y autoriza de manera previa, libre, expresa, inequívoca e informada a la Comisión Metropolitana de Lucha Contra la Corrupción-Quito Honesto el tratamiento de sus datos personales, exclusivamente dentro del marco de la investigación y trámite de su denuncia, por lo que confirma que entiende y acepta lo expuesto.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                setState(() {
                  isCheckedTerminosCondiciones = true;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReservaDatosPersonales() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Reserva de Datos Personales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'La denuncia será pública, sin perjuicio de que los datos de identificación personal del denunciante, procesado o de la víctima, se guarden en reserva para su protección. (COIP Art. 421)',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                setState(() {
                  isCheckedDatosPersonales = true;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nombreDenuncianteController.dispose();
    infoAdicionalController.dispose();
    servidorMunController.dispose();
    hechosController.dispose();
    _dateController.dispose();
    otroController.dispose();
    numeroIdentificacionController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (mounted) {
      fetchEntidades();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep(
                    step: 1,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Tipo de Identificación',
                            hintText: 'Seleccione su identificación',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: tipoIdentificacion,
                          items: <String>['Cédula', 'Pasaporte']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    value == 'Cédula'
                                        ? Icons.credit_card
                                        : Icons.public,
                                    color: const Color(0xFF094780)
                                        .withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              tipoIdentificacion = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, seleccione un tipo de identificación';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: numeroIdentificacionController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: tipoIdentificacion == 'Pasaporte'
                                ? 'Número de Pasaporte'
                                : 'Número de Cédula',
                            hintText: tipoIdentificacion == 'Pasaporte'
                                ? 'Ingrese su pasaporte'
                                : 'Ingrese su cédula',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: tipoIdentificacion == 'Pasaporte'
                              ? TextInputType.text
                              : TextInputType.number,
                          validator: _validarIdentificacion,
                        ),
                        const SizedBox(height: 20),
                        if (tipoIdentificacion == 'Pasaporte')
                          TextFormField(
                            controller: nombreDenuncianteController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              labelText: 'Nombre Completo',
                              hintText: 'Ingrese sus nombres y apellidos',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingrese sus nombres y apellidos';
                              }
                              return null;
                            },
                          )
                        else
                          Column(
                            children: [
                              TextFormField(
                                controller: _dateController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 10),
                                  labelText: 'Fecha de Emisión (Cédula)',
                                  hintText: 'Seleccione fecha de emisión',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    color: const Color(0xFF094780)
                                        .withOpacity(0.7),
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () => _selectDate(context),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () => _selectDate(context),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, seleccione la fecha de emisión';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(responseRequest),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildStep(
                    step: 2,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: telefonoController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Número Telefónico',
                            hintText: 'Ej. 0987654321',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: const Color(0xFF094780).withOpacity(0.7),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su teléfono';
                            }
                            final phoneExp = RegExp(r'^[0-9]{7,10}$');
                            if (!phoneExp.hasMatch(value)) {
                              return 'Ingrese un número telefónico válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Correo Electrónico',
                            hintText: 'Ingrese su correo',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: const Color(0xFF094780).withOpacity(0.7),
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
                          controller: direccionController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Dirección',
                            hintText: 'Ingrese su dirección (opcional)',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.home,
                              color: const Color(0xFF094780).withOpacity(0.7),
                            ),
                          ),
                          validator: (value) {
                            // La dirección es opcional, así que no hay validación aquí
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Género',
                            hintText: 'Seleccione su género',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: genero,
                          items: <String>[
                            'Femenino',
                            'LGBTQ+',
                            'Masculino',
                            'Sin especificar',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              genero = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, seleccione su género';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Etnia',
                            hintText: 'Seleccione su etnia',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: etnia,
                          items: <String>[
                            'Afroecuatoriano',
                            'Blanco',
                            'Indígena',
                            'Mestizo',
                            'Montubio',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              etnia = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, seleccione su etnia';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            labelText: 'Edad',
                            hintText: 'Seleccione su edad',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: edad,
                          items: <String>[
                            'Menor a 18',
                            '18 a 24 años',
                            '25 a 64 años',
                            'Mayor a 65'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              edad = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, seleccione su edad';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    step: 3,
                    child: Column(
                      children: [
                        const Text(
                          '¿Pertenece a algún grupo de atención prioritaria?',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 10.0),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      perteneceGrupo = 'si';
                                      gruposPrioritarios.forEach((key, _) {
                                        gruposPrioritarios[key] = false;
                                      });
                                      otroController.clear();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: perteneceGrupo == 'si'
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8.0),
                                        bottomLeft: Radius.circular(8.0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Si',
                                        style: TextStyle(
                                          color: perteneceGrupo == 'si'
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      perteneceGrupo = 'no';
                                      gruposPrioritarios.forEach((key, _) {
                                        gruposPrioritarios[key] = false;
                                      });
                                      otroController.clear();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: perteneceGrupo == 'no'
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8.0),
                                        bottomRight: Radius.circular(8.0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No',
                                        style: TextStyle(
                                          color: perteneceGrupo == 'no'
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (perteneceGrupo == 'si') ...[
                          const SizedBox(height: 16.0),
                          const Text(
                            '¿A qué grupo de atención prioritaria pertenece?',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          const SizedBox(height: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: gruposPrioritarios.keys.map((String key) {
                              return Container(
                                height: 55,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: gruposPrioritarios[key]!
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    key,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: gruposPrioritarios[key]!
                                            ? Colors.white
                                            : null),
                                  ),
                                  value: gruposPrioritarios[key],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      gruposPrioritarios[key] = value ?? false;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          if (gruposPrioritarios['Otro (especifique)'] ??
                              false) ...[
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: otroController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                labelText: 'Grupo prioritario',
                                hintText: 'Ingrese su grupo prioritario',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese su grupo prioritario';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  _buildStep(
                    step: 4,
                    child: TextFormField(
                      controller: hechosController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: 'Narración de los hechos',
                        hintText: 'Describa lo sucedido',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, describa lo sucedido';
                        }
                        return null;
                      },
                    ),
                  ),
                  _buildStep(
                      step: 5,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: servidorMunController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              labelText: 'Servidor Municipal',
                              hintText: 'Ingrese nombre y apellido (opcional)',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          if (errorMessageFetch.isNotEmpty)
                            Text(errorMessageFetch)
                          else
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                labelText: 'Entidad Municipal',
                                hintText: 'Seleccione la entidad',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              isExpanded: true,
                              value: _entidadMunicipal,
                              items: entidades.map<DropdownMenuItem<String>>(
                                  (Entidad entidad) {
                                return DropdownMenuItem<String>(
                                  value: entidad.entidadDependencia,
                                  child: Text(
                                    entidad.entidadDependencia,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _entidadMunicipal = newValue!;
                                  for (Entidad entidad in entidades) {
                                    if (entidad.entidadDependencia ==
                                        _entidadMunicipal) {
                                      idEntidad = entidad.idDependencia;
                                    }
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor seleccione una entidad';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: infoAdicionalController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Información adicional',
                              hintText: 'Ingrese información (opcional)',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                        ],
                      )),
                  _buildStep(
                      step: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: ElevatedButton.icon(
                              onPressed: _openFileExplorer,
                              icon: const Icon(Icons.folder_open),
                              label:
                                  const Text('Seleccionar archivo (opcional)'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical:
                                        16.0), // Aumenta el espacio vertical
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Redondea las esquinas del botón
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black),
                                    children: [
                                  const TextSpan(
                                      text: 'Archivo: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )),
                                  TextSpan(text: filePath),
                                ])),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8)),
                            child: CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: isCheckedDatosPersonales,
                                onChanged: (value) {
                                  value == true
                                      ? _showReservaDatosPersonales()
                                      : setState(() {
                                          isCheckedDatosPersonales = value;
                                        });
                                },
                                title: Text(
                                  'Reserva de datos personales (opcional)',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Theme.of(context).colorScheme.primary,
                                      color: Theme.of(context).colorScheme.primary),
                                )),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary
                                      .withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(8)),
                            child: CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: isCheckedTerminosCondiciones,
                                onChanged: (value) {
                                  value == true
                                      ? _showTermsAndConditions()
                                      : setState(() {
                                          isCheckedTerminosCondiciones = value;
                                        });
                                },
                                title: Text(
                                  'Términos y condiciones',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Theme.of(context).colorScheme.primary,
                                      color: Theme.of(context).colorScheme.primary),
                                )),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: NavigationButtons(
              pageController: _pageController,
              formKey: _formKey,
              stepperFormState: this,
            ),
          ),
        ],
      ),
      if (isLoading)
        Positioned.fill(
            child: Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        )),
    ]);
  }

  Widget _buildStep({required int step, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleProgressWithText(
            stepCircle: step,
            size: 95,
            titles: const [
              'Datos del Denunciante',
              'Datos del Denunciante',
              'Datos Adicionales',
              'Denuncia',
              'Datos del Denunciado',
              'Documentación Adjunta'
            ],
            subtitles: const [
              'Identificación',
              'Información Personal',
              'Información Complementaria',
              'Descripción del Incidente',
              'Información del Acusado',
              'Archivos y Evidencias'
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
              child: SingleChildScrollView(
                  child: Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ))),
        ],
      ),
    );
  }
}
