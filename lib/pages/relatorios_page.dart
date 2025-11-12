import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database_helper.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final dbHelper = DatabaseHelper();
  DateTimeRange? _periodoSelecionado;

  double valorDinheiro = 0.0;
  double valorPix = 0.0;
  double valorFiado = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final entradas = await dbHelper.getEntradas();
    final fiados = await dbHelper.getFiado();

    double dinheiro = 0.0;
    double pix = 0.0;
    double fiado = 0.0;

    for (var e in entradas) {
      final data = DateTime.tryParse(e['data'] ?? '') ?? DateTime.now();
      if (_estaNoPeriodo(data)) {
        dinheiro += (e['dinheiro'] ?? 0);
        pix += (e['pix'] ?? 0);
      }
    }

    for (var f in fiados) {
      final data = DateTime.tryParse(f['data'] ?? '') ?? DateTime.now();
      if (_estaNoPeriodo(data)) {
        fiado += (f['valor'] ?? 0);
      }
    }

    setState(() {
      valorDinheiro = dinheiro;
      valorPix = pix;
      valorFiado = fiado;
    });
  }

  bool _estaNoPeriodo(DateTime data) {
    if (_periodoSelecionado == null) return true;
    return data.isAfter(_periodoSelecionado!.start.subtract(const Duration(days: 1))) &&
        data.isBefore(_periodoSelecionado!.end.add(const Duration(days: 1)));
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final novoPeriodo = await showDateRangePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _periodoSelecionado ??
          DateTimeRange(
            start: DateTime(agora.year, agora.month, 1),
            end: agora,
          ),
    );

    if (novoPeriodo != null) {
      setState(() => _periodoSelecionado = novoPeriodo);
      await _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = valorDinheiro + valorPix + valorFiado;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seletor de período
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: _selecionarPeriodo,
              ),
              const SizedBox(width: 8),
              const Text(
                'Selecione o Período',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_periodoSelecionado != null)
            Center(
              child: Text(
                'Período: ${DateFormat('dd/MM/yyyy').format(_periodoSelecionado!.start)} '
                'até ${DateFormat('dd/MM/yyyy').format(_periodoSelecionado!.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recebido Dinheiro: ${formato.format(valorDinheiro)}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF1976D2))),
                  Text('Recebido PIX: ${formato.format(valorPix)}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF64B5F6))),
                  Text('Valor pendente (Fiado): ${formato.format(valorFiado)}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F))),
                  const Divider(height: 24),
                  Text('Total (recebidos e pendentes): ${formato.format(total)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: _buildGraficoPizza(),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPizza() {
    final total = valorDinheiro + valorPix + valorFiado;
    if (total == 0) {
      return const Center(child: Text('Sem dados suficientes para gerar o gráfico.'));
    }

    final percentualDinheiro = (valorDinheiro / total) * 100;
    final percentualPix = (valorPix / total) * 100;
    final percentualFiado = (valorFiado / total) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF1976D2),
                  value: valorDinheiro,
                  title: '${percentualDinheiro.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: const Color(0xFF64B5F6),
                  value: valorPix,
                  title: '${percentualPix.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: const Color(0xFFD32F2F),
                  value: valorFiado,
                  title: '${percentualFiado.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendaItem(const Color(0xFF1976D2), 'Dinheiro: ${percentualDinheiro.toStringAsFixed(1)}%'),
            _legendaItem(const Color(0xFF64B5F6), 'PIX: ${percentualPix.toStringAsFixed(1)}%'),
            _legendaItem(const Color(0xFFD32F2F), 'Fiado: ${percentualFiado.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Widget _legendaItem(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: cor),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
