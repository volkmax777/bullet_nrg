import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const NrgCalcApp());
}

// Модель для сохранения в архив с методами сериализации
class CalculationRecord {
  final double mass;
  final bool isMassGrains;
  final double velocity;
  final bool isVelocityFps;
  final double joules;
  final double ftLbf;
  final DateTime timestamp;

  CalculationRecord({
    required this.mass,
    required this.isMassGrains,
    required this.velocity,
    required this.isVelocityFps,
    required this.joules,
    required this.ftLbf,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'mass': mass,
        'isMassGrains': isMassGrains,
        'velocity': velocity,
        'isVelocityFps': isVelocityFps,
        'joules': joules,
        'ftLbf': ftLbf,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CalculationRecord.fromJson(Map<String, dynamic> json) =>
      CalculationRecord(
        mass: json['mass'],
        isMassGrains: json['isMassGrains'],
        velocity: json['velocity'],
        isVelocityFps: json['isVelocityFps'],
        joules: json['joules'],
        ftLbf: json['ftLbf'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class NrgCalcApp extends StatelessWidget {
  const NrgCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange),
          ),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _massController = TextEditingController();
  final TextEditingController _velocityController = TextEditingController();

  double _energyJoules = 0.0;
  double _energyFtLbf = 0.0;

  bool _isMassGrains = false;
  bool _isVelocityFps = false;

  // Архив расчетов
  final List<CalculationRecord> _archive = [];

  @override
  void initState() {
    super.initState();
    _massController.addListener(_calculateEnergy);
    _velocityController.addListener(_calculateEnergy);
    _loadArchiveFromPrefs(); // Загружаем локальную базу
  }

  // ==== РАБОТА С ЛОКАЛЬНОЙ БАЗОЙ ====
  Future<void> _loadArchiveFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? archiveString = prefs.getString('archive_data');
    if (archiveString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(archiveString);
        setState(() {
          _archive.clear();
          _archive.addAll(
            decodedList.map((item) => CalculationRecord.fromJson(item)).toList()
          );
        });
      } catch (e) {
        debugPrint('Ошибка загрузки архива: $e');
      }
    }
  }

  Future<void> _saveArchiveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(
      _archive.map((record) => record.toJson()).toList()
    );
    await prefs.setString('archive_data', encodedList);
  }
  // ==================================

  @override
  void dispose() {
    _massController.dispose();
    _velocityController.dispose();
    super.dispose();
  }

  void _calculateEnergy() {
    final massText = _massController.text.replaceAll(',', '.');
    final velocityText = _velocityController.text.replaceAll(',', '.');

    if (massText.isEmpty || velocityText.isEmpty) {
      setState(() {
        _energyJoules = 0.0;
        _energyFtLbf = 0.0;
      });
      return;
    }

    final massInput = double.tryParse(massText);
    final velocityInput = double.tryParse(velocityText);

    if (massInput == null || velocityInput == null) {
      setState(() {
        _energyJoules = 0.0;
        _energyFtLbf = 0.0;
      });
      return;
    }

    double massGrams = _isMassGrains ? massInput * 0.0647989 : massInput;
    double velocityMs = _isVelocityFps ? velocityInput * 0.3048 : velocityInput;

    double massKg = massGrams / 1000;
    double joules = (massKg * velocityMs * velocityMs) / 2;

    setState(() {
      _energyJoules = joules;
      _energyFtLbf = joules * 0.737562149;
    });
  }

  void _saveToArchive() {
    final massText = _massController.text.replaceAll(',', '.');
    final velocityText = _velocityController.text.replaceAll(',', '.');
    final l10n = AppLocalizations.of(context)!;

    if (massText.isEmpty || velocityText.isEmpty || _energyJoules == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterDataPrompt)),
      );
      return;
    }

    final record = CalculationRecord(
      mass: double.parse(massText),
      isMassGrains: _isMassGrains,
      velocity: double.parse(velocityText),
      isVelocityFps: _isVelocityFps,
      joules: _energyJoules,
      ftLbf: _energyFtLbf,
      timestamp: DateTime.now(),
    );

    setState(() {
      _archive.insert(0, record);
    });
    
    _saveArchiveToPrefs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedToArchive)),
    );
  }

  void _openArchive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArchiveScreen(
          archive: _archive,
          onDelete: (record) {
            setState(() {
              _archive.remove(record);
            });
            _saveArchiveToPrefs(); 
          },
        ),
      ),
    );
  }

  String _getEnergyClass(double joules, AppLocalizations l10n) {
    if (joules == 0) return l10n.waitingInput;
    if (joules < 10) return l10n.pneumatics;
    if (joules < 200) return l10n.smallCaliber;
    if (joules < 800) return l10n.pistol;
    if (joules < 2500) return l10n.intermediate;
    if (joules < 4500) return l10n.rifle;
    return l10n.magnum;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openArchive,
            tooltip: l10n.history,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF242424),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          l10n.kineticEnergy,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_energyJoules.toStringAsFixed(1)} J',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_energyFtLbf.toStringAsFixed(1)} ft-lbf',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getEnergyClass(_energyJoules, l10n),
                            style: const TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _massController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.bulletMass,
                          prefixIcon: const Icon(Icons.scale),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() { _isMassGrains = false; _calculateEnergy(); }),
                              child: Text(
                                'g',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: !_isMassGrains ? FontWeight.bold : FontWeight.normal,
                                  color: !_isMassGrains ? Colors.deepOrange : Colors.grey,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade700),
                            GestureDetector(
                              onTap: () => setState(() { _isMassGrains = true; _calculateEnergy(); }),
                              child: Text(
                                'gr',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _isMassGrains ? FontWeight.bold : FontWeight.normal,
                                  color: _isMassGrains ? Colors.deepOrange : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _velocityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.velocity,
                          prefixIcon: const Icon(Icons.speed),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() { _isVelocityFps = false; _calculateEnergy(); }),
                              child: Text(
                                'm/s',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: !_isVelocityFps ? FontWeight.bold : FontWeight.normal,
                                  color: !_isVelocityFps ? Colors.deepOrange : Colors.grey,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade700),
                            GestureDetector(
                              onTap: () => setState(() { _isVelocityFps = true; _calculateEnergy(); }),
                              child: Text(
                                'fps',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _isVelocityFps ? FontWeight.bold : FontWeight.normal,
                                  color: _isVelocityFps ? Colors.deepOrange : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton.icon(
                  onPressed: _saveToArchive,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.saveToArchive, style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    l10n.formula,
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArchiveScreen extends StatefulWidget {
  final List<CalculationRecord> archive;
  final Function(CalculationRecord) onDelete;

  const ArchiveScreen({
    super.key,
    required this.archive,
    required this.onDelete,
  });

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
      ),
      body: widget.archive.isEmpty
          ? Center(
              child: Text(
                l10n.archiveEmpty,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: widget.archive.length,
              itemBuilder: (context, index) {
                final record = widget.archive[index];
                final massUnit = record.isMassGrains ? l10n.grains : l10n.grams;
                final velUnit = record.isVelocityFps ? 'fps' : 'm/s';

                return Dismissible(
                  key: ValueKey(record.timestamp),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    widget.onDelete(record);
                    setState(() {});
                  },
                  child: Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        '${record.joules.toStringAsFixed(1)} J',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text('${l10n.massLabel}: ${record.mass} $massUnit'),
                          Text('${l10n.velocityLabel}: ${record.velocity} $velUnit'),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(record.timestamp),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () {
                          widget.onDelete(record);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
