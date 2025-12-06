import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rent_hive_app/firebase_options.dart';
import 'products_listing.dart';
import 'categories_listing.dart';
import 'admin_orders_screen.dart';
import 'payment_summary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentHive Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          elevation: 8,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Dashboard(toggleTheme: toggleTheme),
    );
  }
}

class Dashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  const Dashboard({super.key, required this.toggleTheme});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  bool isDark = false;
  String selectedTab = 'Weekly'; // To manage tab selection
  int selectedBottomIndex = 0;
  late AnimationController _animationController, _chartAnimationController;

  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCategories = 0;
  double _totalRevenue = 0.0;
  List<double> _chartData = List.filled(7, 0); // Generic chart data
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchRecentActivities();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Fetch general stats only once or less frequently if needed
      if (_totalUsers == 0) {
        final usersSnapshot =
            await FirebaseFirestore.instance.collection('users').count().get();
        _totalUsers = usersSnapshot.count ?? 0;

        final ordersSnapshot =
            await FirebaseFirestore.instance.collection('orders').count().get();
        _totalOrders = ordersSnapshot.count ?? 0;

        final productsSnapshot =
            await FirebaseFirestore.instance
                .collection('products')
                .count()
                .get();
        _totalProducts = productsSnapshot.count ?? 0;

        final categoriesSnapshot =
            await FirebaseFirestore.instance
                .collection('categories')
                .count()
                .get();
        _totalCategories = categoriesSnapshot.count ?? 0;

        final revenueSnapshot =
            await FirebaseFirestore.instance
                .collection('categories')
                .count()
                .get();
        _totalCategories = categoriesSnapshot.count ?? 0;
      }

      // Fetch chart data based on selected tab
      final now = DateTime.now();
      DateTime startDate;
      int daysToFetch;

      switch (selectedTab) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          daysToFetch = 1;
          break;
        case 'Monthly':
          startDate = now.subtract(const Duration(days: 30));
          daysToFetch = 30;
          break;
        case 'Weekly':
        default:
          startDate = now.subtract(const Duration(days: 7));
          daysToFetch = 7;
          break;
      }

      final chartOrdersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('createdAt', isGreaterThanOrEqualTo: startDate)
              .get();

      // Process data for the chart
      if (selectedTab == 'Weekly' || selectedTab == 'Today') {
        final dailyCounts = List.filled(7, 0.0);
        for (var doc in chartOrdersSnapshot.docs) {
          final orderDate = (doc.data()['createdAt'] as Timestamp).toDate();
          final dayIndex = now.difference(orderDate).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            dailyCounts[6 - dayIndex]++;
          }
        }
        _chartData = dailyCounts;
      } else if (selectedTab == 'Monthly') {
        // Example: group by week for monthly view
        final weeklyCounts = List.filled(4, 0.0);
        for (var doc in chartOrdersSnapshot.docs) {
          final orderDate = (doc.data()['createdAt'] as Timestamp).toDate();
          final weekIndex = (now.difference(orderDate).inDays / 7).floor();
          if (weekIndex >= 0 && weekIndex < 4) {
            weeklyCounts[3 - weekIndex]++;
          }
        }
        // For simplicity, we stretch 4 weeks of data over 7 chart bars
        _chartData = [
          weeklyCounts[0],
          weeklyCounts[0],
          weeklyCounts[1],
          weeklyCounts[1],
          weeklyCounts[2],
          weeklyCounts[2],
          weeklyCounts[3],
        ];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
        _chartAnimationController.forward();
      }
    }
  }

  Future<void> _fetchRecentActivities() async {
    if (!mounted) return;

    try {
      // Fetch last 2 products
      final productsSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .orderBy('createdAt', descending: true)
              .limit(2)
              .get();

      // Fetch last 2 categories
      final categoriesSnapshot =
          await FirebaseFirestore.instance
              .collection('categories')
              .orderBy('createdAt', descending: true)
              .limit(2)
              .get();

      List<Map<String, dynamic>> activities = [];

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        activities.add({
          'title': 'New Product: ${data['title']}',
          'time': createdAt,
          'icon': data['imageURL'],
          'color': Colors.orange,
        });
      }

      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        activities.add({
          'title': 'New Category: ${data['name']}',
          'time': createdAt,
          'icon': data['iconURL'],
          'color': Colors.teal,
        });
      }

      // Sort activities by time
      activities.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
      );

      if (mounted) {
        setState(() {
          _recentActivities = activities;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recent activities: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final stats = [
      {
        'icon': Icons.people_outline,
        'label': 'Total Users',
        'value': _totalUsers.toString(),
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFECFDF5),
        'darkBgColor': const Color(0xFF064E3B),
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'hover': false,
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Total Orders',
        'value': _totalOrders.toString(),
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
        'darkBgColor': const Color(0xFF1E3A8A),
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'hover': false,
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Products',
        'value': _totalProducts.toString(),
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFF3F4F6),
        'darkBgColor': const Color(0xFF581C87),
        'gradient': const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'hover': false,
      },
      {
        'icon': Icons.category_outlined,
        'label': 'Total Categories',
        'value': _totalCategories.toString(),
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'darkBgColor': const Color(0xFF92400E),
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'hover': false,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
              : CustomScrollView(
                slivers: [
                  _buildAppBar(isDarkTheme),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsGrid(stats),
                          const SizedBox(height: 25),
                          _buildChartSection(),
                          const SizedBox(height: 20),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: _isLoading ? null : _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar(bool isDarkTheme) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'RentHive',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   return FadeTransition(
  //     opacity: _animationController,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 10,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: TextField(
  //         decoration: InputDecoration(
  //           hintText: 'Search...',
  //           prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
  //           filled: true,
  //           fillColor: Theme.of(context).cardColor,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(16),
  //             borderSide: BorderSide.none,
  //           ),
  //           contentPadding: const EdgeInsets.symmetric(
  //             horizontal: 20,
  //             vertical: 14,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatsGrid(List<Map<String, dynamic>> stats) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final double startInterval = (index * 0.1).clamp(0.0, 0.6);
            final double endInterval = (0.6 + (index * 0.1)).clamp(0.0, 1.0);
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.3 + (index * 0.05)),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    startInterval,
                    endInterval,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: _buildStatCard(stats[index], index),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: InkWell(
              onTap: () => HapticFeedback.lightImpact(),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (stat['gradient'] as LinearGradient).colors.first
                        .withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (stat['gradient'] as LinearGradient).colors.first
                          .withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // border: Border(
                  //   left: BorderSide(color: stat['color'] as Color, width: 4),
                  // ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(stat['icon'], color: stat['color'], size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: stat['gradient'],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (stat['gradient'] as LinearGradient)
                                    .colors
                                    .first
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            stat['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (stat['gradient'] as LinearGradient)
                                .colors
                                .first
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color:
                                  (stat['gradient'] as LinearGradient)
                                      .colors
                                      .first,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          stat['label'],
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            stat['value'].toString(),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Text(
                        stat['value'].toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              (stat['gradient'] as LinearGradient).colors.first,
                          fontSize: 24,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        stat['label'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    return FadeTransition(
      opacity: _chartAnimationController,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildTabButtons(),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (_chartData.isEmpty
                              ? 10
                              : _chartData.reduce((a, b) => a > b ? a : b)) *
                          1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => const Color(0xFF6366F1),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget:
                                (value, meta) => Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                              ];
                              if (selectedTab == 'Monthly') {
                                final weeks = ['W1', 'W2', 'W3', 'W4'];
                                if (value.toInt() < weeks.length) {
                                  return Text(
                                    weeks[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                }
                              } else if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.grey.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  _chartData.length > index
                                      ? _chartData[index] *
                                          _chartAnimationController.value
                                      : 0,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            ['Today', 'Weekly', 'Monthly'].map((label) {
              bool isSelected = selectedTab == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                      foregroundColor:
                          isSelected ? Colors.white : Colors.grey[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedTab = label;
                      });
                      _fetchDashboardData();
                      _chartAnimationController.reset();
                      _chartAnimationController.forward();
                    },
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (_recentActivities.isEmpty)
            Center(
              child: Text(
                'No recent activities.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ..._recentActivities.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> activity = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _recentActivities.length - 1 ? 0 : 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activity['color']! as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          activity['icon'] is String &&
                                  (activity['icon'] as String).startsWith(
                                    'http',
                                  )
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  activity['icon'] as String,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                ),
                              )
                              : Icon(
                                activity['icon'] is IconData
                                    ? activity['icon'] as IconData
                                    : Icons.info,
                                color: activity['color'] as Color,
                                size: 20,
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatTimeAgo(activity['time'] as DateTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedBottomIndex,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
        ],
        onTap: (index) {
          setState(() => selectedBottomIndex = index);
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductsListingScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoriesListingScreen(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminOrdersScreen(),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentSummaryScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}
