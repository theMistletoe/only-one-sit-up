/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 28 (14 per locale)
///
/// Built on 2024-01-05 at 07:26 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	ja(languageCode: 'ja', build: _StringsJa.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	String get start_message => 'Let\'s do "just ONE" sit-up!';
	String get situp_count => 'Sit-up Count';
	String get complete_message => 'You did it!';
	String get situp_count_days => 'Total Continuous Days';
	String get situp_count_total => 'Total Sit-ups Count';
	String get situp_count_unit => 'sit-ups';
	String get tutorial_title => 'How to use';
	String get tutorial_message1 => 'Just once a day, do sit-ups with your phone on your chest!';
	String get tutorial_message2 => 'It\'s only once a day, so you can definitely keep up!';
	String get close => 'Close';
	String get warning_title => '※Warning';
	String get warning_message => 'Upon import, all previously recorded data will be deleted and overwritten by the data being imported. Are you sure?';
	String get yes => 'Yes';
	String get no => 'No';
}

// Path: <root>
class _StringsJa implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsJa.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsJa _root = this; // ignore: unused_field

	// Translations
	@override String get start_message => '腹筋を"1回だけ"やろう!';
	@override String get situp_count => '腹筋した回数';
	@override String get complete_message => '腹筋してえらい!';
	@override String get situp_count_days => '腹筋した日数';
	@override String get situp_count_total => '腹筋したトータル回数';
	@override String get situp_count_unit => '回';
	@override String get tutorial_title => 'このアプリの使い方';
	@override String get tutorial_message1 => '1日1回だけ、胸にスマホを置いて腹筋しよう!';
	@override String get tutorial_message2 => '1日1回だけだから、絶対に続けられる!';
	@override String get close => '閉じる';
	@override String get warning_title => '※注意';
	@override String get warning_message => 'インポートすると、以前に記録されたデータはすべて削除され、インポートするデータによって上書きされます。よろしいですか？';
	@override String get yes => 'はい';
	@override String get no => 'いいえ';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'start_message': return 'Let\'s do "just ONE" sit-up!';
			case 'situp_count': return 'Sit-up Count';
			case 'complete_message': return 'You did it!';
			case 'situp_count_days': return 'Total Continuous Days';
			case 'situp_count_total': return 'Total Sit-ups Count';
			case 'situp_count_unit': return 'sit-ups';
			case 'tutorial_title': return 'How to use';
			case 'tutorial_message1': return 'Just once a day, do sit-ups with your phone on your chest!';
			case 'tutorial_message2': return 'It\'s only once a day, so you can definitely keep up!';
			case 'close': return 'Close';
			case 'warning_title': return '※Warning';
			case 'warning_message': return 'Upon import, all previously recorded data will be deleted and overwritten by the data being imported. Are you sure?';
			case 'yes': return 'Yes';
			case 'no': return 'No';
			default: return null;
		}
	}
}

extension on _StringsJa {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'start_message': return '腹筋を"1回だけ"やろう!';
			case 'situp_count': return '腹筋した回数';
			case 'complete_message': return '腹筋してえらい!';
			case 'situp_count_days': return '腹筋した日数';
			case 'situp_count_total': return '腹筋したトータル回数';
			case 'situp_count_unit': return '回';
			case 'tutorial_title': return 'このアプリの使い方';
			case 'tutorial_message1': return '1日1回だけ、胸にスマホを置いて腹筋しよう!';
			case 'tutorial_message2': return '1日1回だけだから、絶対に続けられる!';
			case 'close': return '閉じる';
			case 'warning_title': return '※注意';
			case 'warning_message': return 'インポートすると、以前に記録されたデータはすべて削除され、インポートするデータによって上書きされます。よろしいですか？';
			case 'yes': return 'はい';
			case 'no': return 'いいえ';
			default: return null;
		}
	}
}
