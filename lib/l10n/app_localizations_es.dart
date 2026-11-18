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
  String get noLyrics => 'Esta canción no tiene letra.';

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
  String get panelBand => 'Banda';

  @override
  String get panelPractice => 'Práctica';

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
      'Añade al metrónomo la sección Práctica: click desplazado, entrenador de tempo y rampa.';

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
  String get authorOptional => 'Autor (opcional)';

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

  @override
  String get saveLeaderSetlist => 'Guardar este setlist en mi biblioteca';

  @override
  String get history => 'Historial de práctica';

  @override
  String get historyNoSong => 'Sin canción';

  @override
  String get historyEmpty =>
      'Todavía no hay práctica. Cada vez que el click suena al menos 10 segundos, queda anotado aquí.';

  @override
  String historyTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String historyBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String historyTempo(int first, int last, int best) {
    return '$first → $last BPM (máx. $best)';
  }

  @override
  String get historyClear => 'Borrar historial';

  @override
  String get historyClearAsk =>
      '¿Borrar todo el historial de práctica? No se puede deshacer.';

  @override
  String durationM(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationS(int seconds) {
    return '$seconds s';
  }

  @override
  String get historyRangeDay => 'Día';

  @override
  String get historyRangeWeek => 'Semana';

  @override
  String get historyRangeMonth => 'Mes';

  @override
  String get historyPrevious => 'Anterior';

  @override
  String get historyNext => 'Siguiente';

  @override
  String get historyWholePeriod => 'Ver todo el periodo';

  @override
  String get historyTime => 'Tiempo';

  @override
  String get historySessionsLabel => 'Sesiones';

  @override
  String get historyDaysLabel => 'Días practicados';

  @override
  String get historyLongest => 'Sesión más larga';

  @override
  String get historyStreak => 'Racha';

  @override
  String historyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String historyVsPrevDay(String change) {
    return '$change vs. el día anterior';
  }

  @override
  String historyVsPrevWeek(String change) {
    return '$change vs. la semana anterior';
  }

  @override
  String historyVsPrevMonth(String change) {
    return '$change vs. el mes anterior';
  }

  @override
  String get historyTapHour => 'Toca una barra para ver esa hora.';

  @override
  String get historyTapDay => 'Toca un día para ver solo ese día.';

  @override
  String historyMax(String time) {
    return 'máx. $time';
  }

  @override
  String get historySongs => 'Canciones';

  @override
  String get historyTools => 'Herramientas';

  @override
  String get historyNoTools => 'Sin herramientas';

  @override
  String get historyNothing => 'Nada en este periodo.';

  @override
  String get historyBestBpm => 'Mejor tempo';

  @override
  String get historyTempoChange => 'Cambio de tempo';

  @override
  String get historyTempoPerSession => 'Tempo por sesión';

  @override
  String get historyTapPoint =>
      'Toca o desliza en el gráfico para ver cada sesión.';

  @override
  String get backupSave => 'Guardar copia de seguridad';

  @override
  String get backupSaveHelp =>
      'Canciones, setlists, ajustes e historial de práctica en un archivo.';

  @override
  String get backupRestore => 'Restaurar copia de seguridad';

  @override
  String get backupRestoreHelp =>
      'Reemplaza todo por lo de un archivo guardado antes, de este u otro dispositivo.';

  @override
  String get backupRestoreAsk => '¿Reemplazar todo?';

  @override
  String backupRestoreWhat(int songs, int setlists) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs canciones',
      one: '1 canción',
    );
    String _temp1 = intl.Intl.pluralLogic(
      setlists,
      locale: localeName,
      other: '$setlists setlists',
      one: '1 setlist',
    );
    return 'Tus canciones, setlists, ajustes e historial se reemplazan por los del archivo: $_temp0 y $_temp1.';
  }

  @override
  String get backupReplace => 'Reemplazar';

  @override
  String get backupRestored => 'Copia de seguridad restaurada.';

  @override
  String get notABackup =>
      'Ese archivo no es una copia de seguridad de PrronClick.';

  @override
  String get undo => 'Deshacer';

  @override
  String get vibrate => 'Vibrar en el pulso';

  @override
  String get vibrateHelp =>
      'El teléfono vibra en cada pulso que suena, más fuerte en los acentos. Funciona con la pantalla apagada.';

  @override
  String get vibrateDownbeat => 'Vibrar solo en el 1';

  @override
  String get vibrateDownbeatHelp => 'Solo en el primer pulso de cada compás.';

  @override
  String get rampMaxBpm => 'Hasta (BPM)';

  @override
  String get rampNoMax => 'Sin límite';

  @override
  String get rampMaxDown => 'Bajar el tope';

  @override
  String get rampMaxUp => 'Subir el tope';

  @override
  String get rampMaxStep => 'Botones − y + de (BPM)';
}
