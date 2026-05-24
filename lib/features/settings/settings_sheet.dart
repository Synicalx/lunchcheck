import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/storage/models/settings_model.dart';
import '../data_portability/portability_helper.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _spendController;
  late List<int> _selectedDays;
  late TimeOfDay _notificationTime;

  final List<String> _weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    _spendController = TextEditingController(
      text: provider.settings.targetSpend.toStringAsFixed(2),
    );
    _selectedDays = List<int>.from(provider.settings.activeDays);
    _notificationTime = TimeOfDay(
      hour: provider.settings.notificationHour,
      minute: provider.settings.notificationMinute,
    );
  }

  @override
  void dispose() {
    _spendController.dispose();
    super.dispose();
  }

  void _toggleDay(int index) {
    final dayNum = index + 1;
    setState(() {
      if (_selectedDays.contains(dayNum)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(dayNum);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one active day.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        _selectedDays.add(dayNum);
      }
      _selectedDays.sort();
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    final spendText = _spendController.text.trim();
    final double? parsedSpend = double.tryParse(spendText);
    if (parsedSpend == null || parsedSpend <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target spend greater than 0.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newSettings = AppSettings(
      targetSpend: parsedSpend,
      activeDays: _selectedDays,
      notificationHour: _notificationTime.hour,
      notificationMinute: _notificationTime.minute,
      isOnboarded: true, // Persist onboarded state
    );

    await Provider.of<AppStateProvider>(context, listen: false)
        .updateSettings(newSettings);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    try {
      await PortabilityHelper.exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs exported successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    try {
      final importedLogs = await PortabilityHelper.importData();
      if (importedLogs != null && importedLogs.isNotEmpty) {
        if (mounted) {
          final provider = Provider.of<AppStateProvider>(context, listen: false);
          await provider.importLogs(importedLogs);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${importedLogs.length} logs.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Application?'),
        content: const Text(
          'This will permanently delete all logged spends and reset settings to default. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      await provider.clearDatabase();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application has been reset.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings & Portability',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Colors.white10),

              // Spend input
              Text(
                'Target Daily Spend (\$)',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _spendController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 20),

              // Active days
              Text(
                'Active Tracking Days',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_weekDays[index]),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    onSelected: (_) => _toggleDay(index),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Notification time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminder Time',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'When we prompt you to log lunch.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _notificationTime.format(context),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40, thickness: 1, color: Colors.white10),

              // Data Import/Export Actions
              Text(
                'Data Portability',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).applyTo(
                      OutlinedButton(
                        onPressed: _handleExport,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ios_share_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Export JSON'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).applyTo(
                      OutlinedButton(
                        onPressed: _handleImport,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_open_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Import JSON'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save & Reset Buttons
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _handleReset,
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Reset App Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to wrap OutlinedButton styling since Material 3 can be verbose
extension on ButtonStyle {
  Widget applyTo(OutlinedButton button) {
    return OutlinedButton(
      onPressed: button.onPressed,
      style: this,
      child: button.child!,
    );
  }
}
