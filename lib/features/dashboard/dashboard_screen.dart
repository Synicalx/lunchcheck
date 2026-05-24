import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/storage/models/lunch_log_model.dart';
import '../../core/notifications/notification_helper.dart';
import '../entry/entry_modal.dart';
import '../settings/settings_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to notification tap events to open input view
    NotificationHelper.openInputModalNotifier.addListener(_onNotificationTap);
  }

  @override
  void dispose() {
    NotificationHelper.openInputModalNotifier.removeListener(_onNotificationTap);
    super.dispose();
  }

  void _onNotificationTap() {
    if (NotificationHelper.openInputModalNotifier.value) {
      NotificationHelper.openInputModalNotifier.value = false;
      _showEntryModal();
    }
  }

  void _showEntryModal({DateTime? date}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EntryModal(initialDate: date),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  Future<bool> _deleteLog(LunchLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log?'),
        content: Text(
          'Are you sure you want to delete the entry for ${DateFormat('MMMM d').format(log.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    final weekMetrics = provider.thisWeekMetrics;
    final averages = provider.rolling30DayAverages;
    final groupedLogs = provider.logsByMonth;

    final double weeklySpent = weekMetrics['spent'] ?? 0.00;
    final double weeklySaved = weekMetrics['saved'] ?? 0.00;
    final double weeklyOverspent = weekMetrics['overspent'] ?? 0.00;

    final double avgBought = averages['averageBought'] ?? 0.00;
    final double avgBrought = averages['averageBrought'] ?? 0.00;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LunchCheck'),
        actions: [
          IconButton(
            onPressed: _showSettingsSheet,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              
              // 1. TOP HERO METRIC
              Card(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).cardTheme.color ?? const Color(0xFF222228),
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'THIS WEEK',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${weeklySpent.toStringAsFixed(2)}',
                        style: textTheme.headlineLarge?.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  const Text('Saved', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${weeklySaved.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  const Text('Overspent', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${weeklyOverspent.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. MID HISTORY SECTION
              Expanded(
                child: groupedLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No spends logged yet.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the button below to add your first log.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedLogs.keys.length,
                        itemBuilder: (context, monthIndex) {
                          final monthName = groupedLogs.keys.elementAt(monthIndex);
                          final monthLogs = groupedLogs[monthName]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 8.0),
                                child: Text(
                                  monthName.toUpperCase(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: monthLogs.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, logIndex) {
                                  final log = monthLogs[logIndex];
                                  final isSaved = log.actualSpend <= log.targetSpend;
                                  final dayOfWeek = DateFormat('EEE').format(log.date);
                                  final dayNum = DateFormat('d').format(log.date);

                                  return Dismissible(
                                    key: Key(log.storageKey),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20.0),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    ),
                                    onDismissed: (_) async {
                                      await provider.deleteLog(log.storageKey);
                                    },
                                    confirmDismiss: (_) => _deleteLog(log),
                                    child: InkWell(
                                      onTap: () => _showEntryModal(date: log.date),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardTheme.color,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.04),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Date Badge
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    dayOfWeek.toUpperCase(),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
                                                  ),
                                                  Text(
                                                    dayNum,
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  log.wasBrought
                                                      ? const Row(
                                                          children: [
                                                            Icon(Icons.backpack_rounded, size: 14, color: Color(0xFF10B981)),
                                                            SizedBox(width: 4),
                                                            Text('Brought Lunch', style: TextStyle(fontWeight: FontWeight.w600)),
                                                          ],
                                                        )
                                                      : const Text('Bought Lunch', style: TextStyle(fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Target: \$${log.targetSpend.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Actual spent with indicator
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${log.actualSpend.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (isSaved ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isSaved ? 'SAVED' : 'OVER',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w900,
                                                      color: isSaved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 12),

              // 3. BOTTOM SECTION: 30-DAY COMPARISON
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rolling 30-Day Averages',
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const Icon(Icons.analytics_outlined, size: 18, color: Colors.white38),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Average Bought: \$${avgBought.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Average Brought: \$${avgBrought.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryModal(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
