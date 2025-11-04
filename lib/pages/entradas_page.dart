import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key});
  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

class _EntradasPageState extends State<EntradasPage> {
  final _dinheiroCtrl = TextEditingController();
  final _pixCtrl = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> _entradas = [];

  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _carregarEntradas();
  }

  Future<void> _carregarEntradas() async {
    final rows = await _db.getEntradas();
    setState(() {
      _entradas = rows.map((e) {
        return {
          'id': e['id'],
          'dinheiro': (e['dinheiro'] is int)
              ? (e['dinheiro'] as int).toDouble()
              : (e['dinheiro'] as double? ?? 0.0),
          'pix': (e['pix'] is int)
              ? (e['pix'] as int).toDouble()
              : (e['pix'] as double? ?? 0.0),
          'data': DateTime.parse(e['data'] as String),
        };
      }).toList();
    });
  }

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _selecionarData() async {
    final DateTime? novo = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (novo != null) setState(() => _dataSelecionada = novo);
  }

  Future<void> _salvarEntrada() async {
    final dinheiro = double.tryParse(_dinheiroCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final pix = double.tryParse(_pixCtrl.text.replaceAll(',', '.')) ?? 0.0;

    if (dinheiro <= 0 && pix <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Informe pelo menos um valor maior que 0')));
      return;
    }

    final row = {
      'dinheiro': dinheiro,
      'pix': pix,
      'data': _dataSelecionada.toIso8601String(),
    };

    await _db.insertEntrada(row);
    _dinheiroCtrl.clear();
    _pixCtrl.clear();
    await _carregarEntradas();
  }

  @override
  void dispose() {
    _dinheiroCtrl.dispose();
    _pixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _dinheiroCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))
            ],
            decoration: const InputDecoration(labelText: 'Valor em Dinheiro (ex: 15.45)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pixCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))
            ],
            decoration: const InputDecoration(labelText: 'Valor em PIX (ex: 10.00)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Data: ${_fmtDate(_dataSelecionada)}'),
              const Spacer(),
              ElevatedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Selecionar')),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: _salvarEntrada,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Entrada')),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Histórico de Entradas',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Expanded(
            child: _entradas.isEmpty
                ? const Center(child: Text('Nenhuma entrada registrada'))
                : ListView.builder(
                    itemCount: _entradas.length,
                    itemBuilder: (_, i) {
                      final e = _entradas[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.attach_money),
                          title: Text(
                              'Dinheiro: R\$ ${(e['dinheiro'] as double).toStringAsFixed(2)}  •  Pix: R\$ ${(e['pix'] as double).toStringAsFixed(2)}'),
                          subtitle: Text('Data: ${_fmtDate(e['data'] as DateTime)}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
