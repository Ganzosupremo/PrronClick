// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get audioFailed => 'No se pudo abrir la salida de audio.';

  @override
  String get tabMetronome => 'Metrónomo';

  @override
  String get tabSongs => 'Canciones';

  @override
  String get tabSetlists => 'Setlists';

  @override
  String get importExport => 'Importar o exportar';

  @override
  String get importSongs => 'Importar canciones';

  @override
  String get exportSongs => 'Exportar canciones';

  @override
  String get importSetlist => 'Importar setlist';

  @override
  String get settings => 'Ajustes';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get no => 'No';

  @override
  String get name => 'Nombre';

  @override
  String get meter => 'Compás';

  @override
  String get countIn => 'Cuenta de entrada';

  @override
  String bars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compases',
      one: '1 compás',
    );
    return '$_temp0';
  }

  @override
  String inBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count compases',
      one: 'en el próximo compás',
    );
    return '$_temp0';
  }

  @override
  String get followerNoTempo => 'Como seguidor, el tempo lo pone el líder.';

  @override
  String deleteQuestion(String name) {
    return '¿Borrar \"$name\"?';
  }

  @override
  String get between20and300 => 'Entre 20 y 300';

  @override
  String get nameRequired => 'Ponle un nombre';

  @override
  String comingUpSection(String section, String when) {
    return 'Sigue: $section $when';
  }

  @override
  String leaderPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Líder · $count conectados',
      one: 'Líder · 1 conectado',
    );
    return '$_temp0';
  }

  @override
  String get searchingLeader => 'Buscando líder…';

  @override
  String get followingLeader => 'Siguiendo al líder';

  @override
  String get statusPause => 'Pausa';

  @override
  String get statusSilence => 'Silencio';

  @override
  String get tempoDown => 'Bajar tempo';

  @override
  String get tempoUp => 'Subir tempo';

  @override
  String get tapTempo => 'Tap tempo';

  @override
  String get stop => 'Parar';

  @override
  String get start => 'Empezar';

  @override
  String get lyrics => 'Letra';

  @override
  String setlistEnds(String when) {
    return 'Termina $when';
  }

  @override
  String setlistNextIn(String song, String when) {
    return 'Sigue \"$song\" $when';
  }

  @override
  String get lastSong => 'Última canción';

  @override
  String nextSong(String song) {
    return 'Siguiente: $song';
  }

  @override
  String get previousSongTooltip => 'Canción anterior';

  @override
  String get nextSongTooltip => 'Canción siguiente';

  @override
  String get leaveSetlist => 'Salir del setlist';

  @override
  String get tools => 'Herramientas';

  @override
  String get shareClick => 'Compartir click';

  @override
  String get modeSolo => 'Solo';

  @override
  String get modeLeader => 'Líder';

  @override
  String get modeFollower => 'Seguidor';

  @override
  String get myClick => 'Mi click';

  @override
  String get myClickHelp =>
      'Solo en este dispositivo: cada músico pone el suyo.';

  @override
  String get subdivision => 'Subdivisión';

  @override
  String get volume => 'Volumen';

  @override
  String get sound => 'Sonido';

  @override
  String get soundBeep => 'Pitido';

  @override
  String get soundWood => 'Madera';

  @override
  String get soundDigital => 'Digital';

  @override
  String get displacedClick => 'Click desplazado';

  @override
  String displacedNow(String step) {
    return 'Ahora en: $step';
  }

  @override
  String everyBars(int count) {
    return 'Cada $count';
  }

  @override
  String get displacedHelp =>
      'Se mueve una semicorchea cada 2 o 3 compases: 1, e, &, a.';

  @override
  String get gapTrainer => 'Entrenador de tempo';

  @override
  String get gapTrainerHelp => 'El click suena unos compases y luego se calla.';

  @override
  String get barsWithClick => 'Compases con click';

  @override
  String get barsSilent => 'Compases en silencio';

  @override
  String get tempoRamp => 'Rampa de tempo';

  @override
  String get tempoRampHelp =>
      'El tempo sube cada pocos compases. Al parar vuelve al inicial.';

  @override
  String get rampUpBpm => 'Subir (BPM)';

  @override
  String get rampEveryBars => 'Cada (compases)';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'El del sistema';

  @override
  String get practiceTools => 'Herramientas de práctica';

  @override
  String get practiceToolsHelp =>
      'Muestra el click desplazado y el entrenador de tempo en el panel de Herramientas.';

  @override
  String get countInHelp =>
      'Compases de click en otro tono antes de cada canción. Como Seguidor suena la cuenta del líder.';

  @override
  String get flash => 'Flash de pantalla';

  @override
  String get flashHelp =>
      'El metrónomo parpadea con cada pulso. Por encima de 180 BPM, solo en el primer pulso del compás.';

  @override
  String get flashCountIn => 'Flash en la cuenta de entrada';

  @override
  String get flashCountInHelp =>
      'Si parpadea durante la cuenta, esté o no encendido el flash de cada pulso.';

  @override
  String get sessionCode => 'Código de sesión';

  @override
  String sessionCodeIs(String code) {
    return 'Código de sesión: $code';
  }

  @override
  String get sessionCodeOffHelp =>
      'Sin código: Link estándar, compatible con Ableton Live y otras apps. Pon uno si hay otra banda en la misma red.';

  @override
  String get sessionCodeOnHelp =>
      'Solo comparten click los dispositivos con este mismo código. Ableton Live y otras apps con Link no os ven hasta que lo quites.';

  @override
  String get sessionCodeReset => 'Quitar código (volver a Link estándar)';

  @override
  String get sessionCodeLabel => 'El mismo en toda la banda';

  @override
  String latencyAdjust(int ms) {
    return 'Ajuste de latencia: $ms ms';
  }

  @override
  String get latencyHelp =>
      'Súbelo si tu click suena tarde respecto a los demás (p. ej. con auriculares Bluetooth), o calíbralo abajo.';

  @override
  String latencyCompensated(String ms) {
    return 'Latencia de salida ya compensada: $ms ms';
  }

  @override
  String get calibrate => 'Calibrar con el líder';

  @override
  String get calibrateListening =>
      'Escuchando… no toques nada durante 8 segundos.';

  @override
  String get calibrateHelp =>
      'Con este dispositivo como Seguidor y el líder sonando cerca, el micrófono escucha los dos clicks y ajusta la latencia. Mejor sin otros seguidores sonando y a un tempo moderado.';

  @override
  String get calibrateAligned => 'Ya estabas alineado con el líder.';

  @override
  String calibrateLate(int ms) {
    return 'Sonabas $ms ms tarde.';
  }

  @override
  String calibrateEarly(int ms) {
    return 'Sonabas $ms ms antes.';
  }

  @override
  String get calibrateFixed => 'Ajuste corregido.';

  @override
  String calibrateLimit(int ms) {
    return 'El ajuste llegó a su límite ($ms ms); revisa la salida de audio de este dispositivo.';
  }

  @override
  String get calibrateNotFollowing =>
      'Ponte como Seguidor con el líder sonando.';

  @override
  String get calibrateNoPermission =>
      'Hace falta permiso para usar el micrófono.';

  @override
  String get calibrateMicFailed => 'No se pudo abrir el micrófono.';

  @override
  String get calibrateNotHeard =>
      'No se oyeron bien los dos clicks. Acerca el dispositivo al líder, sube el volumen, deja sonar solo al líder (sin click desplazado) y prueba otra vez.';

  @override
  String get cannotUndo => 'No se puede deshacer.';

  @override
  String get newSong => 'Nueva canción';

  @override
  String get editSong => 'Editar canción';

  @override
  String get noSongs =>
      'Aún no hay canciones. Toca + para crear una con su tempo, compás y duración.';

  @override
  String get options => 'Opciones';

  @override
  String get searchSong => 'Buscar canción';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get noMatch => 'Ninguna canción coincide.';

  @override
  String get tempoBpm => 'Tempo (BPM)';

  @override
  String get durationOptional => 'Duración (opcional)';

  @override
  String get durationHelp =>
      'Minutos:segundos. En un setlist, al acabar pasa a la siguiente.';

  @override
  String get durationInvalid => 'Usa minutos:segundos, p. ej. 3:30';

  @override
  String get sectionsOptional => 'Secciones (opcional)';

  @override
  String get sectionsHelp =>
      'Tramos con sus compases y, si quieres, su tempo y compás. Suenan en orden y de ellos sale la duración de la canción.';

  @override
  String get moveUp => 'Subir';

  @override
  String get removeSection => 'Quitar sección';

  @override
  String get keyOptional => 'Tonalidad (opcional)';

  @override
  String get noteOptional => 'Nota (opcional)';

  @override
  String get noteHint => 'Entra la batería sola';

  @override
  String get noteHelp => 'Se ve en el metrónomo, también en los seguidores.';

  @override
  String get lyricsOptional => 'Letra (opcional)';

  @override
  String lyricsHelp(String example) {
    return 'Formato ChordPro: acordes entre corchetes, [Am], y avisos como $example.';
  }

  @override
  String get lyricsHelpCue => 'Entra toda la banda';

  @override
  String get newSection => 'Nueva sección';

  @override
  String get editSection => 'Editar sección';

  @override
  String get sectionNameHint => 'Coro';

  @override
  String get barsLabel => 'Compases';

  @override
  String get between1and999 => 'Entre 1 y 999';

  @override
  String get tempoOptional => 'Tempo (opcional)';

  @override
  String get tempoOptionalHelp => 'Vacío: el de la canción.';

  @override
  String get useSongMeter => 'Usar el compás de la canción';

  @override
  String get songMeter => 'El de la canción';

  @override
  String get newSetlist => 'Nuevo setlist';

  @override
  String get noSetlists =>
      'Aún no hay setlists. Toca + para crear uno y añadirle canciones.';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String get createSongsFirst => 'Primero crea canciones en Canciones.';

  @override
  String get renameSetlist => 'Renombrar setlist';

  @override
  String get rename => 'Renombrar';

  @override
  String get setlistDeleteKeepsSongs => 'Las canciones no se borran.';

  @override
  String get exportSetlist => 'Exportar setlist';

  @override
  String get deleteSetlist => 'Borrar setlist';

  @override
  String get autoAdvance => 'Pasar a la siguiente automáticamente';

  @override
  String get autoAdvanceHelp =>
      'Al acabar la duración de una canción empieza la siguiente en el compás exacto. Al final del setlist, se para.';

  @override
  String get pauseBetween => 'Pausa entre canciones';

  @override
  String get pauseBetweenHelp =>
      'Compases en silencio, al tempo de la siguiente, antes de que empiece.';

  @override
  String get setlistCountInHelp =>
      'Compases de click en otro tono antes de cada canción, después de la pausa.';

  @override
  String countInFromSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajustes ($count)',
      zero: 'Ajustes (no)',
    );
    return '$_temp0';
  }

  @override
  String noDurationManual(String summary) {
    return '$summary · sin duración: pasa a mano';
  }

  @override
  String get removeFromSetlist => 'Quitar del setlist';

  @override
  String get addSongs => 'Añadir canciones';

  @override
  String addCount(int count) {
    return 'Añadir ($count)';
  }

  @override
  String songsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones importadas.',
      one: '1 canción importada.',
    );
    return '$_temp0';
  }

  @override
  String filesWithoutSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos sin canciones.',
      one: '1 archivo sin canciones.',
    );
    return '$_temp0';
  }

  @override
  String get cannotRead => 'No se pudo leer el archivo.';

  @override
  String get cannotSave => 'No se pudo guardar el archivo.';

  @override
  String savedFile(String file) {
    return 'Guardado: $file';
  }

  @override
  String get songsFileName => 'canciones';

  @override
  String get notASetlist => 'Ese archivo no es un setlist de PrronClick.';

  @override
  String setlistImported(String name) {
    return 'Setlist \"$name\" importado.';
  }

  @override
  String get beatsPerBar => 'Pulsos por compás';

  @override
  String get beatUnit => 'Figura del pulso';

  @override
  String get meterHelp =>
      'El click suena una vez por pulso y el tempo cuenta esos pulsos: en 6/8 a 180 BPM suenan 180 corcheas por minuto.';

  @override
  String useMeter(String meter) {
    return 'Usar $meter';
  }

  @override
  String get chorus => 'Coro';

  @override
  String get verse => 'Verso';

  @override
  String get bridge => 'Puente';

  @override
  String get accentStrong => 'Fuerte';

  @override
  String get accentMedium => 'Medio';

  @override
  String get accentNormal => 'Normal';

  @override
  String get accentSilent => 'Mudo';

  @override
  String accentBeat(int beat, String level) {
    return 'Pulso $beat: $level';
  }

  @override
  String get accentsHelp =>
      'Toca un pulso para cambiar su acento: normal, fuerte, medio o mudo. También en el metrónomo.';

  @override
  String get voiceCount => 'Voz en la cuenta';

  @override
  String get voiceCountHelp =>
      'Una voz dice los números de la cuenta: «uno, dos, tres, cuatro».';

  @override
  String get voiceSections => 'Voz en las secciones';

  @override
  String get voiceSectionsHelp =>
      'Un compás antes, una voz dice la sección que viene: «Coro», «Verso dos».';

  @override
  String get voicesMissing => 'Esta versión no trae voces.';

  @override
  String get transpose => 'Transponer';

  @override
  String get transposeDown => 'Medio tono abajo';

  @override
  String get transposeUp => 'Medio tono arriba';
}
