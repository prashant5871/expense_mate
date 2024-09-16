import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart'; // Import the random_color package

class ReportsStatisticsPage extends StatefulWidget {
  @override
  _ReportsStatisticsPageState createState() => _ReportsStatisticsPageState();
}

class _ReportsStatisticsPageState extends State<ReportsStatisticsPage> {
  String _selectedFilter = 'Monthly';
  int? _touchedBarIndex;
  Map<String, double> _spendingByCategory = {};
  Map<String, Color> _categoryColors = {}; // To store unique colors for each category

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilter) {
      case 'Weekly':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Yearly':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(Duration(days: 30)); // Default to a month if filter is unknown
    }

    final transactionCollection = FirebaseFirestore.instance.collection('transactions');
    final querySnapshot = await transactionCollection
        .where('date', isGreaterThanOrEqualTo: startDate)
        .get();

    final categoryExpenses = <String, double>{};
    final RandomColor _randomColor = RandomColor(); // Create an instance of RandomColor

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      if (category != null) {
        categoryExpenses.update(category, (existingValue) => existingValue + amount, ifAbsent: () => amount);
        // Assign a unique random color to each category
        _categoryColors.putIfAbsent(category, () => _generateColor());
      }
    }

    setState(() {
      _spendingByCategory = categoryExpenses;
    });
  }

  Color _generateColor() {
    final randomColor = RandomColor();
    Color color;
    do {
      color = randomColor.randomColor();
    } while (!_isColorValid(color));
    return color;
  }

  bool _isColorValid(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = hsl.lightness;
    return lightness > 0.2 && lightness < 0.5; // Filter out too dark or too light colors
  }

  List<PieChartSectionData> _generatePieChartSections() {
    return _spendingByCategory.entries.map((entry) {
      final index = _spendingByCategory.keys.toList().indexOf(entry.key);
      final isSelected = index == _touchedBarIndex;
      return PieChartSectionData(
        color: _categoryColors[entry.key] ?? Colors.grey, // Use the color from the map
        value: entry.value,
        title: '',
        radius: isSelected ? 60 : 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isSelected ? _buildBadge(entry.key, entry.value) : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _buildBadge(String category, double value) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '$category\n\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarChartData() {
    return _spendingByCategory.entries.map((entry) {
      final index = _spendingByCategory.keys.toList().indexOf(entry.key);
      final isTouched = index == _touchedBarIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _categoryColors[entry.key] ?? Colors.grey, // Use the color from the map
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _spendingByCategory.values.reduce((a, b) => a > b ? a : b),
              color: Colors.grey[300],
            ),
            rodStackItems: isTouched
                ? [
              BarChartRodStackItem(0, entry.value, _categoryColors[entry.key] ?? Colors.grey),
            ]
                : [],
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    }).toList();
  }

  void _onPieChartTouch(FlTouchEvent event, PieTouchResponse? touchResponse) {
    setState(() {
      if (touchResponse != null && event is FlTapUpEvent) {
        _touchedBarIndex = touchResponse.touchedSection?.touchedSectionIndex;
      } else {
        _touchedBarIndex = -1;
      }
    });
  }

  void _onBarChartTouch(FlTouchEvent event, BarTouchResponse? touchResponse) {
    setState(() {
      if (touchResponse != null && event is FlTapUpEvent) {
        _touchedBarIndex = touchResponse.spot?.touchedBarGroupIndex;
      } else {
        _touchedBarIndex = -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedFilter,
              items: ['Weekly', 'Monthly', 'Yearly'].map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _fetchData(); // Fetch data again when the filter changes
                });
              },
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: _generatePieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    touchCallback: _onPieChartTouch,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: _spendingByCategory.length * 60.0, // Adjust width based on the number of categories
                  child: BarChart(
                    BarChartData(
                      barGroups: _generateBarChartData(),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      alignment: BarChartAlignment.spaceAround,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hides the vertical axis titles
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hides the horizontal axis titles
                      ),
                      barTouchData: BarTouchData(
                        touchCallback: _onBarChartTouch,
                        handleBuiltInTouches: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
