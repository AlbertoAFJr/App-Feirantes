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
    _limparCampos();
    await _carregarFiado();
  }

  void _limparCampos() {
    _nomeCtrl.clear();
    _celCtrl.clear();
    _valorCtrl.clear();
    setState(() => _dataCompra = DateTime.now());
  }

  // Nova função de confirmar pagamento com escolha entre Dinheiro ou PIX
  Future<void> _confirmarPagamento(int id, String nome, double valor) async {
    final formaPagamento = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar pagamento recebido'),
        content: Text(
            'Deseja confirmar que o cliente "$nome" pagou o valor de R\$ ${valor.toStringAsFixed(2)}? Escolha a forma de pagamento:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'dinheiro'),
            child: const Text('Dinheiro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pix'),
            child: const Text('PIX'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (formaPagamento != null) {
      double dinheiro = 0.0;
      double pix = 0.0;

      if (formaPagamento == 'dinheiro') {
        dinheiro = valor;
      } else if (formaPagamento == 'pix') {
        pix = valor;
      }

      // Adiciona entrada na tabela Entradas
      final entrada = {
        'dinheiro': dinheiro,
        'pix': pix,
        'data': DateTime.now().toIso8601String(),
      };
      await _db.insertEntrada(entrada);

      // Remove registro do fiado
      await _db.deleteFiado(id);
      await _carregarFiado();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pagamento confirmado para $nome como $formaPagamento.')),
      );
    }
  }

  // Função de excluir permanece inalterada
  Future<void> _excluirRegistro(int id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text('Deseja realmente excluir o registro de "$nome"?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.cancel, color: Colors.grey),
            label: const Text('Não'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Sim, excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _db.deleteFiado(id);
      await _carregarFiado();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro de $nome excluído com sucesso.')),
      );
    }
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
                label: const Text('Selecionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _salvarCliente,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Cliente'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Clientes Cadastrados',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Excluir registro',
                                onPressed: () => _excluirRegistro(
                                  c['id'] as int,
                                  c['nome'] as String,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                tooltip: 'Confirmar pagamento',
                                onPressed: () => _confirmarPagamento(
                                  c['id'] as int,
                                  c['nome'] as String,
                                  c['valor'] as double,
                                ),
                              ),
                            ],
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
