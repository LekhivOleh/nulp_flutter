import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _colorController = TextEditingController();
  Color _squareColor = Colors.black;
  final List<String> _colorHistory = [];

  void _updateColor(String value) {
    if (value.isEmpty) return;
    
    try {
      final Color? color = _parseColor(value.trim());
      if (color != null) {
        setState(() {
          _squareColor = color;
          
          _colorHistory.insert(0, value.trim());
          if (_colorHistory.length > 5) {
            _colorHistory.removeLast();
          }
        });
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      _colorController.clear();
    }
  }

  Color? _parseColor(String input) {
    final colorString = input.toUpperCase();
    
    final colorMap = {
      'RED': Colors.red,
      'BLUE': Colors.blue,
      'GREEN': Colors.green,
      'YELLOW': Colors.yellow,
    };
    
    return colorMap[colorString];
  }

  void _showErrorDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Color'),
        content: 
          const Text('Not a valid color.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter color (red, blue, green, yellow)',
                      ),
                      onSubmitted: _updateColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _updateColor(_colorController.text),
                    child: const Text('Change Color')
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 150,
                height: 150,
                color: _squareColor,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                      children: [
                        const Text('Color History'),
                        ..._colorHistory.indexed.map((item) {
                          return GestureDetector(
                            onTap: () => _updateColor(item.$2),
                            child: ColoredBox(
                              color: _parseColor(item.$2) ?? Colors.transparent,
                              child: Text(item.$2),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
