import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/measurement.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final measurements = provider.measurements;
    final totalRevenue = provider.totalRevenue;
    final totalPaid = provider.totalCollected;
    final outstanding = provider.outstandingBalance;
    final pendingDeliveries = provider.activeOrdersCount;

    // Collection rate percentage
    final double collectionRate = totalRevenue > 0 ? (totalPaid / totalRevenue) : 0.0;
    final String collectionRateStr = '${(collectionRate * 100).toStringAsFixed(0)}%';

    // Clothing type breakdown
    final Map<ClothingType, int> typeCounts = {};
    for (var m in measurements) {
      typeCounts[m.type] = (typeCounts[m.type] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Luxury Header Section
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF080C14), const Color(0xFF101726)]
                        : [const Color(0xFFFAF9F6), const Color(0xFFF0EDE4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'ATELIER ANALYTICS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : theme.primaryColor,
                ),
              ),
            ),
          ),

          // Main Stats Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Collection Rate Premium Indicator Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101726) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: collectionRate,
                              strokeWidth: 8,
                              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                              color: const Color(0xFFC5A880),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            collectionRateStr,
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COLLECTION RATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Atelier Liquidity Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have collected $collectionRateStr of your boutique revenue.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Revenue Details Box
                Text(
                  'FINANCIAL SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  context,
                  [
                    _buildStatRow(context, 'Total Expected', provider.formatPrice(totalRevenue), const Color(0xFFC5A880)),
                    const Divider(height: 24),
                    _buildStatRow(context, 'Collected Revenue', provider.formatPrice(totalPaid), Colors.green.shade400),
                    const Divider(height: 24),
                    _buildStatRow(context, 'Outstanding Balances', provider.formatPrice(outstanding), Colors.red.shade400),
                  ],
                ),
                const SizedBox(height: 28),

                // Order Counts Summary
                Text(
                  'ORDER COUNTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  context,
                  [
                    _buildStatRow(context, 'Registered Orders', '${measurements.length} garments', isDark ? Colors.white : theme.primaryColor),
                    const Divider(height: 24),
                    _buildStatRow(context, 'Active/Pending Fabrication', '$pendingDeliveries in progress', Colors.amber.shade500),
                  ],
                ),
                const SizedBox(height: 32),

                // Category Breakdowns
                Text(
                  'MOST POPULAR GARMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                  ),
                ),
                const SizedBox(height: 12),
                
                if (typeCounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No garment orders recorded yet.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                else
                  ...typeCounts.entries.map((e) => _buildTypeProgressTile(
                        context,
                        e.key.name.toUpperCase(), 
                        e.value, 
                        measurements.length,
                        isDark,
                      )),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101726) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
          width: 1.2,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w900, 
            color: valueColor,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildTypeProgressTile(BuildContext context, String name, int count, int total, bool isDark) {
    final percent = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101726) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
              ),
              Text(
                '$count orders (${(percent * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              color: const Color(0xFFC5A880),
            ),
          ),
        ],
      ),
    );
  }
}
