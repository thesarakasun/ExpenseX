import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class InsightsScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const InsightsScreen({super.key, required this.databaseService});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _touchedIndex = -1; // For Pie Chart interaction

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<Transaction>>(
        stream: widget.databaseService.streamRecentTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final transactions = snapshot.data!;
          if (transactions.isEmpty) {
             return const Center(child: Text("No data to analyze yet."));
          }

          // --- DATA PROCESSING ---
          final now = DateTime.now();
          final thisMonthTx = transactions.where((tx) {
            return tx.date.month == now.month && tx.date.year == now.year;
          }).toList();

          double totalIncome = 0;
          double totalExpense = 0;
          final Map<String, double> categoryTotals = {};
          final Map<int, double> dailySpending = {};

          for (var tx in thisMonthTx) {
            if (tx.type == 0) {
              totalIncome += tx.amount;
            } else if (tx.type == 1) {
              totalExpense += tx.amount;
              final catName = tx.categoryName ?? "Other";
              categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount;

              // Daily totals for Line Chart
              final day = tx.date.day;
              dailySpending[day] = (dailySpending[day] ?? 0) + tx.amount;
            }
          }

          // Prepare Line Chart Data
          List<FlSpot> spots = dailySpending.entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList();
          spots.sort((a, b) => a.x.compareTo(b.x));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1. STAT CARDS ROW
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Income", totalIncome, Colors.green, Icons.arrow_downward)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Expense", totalExpense, Colors.red, Icons.arrow_upward)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard("Net Savings", totalIncome - totalExpense, (totalIncome - totalExpense) >= 0 ? Colors.blue : Colors.orange, Icons.account_balance_wallet),

                const SizedBox(height: 30),

                // 2. BAR CHART (Monthly Overview)
                const Text("Monthly Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text("Income", style: TextStyle(fontWeight: FontWeight.bold));
                              if (value == 1) return const Text("Expense", style: TextStyle(fontWeight: FontWeight.bold));
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: totalIncome, color: Colors.green, width: 30, borderRadius: BorderRadius.circular(6))
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: totalExpense, color: Colors.red, width: 30, borderRadius: BorderRadius.circular(6))
                        ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. LINE CHART (Daily Spending Trend)
                const Text("Daily Spending Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("See which days you spent the most", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                
                Container(
                  height: 250,
                  padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: spots.isEmpty 
                    ? const Center(child: Text("No spending data this month"))
                    : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5, 
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blueAccent.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                ),

                const SizedBox(height: 30),

                // 4. PIE CHART (Expense Breakdown)
                if (totalExpense > 0) ...[
                  const Text("Where is your money going?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _generatePieSections(categoryTotals, totalExpense),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: categoryTotals.entries.map((entry) {
                                return _buildLegendItem(entry.key, entry.value, totalExpense);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else 
                   const Center(child: Text("No expenses recorded this month", style: TextStyle(color: Colors.grey))),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPERS ---
  
  Widget _buildStatCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "LKR ${amount.toStringAsFixed(0)}",
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, double> categoryTotals, double total) {
    final List<PieChartSectionData> sections = [];
    int index = 0;
    
    categoryTotals.forEach((category, amount) {
      final isTouched = index == _touchedIndex;
      final double radius = isTouched ? 60.0 : 50.0;
      final double percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: _getColor(category),
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      index++;
    });
    return sections;
  }

  Widget _buildLegendItem(String category, double amount, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: _getColor(category))),
          const SizedBox(width: 10),
          Text(category, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text("LKR ${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case "Food": return Colors.orange;
      case "Transport": return Colors.blue;
      case "Bills": return Colors.red;
      case "Shopping": return Colors.purple;
      case "Health": return Colors.green;
      case "Salary": return Colors.greenAccent;
      default: return Colors.grey;
    }
  }
}