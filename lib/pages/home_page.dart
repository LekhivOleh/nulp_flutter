import 'package:flutter/material.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/widgets/log_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _logService = AppDependencies.instance.logService;
  final _authService = AppDependencies.instance.authService;
  List<AccessLog> _logs = <AccessLog>[];
  bool _isLoading = true;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getCurrentUser();
    final logs = await _logService.getLogs();

    if (!mounted) {
      return;
    }

    setState(() {
      _userEmail = user?.email ?? 'unknown';
      _logs = logs;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _persistAndRefresh(List<AccessLog> next) async {
    await _logService.saveLogs(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _logs = next;
    });
  }

  Future<void> _showLogDialog({int? index}) async {
    final existing = index == null ? null : _logs[index];
    final nameController = TextEditingController(text: existing?.name ?? '');
    final timeController = TextEditingController(
      text: _formatDate(existing?.timestamp ?? DateTime.now()),
    );
    var direction = existing?.direction ?? 'In';
    final formKey = GlobalKey<FormState>();

    final nextItem = await showDialog<AccessLog>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            scrollable: true,
            title: Text(index == null ? 'Add log' : 'Edit log'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return 'Name is required';
                        }
                        if (RegExp(r'\d').hasMatch(name)) {
                          return 'Name must not contain digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: direction,
                      items: const [
                        DropdownMenuItem(value: 'In', child: Text('In')),
                        DropdownMenuItem(value: 'Out', child: Text('Out')),
                      ],
                      decoration: const InputDecoration(labelText: 'Direction'),
                      onChanged: (value) {
                        setModalState(() {
                          direction = value ?? 'In';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Timestamp'),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: existing?.timestamp ?? DateTime.now(),
                        );

                        if (pickedDate == null) {
                          return;
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(
                            existing?.timestamp ?? DateTime.now(),
                          ),
                        );

                        if (pickedTime == null) {
                          return;
                        }

                        final merged = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        timeController.text = _formatDate(merged);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) {
                    return;
                  }

                  final parsed =
                      DateTime.tryParse(
                        timeController.text.replaceFirst(' ', 'T'),
                      ) ??
                      DateTime.now();

                  final nextItem = AccessLog(
                    uid:
                        existing?.uid ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    direction: direction,
                    timestamp: parsed,
                  );

                  Navigator.pop(dialogContext, nextItem);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (nextItem == null) {
      nameController.dispose();
      timeController.dispose();
      return;
    }

    final next = <AccessLog>[..._logs];
    if (index == null) {
      next.add(nextItem);
    } else {
      next[index] = nextItem;
    }

    await _persistAndRefresh(next);

    nameController.dispose();
    timeController.dispose();
  }

  Future<void> _deleteLog(int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete log'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final next = <AccessLog>[..._logs]..removeAt(index);
    await _persistAndRefresh(next);
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, ProfilePage.routeName),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogDialog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 12),
                  Text('Logged in as: $_userEmail'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.94,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: _logs.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No logs yet. Add your first item.',
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    return Dismissible(
                                      key: ValueKey(_logs[index].uid),
                                      direction: DismissDirection.endToStart,
                                      background: const ColoredBox(
                                        color: Colors.redAccent,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        await _deleteLog(index);
                                        return false;
                                      },
                                      child: InkWell(
                                        onTap: () =>
                                            _showLogDialog(index: index),
                                        child: LogCard(log: _logs[index]),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }
}
