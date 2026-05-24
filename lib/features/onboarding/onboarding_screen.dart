import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/storage/models/settings_model.dart';
import '../../core/notifications/notification_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _spendController = TextEditingController(text: '10.00');
  final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Default Mon to Fri
  TimeOfDay _notificationTime = const TimeOfDay(hour: 12, minute: 30);

  final List<String> _weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  Future<void> _completeOnboarding() async {
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

    // Request permissions for notifications
    final permissionGranted = await NotificationHelper.requestPermissions();
    if (!permissionGranted) {
      // We will still allow onboarding but warn the user
      debugPrint('Notification permissions denied.');
    }

    final newSettings = AppSettings(
      targetSpend: parsedSpend,
      activeDays: _selectedDays,
      notificationHour: _notificationTime.hour,
      notificationMinute: _notificationTime.minute,
      isOnboarded: true,
    );

    if (mounted) {
      await Provider.of<AppStateProvider>(context, listen: false)
          .updateSettings(newSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LunchCheck',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your minimalist weekday lunch spending tracker.',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Step 1: Target Daily Spend Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Target Daily Spend (\$)',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _spendController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.attach_money_rounded, size: 28),
                          hintText: '0.00',
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Active Days Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Active Tracking Days',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Notification Time Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3. Daily Reminder Time',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We will notify you at this time to log.',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Saving'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
