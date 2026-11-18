import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @audioFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la salida de audio.'**
  String get audioFailed;

  /// No description provided for @tabMetronome.
  ///
  /// In es, this message translates to:
  /// **'Metrónomo'**
  String get tabMetronome;

  /// No description provided for @tabSongs.
  ///
  /// In es, this message translates to:
  /// **'Canciones'**
  String get tabSongs;

  /// No description provided for @tabSetlists.
  ///
  /// In es, this message translates to:
  /// **'Setlists'**
  String get tabSetlists;

  /// No description provided for @importExport.
  ///
  /// In es, this message translates to:
  /// **'Importar o exportar'**
  String get importExport;

  /// No description provided for @importSongs.
  ///
  /// In es, this message translates to:
  /// **'Importar canciones'**
  String get importSongs;

  /// No description provided for @exportSongs.
  ///
  /// In es, this message translates to:
  /// **'Exportar canciones'**
  String get exportSongs;

  /// No description provided for @importSetlist.
  ///
  /// In es, this message translates to:
  /// **'Importar setlist'**
  String get importSetlist;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @meter.
  ///
  /// In es, this message translates to:
  /// **'Compás'**
  String get meter;

  /// No description provided for @countIn.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de entrada'**
  String get countIn;

  /// No description provided for @bars.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 compás} other{{count} compases}}'**
  String bars(int count);

  /// No description provided for @inBars.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{en el próximo compás} other{en {count} compases}}'**
  String inBars(int count);

  /// No description provided for @followerNoTempo.
  ///
  /// In es, this message translates to:
  /// **'Como seguidor, el tempo lo pone el líder.'**
  String get followerNoTempo;

  /// No description provided for @deleteQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar \"{name}\"?'**
  String deleteQuestion(String name);

  /// No description provided for @between20and300.
  ///
  /// In es, this message translates to:
  /// **'Entre 20 y 300'**
  String get between20and300;

  /// No description provided for @nameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ponle un nombre'**
  String get nameRequired;

  /// No description provided for @comingUpSection.
  ///
  /// In es, this message translates to:
  /// **'Sigue: {section} {when}'**
  String comingUpSection(String section, String when);

  /// No description provided for @leaderPeers.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Líder · 1 conectado} other{Líder · {count} conectados}}'**
  String leaderPeers(int count);

  /// No description provided for @searchingLeader.
  ///
  /// In es, this message translates to:
  /// **'Buscando líder…'**
  String get searchingLeader;

  /// No description provided for @followingLeader.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo al líder'**
  String get followingLeader;

  /// No description provided for @statusPause.
  ///
  /// In es, this message translates to:
  /// **'Pausa'**
  String get statusPause;

  /// No description provided for @statusSilence.
  ///
  /// In es, this message translates to:
  /// **'Silencio'**
  String get statusSilence;

  /// No description provided for @tempoDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar tempo'**
  String get tempoDown;

  /// No description provided for @tempoUp.
  ///
  /// In es, this message translates to:
  /// **'Subir tempo'**
  String get tempoUp;

  /// No description provided for @tapTempo.
  ///
  /// In es, this message translates to:
  /// **'Tap tempo'**
  String get tapTempo;

  /// No description provided for @stop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get stop;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get start;

  /// No description provided for @noLyrics.
  ///
  /// In es, this message translates to:
  /// **'Esta canción no tiene letra.'**
  String get noLyrics;

  /// No description provided for @lyrics.
  ///
  /// In es, this message translates to:
  /// **'Letra'**
  String get lyrics;

  /// No description provided for @setlistEnds.
  ///
  /// In es, this message translates to:
  /// **'Termina {when}'**
  String setlistEnds(String when);

  /// No description provided for @setlistNextIn.
  ///
  /// In es, this message translates to:
  /// **'Sigue \"{song}\" {when}'**
  String setlistNextIn(String song, String when);

  /// No description provided for @lastSong.
  ///
  /// In es, this message translates to:
  /// **'Última canción'**
  String get lastSong;

  /// No description provided for @nextSong.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: {song}'**
  String nextSong(String song);

  /// No description provided for @previousSongTooltip.
  ///
  /// In es, this message translates to:
  /// **'Canción anterior'**
  String get previousSongTooltip;

  /// No description provided for @nextSongTooltip.
  ///
  /// In es, this message translates to:
  /// **'Canción siguiente'**
  String get nextSongTooltip;

  /// No description provided for @leaveSetlist.
  ///
  /// In es, this message translates to:
  /// **'Salir del setlist'**
  String get leaveSetlist;

  /// No description provided for @panelBand.
  ///
  /// In es, this message translates to:
  /// **'Banda'**
  String get panelBand;

  /// No description provided for @panelPractice.
  ///
  /// In es, this message translates to:
  /// **'Práctica'**
  String get panelPractice;

  /// No description provided for @shareClick.
  ///
  /// In es, this message translates to:
  /// **'Compartir click'**
  String get shareClick;

  /// No description provided for @modeSolo.
  ///
  /// In es, this message translates to:
  /// **'Solo'**
  String get modeSolo;

  /// No description provided for @modeLeader.
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get modeLeader;

  /// No description provided for @modeFollower.
  ///
  /// In es, this message translates to:
  /// **'Seguidor'**
  String get modeFollower;

  /// No description provided for @myClick.
  ///
  /// In es, this message translates to:
  /// **'Mi click'**
  String get myClick;

  /// No description provided for @myClickHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo en este dispositivo: cada músico pone el suyo.'**
  String get myClickHelp;

  /// No description provided for @subdivision.
  ///
  /// In es, this message translates to:
  /// **'Subdivisión'**
  String get subdivision;

  /// No description provided for @volume.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get volume;

  /// No description provided for @sound.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get sound;

  /// No description provided for @soundBeep.
  ///
  /// In es, this message translates to:
  /// **'Pitido'**
  String get soundBeep;

  /// No description provided for @soundWood.
  ///
  /// In es, this message translates to:
  /// **'Madera'**
  String get soundWood;

  /// No description provided for @soundDigital.
  ///
  /// In es, this message translates to:
  /// **'Digital'**
  String get soundDigital;

  /// No description provided for @displacedClick.
  ///
  /// In es, this message translates to:
  /// **'Click desplazado'**
  String get displacedClick;

  /// No description provided for @displacedNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora en: {step}'**
  String displacedNow(String step);

  /// No description provided for @everyBars.
  ///
  /// In es, this message translates to:
  /// **'Cada {count}'**
  String everyBars(int count);

  /// No description provided for @displacedHelp.
  ///
  /// In es, this message translates to:
  /// **'Se mueve una semicorchea cada 2 o 3 compases: 1, e, &, a.'**
  String get displacedHelp;

  /// No description provided for @gapTrainer.
  ///
  /// In es, this message translates to:
  /// **'Entrenador de tempo'**
  String get gapTrainer;

  /// No description provided for @gapTrainerHelp.
  ///
  /// In es, this message translates to:
  /// **'El click suena unos compases y luego se calla.'**
  String get gapTrainerHelp;

  /// No description provided for @barsWithClick.
  ///
  /// In es, this message translates to:
  /// **'Compases con click'**
  String get barsWithClick;

  /// No description provided for @barsSilent.
  ///
  /// In es, this message translates to:
  /// **'Compases en silencio'**
  String get barsSilent;

  /// No description provided for @tempoRamp.
  ///
  /// In es, this message translates to:
  /// **'Rampa de tempo'**
  String get tempoRamp;

  /// No description provided for @tempoRampHelp.
  ///
  /// In es, this message translates to:
  /// **'El tempo sube cada pocos compases. Al parar vuelve al inicial.'**
  String get tempoRampHelp;

  /// No description provided for @rampUpBpm.
  ///
  /// In es, this message translates to:
  /// **'Subir (BPM)'**
  String get rampUpBpm;

  /// No description provided for @rampEveryBars.
  ///
  /// In es, this message translates to:
  /// **'Cada (compases)'**
  String get rampEveryBars;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'El del sistema'**
  String get languageSystem;

  /// No description provided for @practiceTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas de práctica'**
  String get practiceTools;

  /// No description provided for @practiceToolsHelp.
  ///
  /// In es, this message translates to:
  /// **'Añade al metrónomo la sección Práctica: click desplazado, entrenador de tempo y rampa.'**
  String get practiceToolsHelp;

  /// No description provided for @countInHelp.
  ///
  /// In es, this message translates to:
  /// **'Compases de click en otro tono antes de cada canción. Como Seguidor suena la cuenta del líder.'**
  String get countInHelp;

  /// No description provided for @flash.
  ///
  /// In es, this message translates to:
  /// **'Flash de pantalla'**
  String get flash;

  /// No description provided for @flashHelp.
  ///
  /// In es, this message translates to:
  /// **'El metrónomo parpadea con cada pulso. Por encima de 180 BPM, solo en el primer pulso del compás.'**
  String get flashHelp;

  /// No description provided for @flashCountIn.
  ///
  /// In es, this message translates to:
  /// **'Flash en la cuenta de entrada'**
  String get flashCountIn;

  /// No description provided for @flashCountInHelp.
  ///
  /// In es, this message translates to:
  /// **'Si parpadea durante la cuenta, esté o no encendido el flash de cada pulso.'**
  String get flashCountInHelp;

  /// No description provided for @sessionCode.
  ///
  /// In es, this message translates to:
  /// **'Código de sesión'**
  String get sessionCode;

  /// No description provided for @sessionCodeIs.
  ///
  /// In es, this message translates to:
  /// **'Código de sesión: {code}'**
  String sessionCodeIs(String code);

  /// No description provided for @sessionCodeOffHelp.
  ///
  /// In es, this message translates to:
  /// **'Sin código: Link estándar, compatible con Ableton Live y otras apps. Pon uno si hay otra banda en la misma red.'**
  String get sessionCodeOffHelp;

  /// No description provided for @sessionCodeOnHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo comparten click los dispositivos con este mismo código. Ableton Live y otras apps con Link no os ven hasta que lo quites.'**
  String get sessionCodeOnHelp;

  /// No description provided for @sessionCodeReset.
  ///
  /// In es, this message translates to:
  /// **'Quitar código (volver a Link estándar)'**
  String get sessionCodeReset;

  /// No description provided for @sessionCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'El mismo en toda la banda'**
  String get sessionCodeLabel;

  /// No description provided for @latencyAdjust.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de latencia: {ms} ms'**
  String latencyAdjust(int ms);

  /// No description provided for @latencyHelp.
  ///
  /// In es, this message translates to:
  /// **'Súbelo si tu click suena tarde respecto a los demás (p. ej. con auriculares Bluetooth), o calíbralo abajo.'**
  String get latencyHelp;

  /// No description provided for @latencyCompensated.
  ///
  /// In es, this message translates to:
  /// **'Latencia de salida ya compensada: {ms} ms'**
  String latencyCompensated(String ms);

  /// No description provided for @calibrate.
  ///
  /// In es, this message translates to:
  /// **'Calibrar con el líder'**
  String get calibrate;

  /// No description provided for @calibrateListening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando… no toques nada durante 8 segundos.'**
  String get calibrateListening;

  /// No description provided for @calibrateHelp.
  ///
  /// In es, this message translates to:
  /// **'Con este dispositivo como Seguidor y el líder sonando cerca, el micrófono escucha los dos clicks y ajusta la latencia. Mejor sin otros seguidores sonando y a un tempo moderado.'**
  String get calibrateHelp;

  /// No description provided for @calibrateAligned.
  ///
  /// In es, this message translates to:
  /// **'Ya estabas alineado con el líder.'**
  String get calibrateAligned;

  /// No description provided for @calibrateLate.
  ///
  /// In es, this message translates to:
  /// **'Sonabas {ms} ms tarde.'**
  String calibrateLate(int ms);

  /// No description provided for @calibrateEarly.
  ///
  /// In es, this message translates to:
  /// **'Sonabas {ms} ms antes.'**
  String calibrateEarly(int ms);

  /// No description provided for @calibrateFixed.
  ///
  /// In es, this message translates to:
  /// **'Ajuste corregido.'**
  String get calibrateFixed;

  /// No description provided for @calibrateLimit.
  ///
  /// In es, this message translates to:
  /// **'El ajuste llegó a su límite ({ms} ms); revisa la salida de audio de este dispositivo.'**
  String calibrateLimit(int ms);

  /// No description provided for @calibrateNotFollowing.
  ///
  /// In es, this message translates to:
  /// **'Ponte como Seguidor con el líder sonando.'**
  String get calibrateNotFollowing;

  /// No description provided for @calibrateNoPermission.
  ///
  /// In es, this message translates to:
  /// **'Hace falta permiso para usar el micrófono.'**
  String get calibrateNoPermission;

  /// No description provided for @calibrateMicFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el micrófono.'**
  String get calibrateMicFailed;

  /// No description provided for @calibrateNotHeard.
  ///
  /// In es, this message translates to:
  /// **'No se oyeron bien los dos clicks. Acerca el dispositivo al líder, sube el volumen, deja sonar solo al líder (sin click desplazado) y prueba otra vez.'**
  String get calibrateNotHeard;

  /// No description provided for @cannotUndo.
  ///
  /// In es, this message translates to:
  /// **'No se puede deshacer.'**
  String get cannotUndo;

  /// No description provided for @newSong.
  ///
  /// In es, this message translates to:
  /// **'Nueva canción'**
  String get newSong;

  /// No description provided for @editSong.
  ///
  /// In es, this message translates to:
  /// **'Editar canción'**
  String get editSong;

  /// No description provided for @noSongs.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay canciones. Toca + para crear una con su tempo, compás y duración.'**
  String get noSongs;

  /// No description provided for @options.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get options;

  /// No description provided for @searchSong.
  ///
  /// In es, this message translates to:
  /// **'Buscar canción'**
  String get searchSong;

  /// No description provided for @clearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get clearSearch;

  /// No description provided for @noMatch.
  ///
  /// In es, this message translates to:
  /// **'Ninguna canción coincide.'**
  String get noMatch;

  /// No description provided for @tempoBpm.
  ///
  /// In es, this message translates to:
  /// **'Tempo (BPM)'**
  String get tempoBpm;

  /// No description provided for @durationOptional.
  ///
  /// In es, this message translates to:
  /// **'Duración (opcional)'**
  String get durationOptional;

  /// No description provided for @durationHelp.
  ///
  /// In es, this message translates to:
  /// **'Minutos:segundos. En un setlist, al acabar pasa a la siguiente.'**
  String get durationHelp;

  /// No description provided for @durationInvalid.
  ///
  /// In es, this message translates to:
  /// **'Usa minutos:segundos, p. ej. 3:30'**
  String get durationInvalid;

  /// No description provided for @sectionsOptional.
  ///
  /// In es, this message translates to:
  /// **'Secciones (opcional)'**
  String get sectionsOptional;

  /// No description provided for @sectionsHelp.
  ///
  /// In es, this message translates to:
  /// **'Tramos con sus compases y, si quieres, su tempo y compás. Suenan en orden y de ellos sale la duración de la canción.'**
  String get sectionsHelp;

  /// No description provided for @moveUp.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get moveUp;

  /// No description provided for @removeSection.
  ///
  /// In es, this message translates to:
  /// **'Quitar sección'**
  String get removeSection;

  /// No description provided for @authorOptional.
  ///
  /// In es, this message translates to:
  /// **'Autor (opcional)'**
  String get authorOptional;

  /// No description provided for @keyOptional.
  ///
  /// In es, this message translates to:
  /// **'Tonalidad (opcional)'**
  String get keyOptional;

  /// No description provided for @noteOptional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get noteOptional;

  /// No description provided for @noteHint.
  ///
  /// In es, this message translates to:
  /// **'Entra la batería sola'**
  String get noteHint;

  /// No description provided for @noteHelp.
  ///
  /// In es, this message translates to:
  /// **'Se ve en el metrónomo, también en los seguidores.'**
  String get noteHelp;

  /// No description provided for @lyricsOptional.
  ///
  /// In es, this message translates to:
  /// **'Letra (opcional)'**
  String get lyricsOptional;

  /// No description provided for @lyricsHelp.
  ///
  /// In es, this message translates to:
  /// **'Formato ChordPro: acordes entre corchetes, [Am], y avisos como {example}.'**
  String lyricsHelp(String example);

  /// No description provided for @lyricsHelpCue.
  ///
  /// In es, this message translates to:
  /// **'Entra toda la banda'**
  String get lyricsHelpCue;

  /// No description provided for @newSection.
  ///
  /// In es, this message translates to:
  /// **'Nueva sección'**
  String get newSection;

  /// No description provided for @editSection.
  ///
  /// In es, this message translates to:
  /// **'Editar sección'**
  String get editSection;

  /// No description provided for @sectionNameHint.
  ///
  /// In es, this message translates to:
  /// **'Coro'**
  String get sectionNameHint;

  /// No description provided for @barsLabel.
  ///
  /// In es, this message translates to:
  /// **'Compases'**
  String get barsLabel;

  /// No description provided for @between1and999.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y 999'**
  String get between1and999;

  /// No description provided for @tempoOptional.
  ///
  /// In es, this message translates to:
  /// **'Tempo (opcional)'**
  String get tempoOptional;

  /// No description provided for @tempoOptionalHelp.
  ///
  /// In es, this message translates to:
  /// **'Vacío: el de la canción.'**
  String get tempoOptionalHelp;

  /// No description provided for @useSongMeter.
  ///
  /// In es, this message translates to:
  /// **'Usar el compás de la canción'**
  String get useSongMeter;

  /// No description provided for @songMeter.
  ///
  /// In es, this message translates to:
  /// **'El de la canción'**
  String get songMeter;

  /// No description provided for @newSetlist.
  ///
  /// In es, this message translates to:
  /// **'Nuevo setlist'**
  String get newSetlist;

  /// No description provided for @noSetlists.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay setlists. Toca + para crear uno y añadirle canciones.'**
  String get noSetlists;

  /// No description provided for @songCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 canción} other{{count} canciones}}'**
  String songCount(int count);

  /// No description provided for @createSongsFirst.
  ///
  /// In es, this message translates to:
  /// **'Primero crea canciones en Canciones.'**
  String get createSongsFirst;

  /// No description provided for @renameSetlist.
  ///
  /// In es, this message translates to:
  /// **'Renombrar setlist'**
  String get renameSetlist;

  /// No description provided for @rename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get rename;

  /// No description provided for @setlistDeleteKeepsSongs.
  ///
  /// In es, this message translates to:
  /// **'Las canciones no se borran.'**
  String get setlistDeleteKeepsSongs;

  /// No description provided for @exportSetlist.
  ///
  /// In es, this message translates to:
  /// **'Exportar setlist'**
  String get exportSetlist;

  /// No description provided for @deleteSetlist.
  ///
  /// In es, this message translates to:
  /// **'Borrar setlist'**
  String get deleteSetlist;

  /// No description provided for @autoAdvance.
  ///
  /// In es, this message translates to:
  /// **'Pasar a la siguiente automáticamente'**
  String get autoAdvance;

  /// No description provided for @autoAdvanceHelp.
  ///
  /// In es, this message translates to:
  /// **'Al acabar la duración de una canción empieza la siguiente en el compás exacto. Al final del setlist, se para.'**
  String get autoAdvanceHelp;

  /// No description provided for @pauseBetween.
  ///
  /// In es, this message translates to:
  /// **'Pausa entre canciones'**
  String get pauseBetween;

  /// No description provided for @pauseBetweenHelp.
  ///
  /// In es, this message translates to:
  /// **'Compases en silencio, al tempo de la siguiente, antes de que empiece.'**
  String get pauseBetweenHelp;

  /// No description provided for @setlistCountInHelp.
  ///
  /// In es, this message translates to:
  /// **'Compases de click en otro tono antes de cada canción, después de la pausa.'**
  String get setlistCountInHelp;

  /// No description provided for @countInFromSettings.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ajustes (no)} other{Ajustes ({count})}}'**
  String countInFromSettings(int count);

  /// No description provided for @noDurationManual.
  ///
  /// In es, this message translates to:
  /// **'{summary} · sin duración: pasa a mano'**
  String noDurationManual(String summary);

  /// No description provided for @removeFromSetlist.
  ///
  /// In es, this message translates to:
  /// **'Quitar del setlist'**
  String get removeFromSetlist;

  /// No description provided for @addSongs.
  ///
  /// In es, this message translates to:
  /// **'Añadir canciones'**
  String get addSongs;

  /// No description provided for @addCount.
  ///
  /// In es, this message translates to:
  /// **'Añadir ({count})'**
  String addCount(int count);

  /// No description provided for @songsImported.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 canción importada.} other{{count} canciones importadas.}}'**
  String songsImported(int count);

  /// No description provided for @filesWithoutSongs.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 archivo sin canciones.} other{{count} archivos sin canciones.}}'**
  String filesWithoutSongs(int count);

  /// No description provided for @cannotRead.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo.'**
  String get cannotRead;

  /// No description provided for @cannotSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el archivo.'**
  String get cannotSave;

  /// No description provided for @savedFile.
  ///
  /// In es, this message translates to:
  /// **'Guardado: {file}'**
  String savedFile(String file);

  /// No description provided for @songsFileName.
  ///
  /// In es, this message translates to:
  /// **'canciones'**
  String get songsFileName;

  /// No description provided for @notASetlist.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no es un setlist de PrronClick.'**
  String get notASetlist;

  /// No description provided for @setlistImported.
  ///
  /// In es, this message translates to:
  /// **'Setlist \"{name}\" importado.'**
  String setlistImported(String name);

  /// No description provided for @beatsPerBar.
  ///
  /// In es, this message translates to:
  /// **'Pulsos por compás'**
  String get beatsPerBar;

  /// No description provided for @beatUnit.
  ///
  /// In es, this message translates to:
  /// **'Figura del pulso'**
  String get beatUnit;

  /// No description provided for @meterHelp.
  ///
  /// In es, this message translates to:
  /// **'El click suena una vez por pulso y el tempo cuenta esos pulsos: en 6/8 a 180 BPM suenan 180 corcheas por minuto.'**
  String get meterHelp;

  /// No description provided for @useMeter.
  ///
  /// In es, this message translates to:
  /// **'Usar {meter}'**
  String useMeter(String meter);

  /// No description provided for @chorus.
  ///
  /// In es, this message translates to:
  /// **'Coro'**
  String get chorus;

  /// No description provided for @verse.
  ///
  /// In es, this message translates to:
  /// **'Verso'**
  String get verse;

  /// No description provided for @bridge.
  ///
  /// In es, this message translates to:
  /// **'Puente'**
  String get bridge;

  /// No description provided for @accentStrong.
  ///
  /// In es, this message translates to:
  /// **'Fuerte'**
  String get accentStrong;

  /// No description provided for @accentMedium.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get accentMedium;

  /// No description provided for @accentNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get accentNormal;

  /// No description provided for @accentSilent.
  ///
  /// In es, this message translates to:
  /// **'Mudo'**
  String get accentSilent;

  /// No description provided for @accentBeat.
  ///
  /// In es, this message translates to:
  /// **'Pulso {beat}: {level}'**
  String accentBeat(int beat, String level);

  /// No description provided for @accentsHelp.
  ///
  /// In es, this message translates to:
  /// **'Toca un pulso para cambiar su acento: normal, fuerte, medio o mudo. También en el metrónomo.'**
  String get accentsHelp;

  /// No description provided for @voiceCount.
  ///
  /// In es, this message translates to:
  /// **'Voz en la cuenta'**
  String get voiceCount;

  /// No description provided for @voiceCountHelp.
  ///
  /// In es, this message translates to:
  /// **'Una voz dice los números de la cuenta: «uno, dos, tres, cuatro».'**
  String get voiceCountHelp;

  /// No description provided for @voiceSections.
  ///
  /// In es, this message translates to:
  /// **'Voz en las secciones'**
  String get voiceSections;

  /// No description provided for @voiceSectionsHelp.
  ///
  /// In es, this message translates to:
  /// **'Un compás antes, una voz dice la sección que viene: «Coro», «Verso dos».'**
  String get voiceSectionsHelp;

  /// No description provided for @voicesMissing.
  ///
  /// In es, this message translates to:
  /// **'Esta versión no trae voces.'**
  String get voicesMissing;

  /// No description provided for @transpose.
  ///
  /// In es, this message translates to:
  /// **'Transponer'**
  String get transpose;

  /// No description provided for @transposeDown.
  ///
  /// In es, this message translates to:
  /// **'Medio tono abajo'**
  String get transposeDown;

  /// No description provided for @transposeUp.
  ///
  /// In es, this message translates to:
  /// **'Medio tono arriba'**
  String get transposeUp;

  /// No description provided for @saveLeaderSetlist.
  ///
  /// In es, this message translates to:
  /// **'Guardar este setlist en mi biblioteca'**
  String get saveLeaderSetlist;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial de práctica'**
  String get history;

  /// No description provided for @historyNoSong.
  ///
  /// In es, this message translates to:
  /// **'Sin canción'**
  String get historyNoSong;

  /// No description provided for @historyEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay práctica. Cada vez que el click suena al menos 10 segundos, queda anotado aquí.'**
  String get historyEmpty;

  /// No description provided for @historyTimes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 vez} other{{count} veces}}'**
  String historyTimes(int count);

  /// No description provided for @historyBpm.
  ///
  /// In es, this message translates to:
  /// **'{bpm} BPM'**
  String historyBpm(int bpm);

  /// No description provided for @historyTempo.
  ///
  /// In es, this message translates to:
  /// **'{first} → {last} BPM (máx. {best})'**
  String historyTempo(int first, int last, int best);

  /// No description provided for @historyClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar historial'**
  String get historyClear;

  /// No description provided for @historyClearAsk.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todo el historial de práctica? No se puede deshacer.'**
  String get historyClearAsk;

  /// No description provided for @durationM.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String durationM(int minutes);

  /// No description provided for @durationHm.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHm(int hours, int minutes);

  /// No description provided for @durationS.
  ///
  /// In es, this message translates to:
  /// **'{seconds} s'**
  String durationS(int seconds);

  /// No description provided for @historyRangeDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get historyRangeDay;

  /// No description provided for @historyRangeWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get historyRangeWeek;

  /// No description provided for @historyRangeMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get historyRangeMonth;

  /// No description provided for @historyPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get historyPrevious;

  /// No description provided for @historyNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get historyNext;

  /// No description provided for @historyWholePeriod.
  ///
  /// In es, this message translates to:
  /// **'Ver todo el periodo'**
  String get historyWholePeriod;

  /// No description provided for @historyTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get historyTime;

  /// No description provided for @historySessionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get historySessionsLabel;

  /// No description provided for @historyDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días practicados'**
  String get historyDaysLabel;

  /// No description provided for @historyLongest.
  ///
  /// In es, this message translates to:
  /// **'Sesión más larga'**
  String get historyLongest;

  /// No description provided for @historyStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get historyStreak;

  /// No description provided for @historyStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String historyStreakDays(int count);

  /// No description provided for @historyVsPrevDay.
  ///
  /// In es, this message translates to:
  /// **'{change} vs. el día anterior'**
  String historyVsPrevDay(String change);

  /// No description provided for @historyVsPrevWeek.
  ///
  /// In es, this message translates to:
  /// **'{change} vs. la semana anterior'**
  String historyVsPrevWeek(String change);

  /// No description provided for @historyVsPrevMonth.
  ///
  /// In es, this message translates to:
  /// **'{change} vs. el mes anterior'**
  String historyVsPrevMonth(String change);

  /// No description provided for @historyTapHour.
  ///
  /// In es, this message translates to:
  /// **'Toca una barra para ver esa hora.'**
  String get historyTapHour;

  /// No description provided for @historyTapDay.
  ///
  /// In es, this message translates to:
  /// **'Toca un día para ver solo ese día.'**
  String get historyTapDay;

  /// No description provided for @historyMax.
  ///
  /// In es, this message translates to:
  /// **'máx. {time}'**
  String historyMax(String time);

  /// No description provided for @historySongs.
  ///
  /// In es, this message translates to:
  /// **'Canciones'**
  String get historySongs;

  /// No description provided for @historyTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get historyTools;

  /// No description provided for @historyNoTools.
  ///
  /// In es, this message translates to:
  /// **'Sin herramientas'**
  String get historyNoTools;

  /// No description provided for @historyNothing.
  ///
  /// In es, this message translates to:
  /// **'Nada en este periodo.'**
  String get historyNothing;

  /// No description provided for @historyBestBpm.
  ///
  /// In es, this message translates to:
  /// **'Mejor tempo'**
  String get historyBestBpm;

  /// No description provided for @historyTempoChange.
  ///
  /// In es, this message translates to:
  /// **'Cambio de tempo'**
  String get historyTempoChange;

  /// No description provided for @historyTempoPerSession.
  ///
  /// In es, this message translates to:
  /// **'Tempo por sesión'**
  String get historyTempoPerSession;

  /// No description provided for @historyTapPoint.
  ///
  /// In es, this message translates to:
  /// **'Toca o desliza en el gráfico para ver cada sesión.'**
  String get historyTapPoint;

  /// No description provided for @backupSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar copia de seguridad'**
  String get backupSave;

  /// No description provided for @backupSaveHelp.
  ///
  /// In es, this message translates to:
  /// **'Canciones, setlists, ajustes e historial de práctica en un archivo.'**
  String get backupSaveHelp;

  /// No description provided for @backupRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia de seguridad'**
  String get backupRestore;

  /// No description provided for @backupRestoreHelp.
  ///
  /// In es, this message translates to:
  /// **'Reemplaza todo por lo de un archivo guardado antes, de este u otro dispositivo.'**
  String get backupRestoreHelp;

  /// No description provided for @backupRestoreAsk.
  ///
  /// In es, this message translates to:
  /// **'¿Reemplazar todo?'**
  String get backupRestoreAsk;

  /// No description provided for @backupRestoreWhat.
  ///
  /// In es, this message translates to:
  /// **'Tus canciones, setlists, ajustes e historial se reemplazan por los del archivo: {songs, plural, =1{1 canción} other{{songs} canciones}} y {setlists, plural, =1{1 setlist} other{{setlists} setlists}}.'**
  String backupRestoreWhat(int songs, int setlists);

  /// No description provided for @backupReplace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get backupReplace;

  /// No description provided for @backupRestored.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad restaurada.'**
  String get backupRestored;

  /// No description provided for @notABackup.
  ///
  /// In es, this message translates to:
  /// **'Ese archivo no es una copia de seguridad de PrronClick.'**
  String get notABackup;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @vibrate.
  ///
  /// In es, this message translates to:
  /// **'Vibrar en el pulso'**
  String get vibrate;

  /// No description provided for @vibrateHelp.
  ///
  /// In es, this message translates to:
  /// **'El teléfono vibra en cada pulso que suena, más fuerte en los acentos. Funciona con la pantalla apagada.'**
  String get vibrateHelp;

  /// No description provided for @vibrateDownbeat.
  ///
  /// In es, this message translates to:
  /// **'Vibrar solo en el 1'**
  String get vibrateDownbeat;

  /// No description provided for @vibrateDownbeatHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo en el primer pulso de cada compás.'**
  String get vibrateDownbeatHelp;

  /// No description provided for @rampMaxBpm.
  ///
  /// In es, this message translates to:
  /// **'Hasta (BPM)'**
  String get rampMaxBpm;

  /// No description provided for @rampNoMax.
  ///
  /// In es, this message translates to:
  /// **'Sin límite'**
  String get rampNoMax;

  /// No description provided for @rampMaxDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar el tope'**
  String get rampMaxDown;

  /// No description provided for @rampMaxUp.
  ///
  /// In es, this message translates to:
  /// **'Subir el tope'**
  String get rampMaxUp;

  /// No description provided for @rampMaxStep.
  ///
  /// In es, this message translates to:
  /// **'Botones − y + de (BPM)'**
  String get rampMaxStep;
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
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
