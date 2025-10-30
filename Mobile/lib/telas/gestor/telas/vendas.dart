import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  String consultor = '';

  final double totalVendas = 328000;
  final double mediaMensal = 55000;
  final double melhorMesValor = 67000;
  final int periodoMeses = 6;
  final double percentualMeta = 1.025; 

  final List<String> meses = const ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
  final List<double> realizado = const [45000, 52000, 47000, 61000, 56000, 69000];
  final List<double> meta = const [48000, 50000, 50000, 52000, 56000, 60000];

  final Color primary = const Color(0xFFDC2C2C);
  final Color primaryLight = const Color(0xFFF06666);

  final Gradient headerBg = const LinearGradient(
    colors: [Color(0xFFF7F9FB), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  String moeda(double v) => 'R\$ ${v ~/ 1000}k';

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: false,
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 0,
            ),

            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: headerBg),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: _HeaderRow(
                  title: 'Dashboard de Vendas',
                  badgeText: '${(percentualMeta * 100).toStringAsFixed(1)}% da meta',
                  showConsultor: consultor.isNotEmpty,
                  consultorText: 'Consultor: $consultor',
                  primary: primary,
                  primaryLight: primaryLight,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 6, 12, safe.bottom + 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CardsGrid(
                      children: [
                        _BigKpiCard(
                          title: 'Total Vendas',
                          value: moeda(totalVendas),
                          icon: Icons.attach_money_rounded,
                          gradient: LinearGradient(
                            colors: [primary, primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        _KpiCard(
                          title: 'Média Mensal',
                          value: moeda(mediaMensal),
                          icon: Icons.track_changes_rounded,
                        ),
                        _KpiCard(
                          title: 'Melhor Mês',
                          value: moeda(melhorMesValor),
                          icon: Icons.emoji_events_outlined,
                        ),
                        _KpiCard(
                          title: 'Período',
                          value: '$periodoMeses meses',
                          icon: Icons.event_note_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _ChartCard(
                      title: 'Evolução de Vendas',
                      subtitle: 'Comparativo entre vendas realizadas e metas mensais',
                      child: _BarrasVendasChart(
                        meses: meses,
                        realizado: realizado,
                        meta: meta,
                        primary: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final String badgeText;
  final bool showConsultor;
  final String consultorText;
  final Color primary;
  final Color primaryLight;

  const _HeaderRow({
    required this.title,
    required this.badgeText,
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
            gradient: LinearGradient(
              colors: [primary, primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        _MetaBadge(
          text: badgeText,
          color: const Color(0xFFDAF5D7),  
          textColor: const Color(0xFF1E7B34), 
        ),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _MetaBadge({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
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
        Positioned(
          top: _iconTop,
          left: _iconLeft,
          child: SizedBox(height: 24, width: 24, child: FittedBox(child: icon)),
        ),
        Positioned(
          top: _titleTop,
          left: _side,
          right: _side,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.labelLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: _side,
          right: _side,
          bottom: _valueBottom,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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

  const _BigKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

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

// ========== CHART ==========
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
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
            ),
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
  final List<double> meta;
  final Color primary;

  const _BarrasVendasChart({
    required this.meses,
    required this.realizado,
    required this.meta,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final barGroups = List.generate(meses.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 10,
        barRods: [
          BarChartRodData(
            toY: realizado[i] / 1000,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(.85)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          BarChartRodData(
            toY: meta[i] / 1000,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade300,
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: 80,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('R\$ ${value.toInt()}k',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.black54)),
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
                  child: Text(meses[i],
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.black87)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: barGroups,
      ),
    );
  }
}
