// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Баллистический калькулятор';

  @override
  String get history => 'Архив расчетов';

  @override
  String get kineticEnergy => 'Кинетическая энергия выстрела';

  @override
  String get waitingInput => 'Ожидание ввода...';

  @override
  String get pneumatics => 'Пневматика (< 10 Дж)';

  @override
  String get smallCaliber => 'Малый калибр (.22 LR)';

  @override
  String get pistol => 'Пистолет (9x19, .45 ACP)';

  @override
  String get intermediate => 'Промежуточный (5.56, 7.62x39)';

  @override
  String get rifle => 'Винтовочный (.308, .30-06)';

  @override
  String get magnum => 'Магнум / Крупный (.338 LM, .50 BMG)';

  @override
  String get bulletMass => 'Масса пули';

  @override
  String get velocity => 'Скорость';

  @override
  String get formula => 'Формула: E = (m · v²) / 2';

  @override
  String get saveToArchive => 'Сохранить в архив';

  @override
  String get archiveEmpty => 'Архив пуст';

  @override
  String get enterDataPrompt => 'Сначала введите данные для расчета';

  @override
  String get savedToArchive => 'Расчет сохранен в архив';

  @override
  String get massLabel => 'Масса';

  @override
  String get velocityLabel => 'Скорость';

  @override
  String get grains => 'гран';

  @override
  String get grams => 'г';
}
