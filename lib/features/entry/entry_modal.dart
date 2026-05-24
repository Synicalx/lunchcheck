import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/state/app_state_provider.dart';

class EntryModal extends StatefulWidget {
  final DateTime? initialDate;

  const EntryModal({super.key, this.initialDate});

  @override
  State<EntryModal> createState() => _EntryModalState();
}

class _EntryModalState extends State<EntryModal> {
  final _costController = TextEditingController();
  final _focusNode = FocusNode();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    // Auto focus the input field after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _costController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitSpend(double value, bool wasBrought) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    await provider.logSpend(
      date: _selectedDate,
      actualSpend: value,
      wasBrought: wasBrought,
    );
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onSavePressed() {
    final text = _costController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount or tap Brought Lunch.')),
      );
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive number.')),
      );
      return;
    }
    _submitSpend(parsed, parsed == 0.00);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Lunch Spend',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date picker selector
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, 
                           size: 18, 
                           color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Currency input field
              TextField(
                controller: _costController,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  hintText: '0.00',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _onSavePressed(),
              ),
              const SizedBox(height: 24),

              // Brought Lunch Button (Shortcut)
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _submitSpend(0.00, true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981), // Green text
                    side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backpack_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Brought Lunch (\$0)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSavePressed,
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
