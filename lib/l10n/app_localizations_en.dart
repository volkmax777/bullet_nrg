// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ballistic Calculator';

  @override
  String get history => 'History';

  @override
  String get kineticEnergy => 'Kinetic energy of the shot';

  @override
  String get waitingInput => 'Waiting for input...';

  @override
  String get pneumatics => 'Airgun (< 10 J)';

  @override
  String get smallCaliber => 'Small caliber (.22 LR)';

  @override
  String get pistol => 'Pistol (9x19, .45 ACP)';

  @override
  String get intermediate => 'Intermediate (5.56, 7.62x39)';

  @override
  String get rifle => 'Rifle (.308, .30-06)';

  @override
  String get magnum => 'Magnum / Large (.338 LM, .50 BMG)';

  @override
  String get bulletMass => 'Bullet Mass';

  @override
  String get velocity => 'Velocity';

  @override
  String get formula => 'Formula: E = (m · v²) / 2';

  @override
  String get saveToArchive => 'Save to archive';

  @override
  String get archiveEmpty => 'Archive is empty';

  @override
  String get enterDataPrompt => 'Enter data for calculation first';

  @override
  String get savedToArchive => 'Calculation saved to archive';

  @override
  String get massLabel => 'Mass';

  @override
  String get velocityLabel => 'Velocity';

  @override
  String get grains => 'gr';

  @override
  String get grams => 'g';
}
