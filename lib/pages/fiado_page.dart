import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class FiadoPage extends StatefulWidget {
  const FiadoPage({super.key});
  @override
  State<FiadoPage> createState() => _FiadoPageState();
}

class _FiadoPageState extends State<FiadoPage> {
  final _nomeCtrl = TextEditingController();
  final _celCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  DateTime _dataCompra = DateTime.now();
  List<Map<String, dynamic>> _clientes = [];

  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _carregarFiado();
  }

  Future<void> _carregarFiado() async {
    final rows = await _db.getFiado();
    setState(() {
      _clientes = rows.map((e) {
        return {
          'id': e['id'],
          'nome': e['nome'],
          'celular': e['celular'],
          'valor': (e['valor'] is int)
              ? (e['valor'] as int).toDouble()
              : (e['valor'] as double? ?? 0.0),
          'data': DateTime.parse(e['data'] as String),
        };
      }).toList();
    });
  }

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _selecionarData() async {
    final DateTime? novo = await showDatePicker(
      context: context,
      initialDate: _dataCompra,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (novo != null) setState(() => _dataCompra = novo);
  }

  Future<void> _salvarCliente() async {
    final nome = _nomeCtrl.text.trim();
    final celular = _celCtrl.text.trim();
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

    if (nome.isEmpty || valor <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preencha nome e valor corretamente')));
      return;
    }

    final row = {
      'nome': nome,
      'celular': celular,
      'valor': valor,
      'data': _dataCompra.toIso8601String(),
    };

    await _db.insertFiado(row);
    _nomeCtrl.clear();
    _celCtrl.clear();
    _valorCtrl.clear();
    await _carregarFiado();
  }

  Future<void> _removerCliente(int id) async {
    await _db.deleteFiado(id);
    await _carregarFiado();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _celCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Cliente')),
          const SizedBox(height: 8),
          TextField(controller: _celCtrl, decoration: const InputDecoration(labelText: 'Celular')),
          const SizedBox(height: 8),
          TextField(
            controller: _valorCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))
            ],
            decoration: const InputDecoration(labelText: 'Valor (R\$)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Data: ${_fmtDate(_dataCompra)}'),
              const Spacer(),
              ElevatedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Selecionar')),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _salvarCliente, child: const Text('Salvar Cliente')),
          const SizedBox(height: 16),
          const Divider(),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Clientes Cadastrados', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Expanded(
            child: _clientes.isEmpty
                ? const Center(child: Text('Nenhum cliente cadastrado'))
                : ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (_, i) {
                      final c = _clientes[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text('${c['nome']} - R\$ ${(c['valor'] as double).toStringAsFixed(2)}'),
                          subtitle: Text('Data: ${_fmtDate(c['data'] as DateTime)}\nCelular: ${c['celular']}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _removerCliente(c['id'] as int),
                          ),
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
