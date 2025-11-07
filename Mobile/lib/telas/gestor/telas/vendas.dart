import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../components/editar_periodo.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});
  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // anima só na primeira visita após abrir app
  static bool _jaAnimouUmaVezGlobal = false;

  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _chan;

  // KPIs finais
  double totalVendas = 0;
  double mediaMensal = 0;
  double melhorMesValor = 0;
  int periodoMeses = 6;

  // KPIs animados
  double animTotal = 0;
  double animMedia = 0;
  double animMelhor = 0;
  double animPeriodo = 0;

  late final AnimationController _kpiCtrl;

  // Série do gráfico
  List<String> meses = [];
  List<double> realizado = [];

  final Color primary = const Color(0xFFDC2C2C);
  final Color primaryLight = const Color(0xFFF06666);

  String moeda(double v) =>
      NumberFormat.simpleCurrency(locale: 'pt_BR').format(v);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _kpiCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
    _inscreverRealtime();
  }

  @override
  void dispose() {
    if (_chan != null) _client.removeChannel(_chan!);
    _kpiCtrl.dispose();
    super.dispose();
  }

  void _inscreverRealtime() {
    try {
      _chan = _client
          .channel('realtime:dash_vendas_finalizadas')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clientes',
            callback: (_) {
              if (mounted) _carregarDados(animarSeNecessario: false);
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _abrirEditarPeriodo() async {
    final novo = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        int sel = periodoMeses;
        return EditarPeriodoSheet(
          selecionado: periodoMeses,
          onSelecionar: (m) {
            sel = m;
            Navigator.pop(ctx, sel);
          },
        );
      },
    );

    if (novo != null && novo != periodoMeses && mounted) {
      setState(() => periodoMeses = novo);
      await _carregarDados(animarSeNecessario: false); // não reanima ao trocar período
    }
  }

  Future<void> _carregarDados({bool animarSeNecessario = true}) async {
    try {
      final uidGestor = _client.auth.currentUser?.id;
      if (uidGestor == null) return;

      // 1) Consultores ativos do time
      final cons = await _client
          .from('consultores')
          .select('uid, data_cadastro')
          .eq('gestor_id', uidGestor)
          .eq('ativo', true);

      final List<String> uids = (cons is List)
          ? cons
              .map((e) => (e['uid'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList()
          : <String>[];

      // Menor data_cadastro
      DateTime? inicioTime;
      if (cons is List && cons.isNotEmpty) {
        for (final e in cons) {
          final dc = e['data_cadastro'];
          final dt = dc == null ? null : DateTime.tryParse(dc.toString());
          if (dt != null) {
            inicioTime = (inicioTime == null || dt.isBefore(inicioTime!)) ? dt : inicioTime;
          }
        }
      }

      // 2) Agregar vendas finalizadas do time
      Map<String, double> somaMes = {};
      DateTime? primeiraVenda;

      if (uids.isNotEmpty) {
        final valores = uids.map((e) => '"$e"').join(',');
        final vendas = await _client
            .from('clientes')
            .select('data_visita, status_negociacao, valor_proposta, consultor_uid_t')
            .filter('status_negociacao', 'in', '("fechado","fechada","venda")')
            .filter('consultor_uid_t', 'in', '($valores)')
            .order('data_visita', ascending: true);

        String fmtKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

        if (vendas is List) {
          for (final row in vendas) {
            final ds = (row['data_visita'] ?? '').toString();
            final d = DateTime.tryParse(ds)?.toLocal();
            if (d == null) continue;

            primeiraVenda ??= DateTime(d.year, d.month, 1);

            final rawValor = row['valor_proposta'];
            final v = switch (rawValor) {
              num n => n.toDouble(),
              String s => double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0,
              _ => 0.0,
            };

            final key = fmtKey(DateTime(d.year, d.month, 1));
            somaMes.update(key, (old) => old + v, ifAbsent: () => v);
          }
        }
      }

      // 3) “Primeira barra”: mínimo entre cadastro e primeira venda
      DateTime? inicioSerie = inicioTime;
      if (inicioSerie == null || (primeiraVenda != null && primeiraVenda!.isBefore(inicioSerie))) {
        inicioSerie = primeiraVenda;
      }

      // Sem base
      if (inicioSerie == null) {
        if (mounted) {
          setState(() {
            meses = [];
            realizado = [];
            totalVendas = 0;
            mediaMensal = 0;
            melhorMesValor = 0;
            periodoMeses = 0;
            animTotal = 0;
            animMedia = 0;
            animMelhor = 0;
            animPeriodo = 0;
          });
        }
        return;
      }

      // 4) Janela FIXA de `periodoMeses` iniciando exatamente na primeira barra
      final abrev = DateFormat('MMM', 'pt_BR');
      String fmtKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

      final DateTime start = DateTime(inicioSerie.year, inicioSerie.month, 1);
      final DateTime end = DateTime(start.year, start.month + (periodoMeses - 1), 1);

      final List<String> ms = [];
      final List<double> rl = [];
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        final key = fmtKey(cursor);
        ms.add(abrev.format(cursor));
        rl.add(somaMes[key] ?? 0.0);
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      // Sanidade: exatamente `periodoMeses`
      while (ms.length < periodoMeses) {
        final next = DateTime(end.year, end.month + (ms.length - (periodoMeses - 1)), 1);
        ms.add(abrev.format(next));
        rl.add(0.0);
      }
      if (ms.length > periodoMeses) {
        ms.removeRange(0, ms.length - periodoMeses);
        rl.removeRange(0, rl.length - periodoMeses);
      }

      // 5) KPIs locais (ou substitua pela view vendas_kpis se preferir)
      if (mounted) {
        setState(() {
          meses = ms;
          realizado = rl;
          totalVendas = rl.fold<double>(0, (a, b) => a + b);
          periodoMeses = rl.length; // igual ao selecionado
          mediaMensal = periodoMeses == 0 ? 0 : totalVendas / periodoMeses;
          melhorMesValor = rl.isEmpty ? 0 : rl.reduce((a, b) => a > b ? a : b);
        });
      }

      // 6) Animação só na primeira visita
      final deveAnimar = animarSeNecessario && !_jaAnimouUmaVezGlobal;
      if (deveAnimar) {
        _rodarAnimacaoKpis();
        _jaAnimouUmaVezGlobal = true;
      } else {
        if (mounted) {
          setState(() {
            animTotal = totalVendas;
            animMedia = mediaMensal;
            animMelhor = melhorMesValor;
            animPeriodo = periodoMeses.toDouble();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          meses = [];
          realizado = [];
          totalVendas = 0;
          mediaMensal = 0;
          melhorMesValor = 0;
          periodoMeses = 0;
          animTotal = 0;
          animMedia = 0;
          animMelhor = 0;
          animPeriodo = 0;
        });
      }
    }
  }

  void _rodarAnimacaoKpis() {
    final tTween = Tween<double>(begin: 0, end: totalVendas);
    final mTween = Tween<double>(begin: 0, end: mediaMensal);
    final bTween = Tween<double>(begin: 0, end: melhorMesValor);
    final pTween = Tween<double>(begin: 0, end: periodoMeses.toDouble());

    _kpiCtrl
      ..reset()
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          final t = Curves.easeOutCubic.transform(_kpiCtrl.value);
          animTotal = tTween.transform(t);
          animMedia = mTween.transform(t);
          animMelhor = bTween.transform(t);
          animPeriodo = pTween.transform(t);
        });
      })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: false,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 0,
            collapsedHeight: 0,
            expandedHeight: 0,
          ),
          // Header com botão Editar Período
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF7F9FB), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HeaderRow(
                      title: 'Dashboard de Vendas',
                      showConsultor: true,
                      primary: primary,
                      primaryLight: primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: const BorderSide(color: Color(0xFFDD3A3A)),
                        foregroundColor: const Color(0xFFDD3A3A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _abrirEditarPeriodo,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                      label: const Text('Editar Período'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CardsGrid(
                    children: [
                      _BigKpiCard(
                        title: 'Total Vendas',
                        value: moeda(animTotal),
                        icon: Icons.attach_money_rounded,
                        gradient: LinearGradient(
                          colors: [primary, primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      _KpiCard(
                        title: 'Média Mensal',
                        value: moeda(animMedia),
                        icon: Icons.track_changes_rounded,
                      ),
                      _KpiCard(
                        title: 'Melhor Mês',
                        value: moeda(animMelhor),
                        icon: Icons.emoji_events_outlined,
                      ),
                      _KpiCard(
                        title: 'Período',
                        value: '${animPeriodo.toStringAsFixed(0)} meses',
                        icon: Icons.event_note_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ChartCard(
                    title: 'Evolução de Vendas',
                    subtitle: 'Somente vendas finalizadas - Meu time',
                    child: _BarrasVendasChart(
                      meses: meses,
                      realizado: realizado,
                      primary: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== UI Auxiliares ====================

class _HeaderRow extends StatelessWidget {
  final String title;
  final bool showConsultor;
  final String consultorText;
  final Color primary;
  final Color primaryLight;

  const _HeaderRow({
    required this.title,
    required this.primary,
    required this.primaryLight,
    this.showConsultor = false,
    this.consultorText = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [primary, primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                  letterSpacing: .1,
                ),
              ),
              if (showConsultor) ...[
                const SizedBox(height: 2),
                Text(
                  consultorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CardsGrid extends StatelessWidget {
  final List<Widget> children;
  const _CardsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 1000;
    final cross = isWide ? 4 : 2;
    final childAspect = isWide ? 1.55 : 1.15;

    return GridView.builder(
      itemCount: children.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspect,
      ),
      itemBuilder: (context, i) => children[i],
    );
  }
}

const double _cardH = 136;
const double _r = 14;
const double _iconTop = 10;
const double _iconLeft = 12;
const double _titleTop = 48;
const double _side = 16;
const double _valueBottom = 16;

class _KpiLayoutFixed extends StatelessWidget {
  final Widget icon;
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _KpiLayoutFixed({
    required this.icon,
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Stack(
      children: [
        Positioned(top: _iconTop, left: _iconLeft, child: SizedBox(height: 24, width: 24, child: FittedBox(child: icon))),
        Positioned(top: _titleTop, left: _side, right: _side, child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.labelLarge?.copyWith(color: titleColor, fontWeight: FontWeight.w600))),
        Positioned(left: _side, right: _side, bottom: _valueBottom, child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium?.copyWith(color: valueColor, fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(_r),
      child: Container(
        height: _cardH,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_r)),
        child: _KpiLayoutFixed(
          icon: Icon(icon, color: const Color(0xFFDD3A3A), size: 26),
          title: title,
          value: value,
          titleColor: Colors.black54,
          valueColor: const Color(0xFF222222),
        ),
      ),
    );
  }
}

class _BigKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  const _BigKpiCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(_r),
      child: Container(
        height: _cardH,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(_r)),
        child: _KpiLayoutFixed(
          icon: Icon(icon, color: Colors.white, size: 26),
          title: title,
          value: value,
          titleColor: Colors.white70,
          valueColor: Colors.white,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.trending_up, color: Color(0xFFDD3A3A)),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

class _BarrasVendasChart extends StatelessWidget {
  final List<String> meses;
  final List<double> realizado;
  final Color primary;
  const _BarrasVendasChart({required this.meses, required this.realizado, required this.primary});

  @override
  Widget build(BuildContext context) {
    final barGroups = List.generate(meses.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 10,
        barRods: [
          BarChartRodData(
            toY: (realizado[i] / 1000).clamp(0, double.infinity),
            width: 20,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(.85)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    });

    final maxY = [
      ...realizado.map((e) => e / 1000),
      10,
    ].reduce((a, b) => a > b ? a : b) * 1.1;

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('R\$ ${value.toInt()}k', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= meses.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(meses[i], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black87)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: barGroups,
      ),
      swapAnimationDuration: Duration.zero,
      swapAnimationCurve: Curves.linear,
    );
  }
}
