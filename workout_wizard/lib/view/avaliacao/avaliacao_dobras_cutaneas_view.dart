import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workout_wizard/controller/avaliacao_controller.dart';
import 'package:workout_wizard/controller/avaliacao_dobras_controller.dart';
import 'package:workout_wizard/controller/avaliacao_resultado.dart';
import 'package:workout_wizard/controller/login_controller.dart';
import 'package:workout_wizard/model/avaliacao.dart';
import 'package:workout_wizard/model/dobras_cutaneas.dart';
import 'package:workout_wizard/model/resultado.dart';

class AvaliacaoDobrasCutaneasView extends StatefulWidget {
  const AvaliacaoDobrasCutaneasView({super.key});

  @override
  State<AvaliacaoDobrasCutaneasView> createState() =>
      _AvaliacaoDobrasCutaneasViewState();
}

class _AvaliacaoDobrasCutaneasViewState
    extends State<AvaliacaoDobrasCutaneasView> {
  final _formKey = GlobalKey<FormState>();

  final List<String> labels = [
    'Tríceps',
    'Peitoral',
    'Axilar Média',
    'Subescapular',
    'Supra-ilíaca',
    'Abdominal',
    'Coxa',
  ];

  final List<TextEditingController> controllers =
      List.generate(12, (_) => TextEditingController());

  bool isLoading = true;
  String? errorMessage;
  String? avaliacaoId;
  bool isEditing = false;
  String? dobrasId;
  String? resultadoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      avaliacaoId = ModalRoute.of(context)!.settings.arguments as String;
      fetchDobrasCutaneas();
    });
  }

  void fetchDobrasCutaneas() async {
    try {
      if (avaliacaoId != null) {
        final dobrasSnapshot =
            await AvaliacaoDobrasController.listarDobras(avaliacaoId!);
        final resultadoSnapshot = await AvaliacaoResultadoController()
            .getResultadoStream(avaliacaoId!)
            .first;
        resultadoId = resultadoSnapshot.docs.first.id;
        print('Resultado ID: $resultadoId');

        if (dobrasSnapshot.docs.isNotEmpty) {
          isEditing = true;
          dobrasId = dobrasSnapshot.docs.first.id;

          final dobrasData =
              dobrasSnapshot.docs.first.data() as Map<String, dynamic>;

          if (dobrasData != null) {
            final dobrasCutaneas = DobrasCutaneas.fromJson(dobrasData);
            setState(() {
              for (int i = 0; i < labels.length; i++) {
                final String label = labels[i];
                final String value = getValueByLabel(label, dobrasCutaneas);
                controllers[i].text = (value != '0') ? value : '';
              }
              isLoading = false;
            });
          }
        } else {
          setState(() {
            //errorMessage = 'Documento de avaliação não encontrado';
            isLoading = false;
          });
        }
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Erro ao buscar dados: $error';
        isLoading = false;
      });
    }
  }

  String getValueByLabel(String label, DobrasCutaneas dobrasCutaneas) {
    switch (label) {
      case 'Tríceps':
        return dobrasCutaneas.triceps.toString();
      case 'Peitoral':
        return dobrasCutaneas.peitoral.toString();
      case 'Axilar Média':
        return dobrasCutaneas.axilarMedia.toString();
      case 'Subescapular':
        return dobrasCutaneas.subescapular.toString();
      case 'Supra-ilíaca':
        return dobrasCutaneas.supraIliaca.toString();
      case 'Abdominal':
        return dobrasCutaneas.abdominal.toString();
      case 'Coxa':
        return dobrasCutaneas.coxa.toString();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: Text('Dobras Cutaneas'),
        actions: [
          IconButton(
            onPressed: () {
              //LoginController().logout();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        for (int i = 0; i < labels.length; i++)
                          _buildTextFormField(labels[i], controllers[i]),
                        //
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final dobrasCutaneas = DobrasCutaneas(
                                protocolo: 'Pollock 7',
                                avalicaoId: avaliacaoId!,
                                triceps: parseDoubleValue(controllers[0].text),
                                peitoral: parseDoubleValue(controllers[1].text),
                                axilarMedia:
                                    parseDoubleValue(controllers[2].text),
                                subescapular:
                                    parseDoubleValue(controllers[3].text),
                                supraIliaca:
                                    parseDoubleValue(controllers[4].text),
                                abdominal:
                                    parseDoubleValue(controllers[5].text),
                                coxa: parseDoubleValue(controllers[6].text),
                              );

                              // Verifica se as 7 medidas estão presentes
                              bool hasAll7Measures = [
                                controllers[0].text,
                                controllers[1].text,
                                controllers[2].text,
                                controllers[3].text,
                                controllers[4].text,
                                controllers[5].text,
                                controllers[6].text
                              ].every((text) => text.isNotEmpty);

                              final resultado = Resultado.isEmpty();

                              if (hasAll7Measures) {
                                try {
                                  print('Salvando');

                                  print('avalicaoId: $avaliacaoId');
                                  final usuario =
                                      await LoginController().pegarUsuario();
                                  print(usuario);

                                  final avaliacao = await AvaliacaoController()
                                      .getAvaliacao(avaliacaoId!);
                                  print(avaliacao);

                                  resultado.pollock7(
                                      dobrasCutaneas, usuario, avaliacao);

                                  resultado.pollock7(
                                      dobrasCutaneas, usuario, avaliacao);
                                  print(resultado);

                                  AvaliacaoResultadoController()
                                      .atualizarResultado(context, resultado,
                                          avaliacaoId!, resultadoId!);
                                } catch (e) {
                                  print('Ocorreu um erro: $e');
                                }
                              }

                              isEditing
                                  ? AvaliacaoDobrasController().atualizarDobras(
                                      context,
                                      dobrasCutaneas,
                                      avaliacaoId!,
                                      dobrasId!)
                                  : AvaliacaoDobrasController().adicionarDobras(
                                      context, dobrasCutaneas, avaliacaoId!);
                            }
                          },
                          child: Text('Salvar'),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.fitness_center),
          prefixText: '   ', // Add space for the icon and suffix
          suffixText: 'mm',
          suffixStyle: TextStyle(
            color: Colors.grey, // Suffix color
            fontWeight: FontWeight.bold, // Font weight
            fontSize: 16, // Font size
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ], // Allow only numbers and dot
      ),
    );
  }

  @override
  void dispose() {
    controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  double parseDoubleValue(String value) {
    if (value.isEmpty) {
      return 0.0;
    }
    return double.parse(value);
  }
}
