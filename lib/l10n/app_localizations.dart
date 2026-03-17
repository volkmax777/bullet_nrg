import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ballistic Calculator'**
  String get appTitle;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @kineticEnergy.
  ///
  /// In en, this message translates to:
  /// **'Kinetic energy of the shot'**
  String get kineticEnergy;

  /// No description provided for @waitingInput.
  ///
  /// In en, this message translates to:
  /// **'Waiting for input...'**
  String get waitingInput;

  /// No description provided for @pneumatics.
  ///
  /// In en, this message translates to:
  /// **'Airgun (< 10 J)'**
  String get pneumatics;

  /// No description provided for @smallCaliber.
  ///
  /// In en, this message translates to:
  /// **'Small caliber (.22 LR)'**
  String get smallCaliber;

  /// No description provided for @pistol.
  ///
  /// In en, this message translates to:
  /// **'Pistol (9x19, .45 ACP)'**
  String get pistol;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate (5.56, 7.62x39)'**
  String get intermediate;

  /// No description provided for @rifle.
  ///
  /// In en, this message translates to:
  /// **'Rifle (.308, .30-06)'**
  String get rifle;

  /// No description provided for @magnum.
  ///
  /// In en, this message translates to:
  /// **'Magnum / Large (.338 LM, .50 BMG)'**
  String get magnum;

  /// No description provided for @bulletMass.
  ///
  /// In en, this message translates to:
  /// **'Bullet Mass'**
  String get bulletMass;

  /// No description provided for @velocity.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get velocity;

  /// No description provided for @formula.
  ///
  /// In en, this message translates to:
  /// **'Formula: E = (m · v²) / 2'**
  String get formula;

  /// No description provided for @saveToArchive.
  ///
  /// In en, this message translates to:
  /// **'Save to archive'**
  String get saveToArchive;

  /// No description provided for @archiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get archiveEmpty;

  /// No description provided for @enterDataPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter data for calculation first'**
  String get enterDataPrompt;

  /// No description provided for @savedToArchive.
  ///
  /// In en, this message translates to:
  /// **'Calculation saved to archive'**
  String get savedToArchive;

  /// No description provided for @massLabel.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get massLabel;

  /// No description provided for @velocityLabel.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get velocityLabel;

  /// No description provided for @grains.
  ///
  /// In en, this message translates to:
  /// **'gr'**
  String get grains;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get grams;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
