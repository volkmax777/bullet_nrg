import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const BulletNrgApp());
}

// Модель для сохранения в архив с методами сериализации
class CalculationRecord {
  final String weaponName;
  final String ammoName;
  final double mass;
  final bool isMassGrains;
  final double velocity;
  final bool isVelocityFps;
  final double joules;
  final double ftLbf;
  final DateTime timestamp;

  CalculationRecord({
    required this.weaponName,
    required this.ammoName,
    required this.mass,
    required this.isMassGrains,
    required this.velocity,
    required this.isVelocityFps,
    required this.joules,
    required this.ftLbf,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'weaponName': weaponName,
    'ammoName': ammoName,
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
        weaponName: json['weaponName'],
        ammoName: json['ammoName'],
        mass: json['mass'],
        isMassGrains: json['isMassGrains'],
        velocity: json['velocity'],
        isVelocityFps: json['isVelocityFps'],
        joules: json['joules'],
        ftLbf: json['ftLbf'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class BulletNrgApp extends StatelessWidget {
  const BulletNrgApp({super.key});

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
      supportedLocales: const [Locale('en'), Locale('ru')],
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
  ArchiveMetadata? _currentArchiveMetadata;

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
            decodedList
                .map((item) => CalculationRecord.fromJson(item))
                .toList(),
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
      _archive.map((record) => record.toJson()).toList(),
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

  Future<void> _saveToArchive() async {
    final massText = _massController.text.replaceAll(',', '.');
    final velocityText = _velocityController.text.replaceAll(',', '.');
    final l10n = AppLocalizations.of(context)!;

    if (massText.isEmpty || velocityText.isEmpty || _energyJoules == 0.0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterDataPrompt)));
      return;
    }

    if (_currentArchiveMetadata == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectArchiveMetadataPrompt)));
      return;
    }

    final record = CalculationRecord(
      weaponName: _currentArchiveMetadata!.weaponName,
      ammoName: _currentArchiveMetadata!.ammoName,
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.savedToArchive)));
  }

  Future<void> _selectArchiveMetadata() async {
    final metadata = await _showArchiveMetadataDialog();
    if (!mounted || metadata == null) {
      return;
    }

    setState(() {
      _currentArchiveMetadata = metadata;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.archiveDetailsSaved),
      ),
    );
  }

  Future<ArchiveMetadata?> _showArchiveMetadataDialog() {
    final l10n = AppLocalizations.of(context)!;
    final weaponController = TextEditingController(
      text: _currentArchiveMetadata?.weaponName ?? '',
    );
    final ammoController = TextEditingController(
      text: _currentArchiveMetadata?.ammoName ?? '',
    );
    String? errorText;

    return showDialog<ArchiveMetadata>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.archiveDetailsTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weaponController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.weaponNameLabel,
                      prefixIcon: const Icon(Icons.sports_martial_arts),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ammoController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      final result = _validateArchiveMetadata(
                        weaponController.text,
                        ammoController.text,
                      );
                      if (result == null) {
                        Navigator.of(dialogContext).pop(
                          ArchiveMetadata(
                            weaponName: weaponController.text.trim(),
                            ammoName: ammoController.text.trim(),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          errorText = result;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l10n.ammoNameLabel,
                      prefixIcon: const Icon(Icons.adjust),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final result = _validateArchiveMetadata(
                      weaponController.text,
                      ammoController.text,
                    );
                    if (result != null) {
                      setDialogState(() {
                        errorText = result;
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      ArchiveMetadata(
                        weaponName: weaponController.text.trim(),
                        ammoName: ammoController.text.trim(),
                      ),
                    );
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateArchiveMetadata(String weaponName, String ammoName) {
    final l10n = AppLocalizations.of(context)!;
    if (weaponName.trim().isEmpty || ammoName.trim().isEmpty) {
      return l10n.archiveMetadataRequired;
    }
    return null;
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.kineticEnergy,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.archiveSessionTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectArchiveMetadata,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(
                                _currentArchiveMetadata == null
                                    ? l10n.setArchiveDetails
                                    : l10n.changeArchiveDetails,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentArchiveMetadata == null
                              ? l10n.archiveSessionNotSelected
                              : '${l10n.weaponNameLabel}: ${_currentArchiveMetadata!.weaponName}\n${l10n.ammoNameLabel}: ${_currentArchiveMetadata!.ammoName}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            height: 1.4,
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                              onTap: () => setState(() {
                                _isMassGrains = false;
                                _calculateEnergy();
                              }),
                              child: Text(
                                'g',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: !_isMassGrains
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: !_isMassGrains
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade700,
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _isMassGrains = true;
                                _calculateEnergy();
                              }),
                              child: Text(
                                'gr',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _isMassGrains
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isMassGrains
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                              onTap: () => setState(() {
                                _isVelocityFps = false;
                                _calculateEnergy();
                              }),
                              child: Text(
                                'm/s',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: !_isVelocityFps
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: !_isVelocityFps
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade700,
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _isVelocityFps = true;
                                _calculateEnergy();
                              }),
                              child: Text(
                                'fps',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _isVelocityFps
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isVelocityFps
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: _saveToArchive,
                  icon: const Icon(Icons.save),
                  label: Text(
                    l10n.saveToArchive,
                    style: const TextStyle(fontSize: 16),
                  ),
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
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
  static const String _allFilterValue = '__all__';

  String _weaponFilter = _allFilterValue;
  String _ammoFilter = _allFilterValue;

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  List<String> _buildFilterValues(Iterable<String> values) {
    final uniqueValues =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return <String>[_allFilterValue, ...uniqueValues];
  }

  List<CalculationRecord> _filteredArchive() {
    return widget.archive.where((record) {
      final matchesWeapon =
          _weaponFilter == _allFilterValue ||
          record.weaponName == _weaponFilter;
      final matchesAmmo =
          _ammoFilter == _allFilterValue || record.ammoName == _ammoFilter;
      return matchesWeapon && matchesAmmo;
    }).toList();
  }

  Future<void> _copyFilteredArchive() async {
    final l10n = AppLocalizations.of(context)!;
    final rows = _filteredArchive();
    if (rows.isEmpty) {
      return;
    }

    final buffer = StringBuffer()
      ..writeln(
        [
          l10n.dateLabel,
          l10n.weaponNameLabel,
          l10n.ammoNameLabel,
          l10n.massLabel,
          l10n.velocityLabel,
          l10n.energyLabel,
        ].map(_escapeCsvField).join(','),
      );

    for (final record in rows) {
      final massUnit = record.isMassGrains ? l10n.grains : l10n.grams;
      final velocityUnit = record.isVelocityFps ? 'fps' : 'm/s';
      buffer.writeln(
        [
          _formatDate(record.timestamp),
          record.weaponName,
          record.ammoName,
          '${record.mass} $massUnit',
          '${record.velocity} $velocityUnit',
          '${record.joules.toStringAsFixed(1)} J',
        ].map(_escapeCsvField).join(','),
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.archiveCopied)));
  }

  String _escapeCsvField(String value) {
    final escapedValue = value.replaceAll('"', '""');
    return '"$escapedValue"';
  }

  Widget _buildFilterField({
    required String value,
    required String label,
    required List<String> options,
    required String allLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option == _allFilterValue ? allLabel : option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRecordDetailsRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade200, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileArchiveList(
    BuildContext context,
    List<CalculationRecord> filteredArchive,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filteredArchive.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = filteredArchive[index];
        final massUnit = record.isMassGrains ? l10n.grains : l10n.grams;
        final velocityUnit = record.isVelocityFps ? 'fps' : 'm/s';

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${record.joules.toStringAsFixed(1)} J',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(record.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      tooltip: l10n.deleteRecord,
                      onPressed: () {
                        widget.onDelete(record);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildRecordDetailsRow(
                  context,
                  label: l10n.weaponNameLabel,
                  value: record.weaponName,
                ),
                _buildRecordDetailsRow(
                  context,
                  label: l10n.ammoNameLabel,
                  value: record.ammoName,
                ),
                _buildRecordDetailsRow(
                  context,
                  label: l10n.massLabel,
                  value: '${record.mass} $massUnit',
                ),
                _buildRecordDetailsRow(
                  context,
                  label: l10n.velocityLabel,
                  value: '${record.velocity} $velocityUnit',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weaponOptions = _buildFilterValues(
      widget.archive.map((record) => record.weaponName),
    );
    final ammoOptions = _buildFilterValues(
      widget.archive.map((record) => record.ammoName),
    );
    if (!weaponOptions.contains(_weaponFilter)) {
      _weaponFilter = _allFilterValue;
    }
    if (!ammoOptions.contains(_ammoFilter)) {
      _ammoFilter = _allFilterValue;
    }
    final filteredArchive = _filteredArchive();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          IconButton(
            onPressed: filteredArchive.isEmpty ? null : _copyFilteredArchive,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: l10n.copyArchive,
          ),
        ],
      ),
      body: widget.archive.isEmpty
          ? Center(
              child: Text(
                l10n.archiveEmpty,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 560;
                      if (isCompact) {
                        return Column(
                          children: [
                            _buildFilterField(
                              value: _weaponFilter,
                              label: l10n.weaponNameLabel,
                              options: weaponOptions,
                              allLabel: l10n.allWeapons,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _weaponFilter = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildFilterField(
                              value: _ammoFilter,
                              label: l10n.ammoNameLabel,
                              options: ammoOptions,
                              allLabel: l10n.allAmmo,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _ammoFilter = value;
                                });
                              },
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildFilterField(
                              value: _weaponFilter,
                              label: l10n.weaponNameLabel,
                              options: weaponOptions,
                              allLabel: l10n.allWeapons,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _weaponFilter = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterField(
                              value: _ammoFilter,
                              label: l10n.ammoNameLabel,
                              options: ammoOptions,
                              allLabel: l10n.allAmmo,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _ammoFilter = value;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filteredArchive.isEmpty
                      ? Center(
                          child: Text(
                            l10n.archiveFilterEmpty,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 720;
                            if (isCompact) {
                              return _buildMobileArchiveList(
                                context,
                                filteredArchive,
                              );
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text(l10n.dateLabel)),
                                    DataColumn(
                                      label: Text(l10n.weaponNameLabel),
                                    ),
                                    DataColumn(label: Text(l10n.ammoNameLabel)),
                                    DataColumn(label: Text(l10n.massLabel)),
                                    DataColumn(label: Text(l10n.velocityLabel)),
                                    DataColumn(label: Text(l10n.energyLabel)),
                                    const DataColumn(label: SizedBox.shrink()),
                                  ],
                                  rows: filteredArchive.map((record) {
                                    final massUnit = record.isMassGrains
                                        ? l10n.grains
                                        : l10n.grams;
                                    final velocityUnit = record.isVelocityFps
                                        ? 'fps'
                                        : 'm/s';
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(_formatDate(record.timestamp)),
                                        ),
                                        DataCell(Text(record.weaponName)),
                                        DataCell(Text(record.ammoName)),
                                        DataCell(
                                          Text('${record.mass} $massUnit'),
                                        ),
                                        DataCell(
                                          Text(
                                            '${record.velocity} $velocityUnit',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${record.joules.toStringAsFixed(1)} J',
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.grey,
                                            ),
                                            tooltip: l10n.deleteRecord,
                                            onPressed: () {
                                              widget.onDelete(record);
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ArchiveMetadata {
  final String weaponName;
  final String ammoName;

  const ArchiveMetadata({required this.weaponName, required this.ammoName});
}
