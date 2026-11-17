// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get audioFailed => 'Die Audioausgabe konnte nicht geöffnet werden.';

  @override
  String get tabMetronome => 'Metronom';

  @override
  String get tabSongs => 'Songs';

  @override
  String get tabSetlists => 'Setlists';

  @override
  String get importExport => 'Importieren oder exportieren';

  @override
  String get importSongs => 'Songs importieren';

  @override
  String get exportSongs => 'Songs exportieren';

  @override
  String get importSetlist => 'Setlist importieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get no => 'Aus';

  @override
  String get name => 'Name';

  @override
  String get meter => 'Taktart';

  @override
  String get countIn => 'Vorzähler';

  @override
  String bars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Takte',
      one: '1 Takt',
    );
    return '$_temp0';
  }

  @override
  String inBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Takten',
      one: 'im nächsten Takt',
    );
    return '$_temp0';
  }

  @override
  String get followerNoTempo => 'Als Mitspieler bestimmt der Leader das Tempo.';

  @override
  String deleteQuestion(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get between20and300 => 'Zwischen 20 und 300';

  @override
  String get nameRequired => 'Gib einen Namen ein';

  @override
  String comingUpSection(String section, String when) {
    return 'Als Nächstes: $section $when';
  }

  @override
  String leaderPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Leader · $count verbunden',
      one: 'Leader · 1 verbunden',
    );
    return '$_temp0';
  }

  @override
  String get searchingLeader => 'Suche Leader…';

  @override
  String get followingLeader => 'Folgt dem Leader';

  @override
  String get statusPause => 'Pause';

  @override
  String get statusSilence => 'Stille';

  @override
  String get tempoDown => 'Tempo runter';

  @override
  String get tempoUp => 'Tempo hoch';

  @override
  String get tapTempo => 'Tap-Tempo';

  @override
  String get stop => 'Stopp';

  @override
  String get start => 'Start';

  @override
  String get lyrics => 'Text';

  @override
  String setlistEnds(String when) {
    return 'Endet $when';
  }

  @override
  String setlistNextIn(String song, String when) {
    return '„$song“ beginnt $when';
  }

  @override
  String get lastSong => 'Letzter Song';

  @override
  String nextSong(String song) {
    return 'Als Nächstes: $song';
  }

  @override
  String get previousSongTooltip => 'Vorheriger Song';

  @override
  String get nextSongTooltip => 'Nächster Song';

  @override
  String get leaveSetlist => 'Setlist verlassen';

  @override
  String get tools => 'Werkzeuge';

  @override
  String get shareClick => 'Klick teilen';

  @override
  String get modeSolo => 'Solo';

  @override
  String get modeLeader => 'Leader';

  @override
  String get modeFollower => 'Mitspieler';

  @override
  String get myClick => 'Mein Klick';

  @override
  String get myClickHelp =>
      'Nur auf diesem Gerät: Jeder Musiker stellt seinen eigenen ein.';

  @override
  String get subdivision => 'Unterteilung';

  @override
  String get volume => 'Lautstärke';

  @override
  String get sound => 'Klang';

  @override
  String get soundBeep => 'Piepton';

  @override
  String get soundWood => 'Holz';

  @override
  String get soundDigital => 'Digital';

  @override
  String get displacedClick => 'Verschobener Klick';

  @override
  String displacedNow(String step) {
    return 'Jetzt auf: $step';
  }

  @override
  String everyBars(int count) {
    return 'Alle $count';
  }

  @override
  String get displacedHelp =>
      'Wandert alle 2 oder 3 Takte eine Sechzehntel weiter: 1, e, &, a.';

  @override
  String get gapTrainer => 'Tempo-Trainer';

  @override
  String get gapTrainerHelp =>
      'Der Klick spielt ein paar Takte und verstummt dann.';

  @override
  String get barsWithClick => 'Takte mit Klick';

  @override
  String get barsSilent => 'Takte ohne Klick';

  @override
  String get tempoRamp => 'Tempo-Rampe';

  @override
  String get tempoRampHelp =>
      'Das Tempo steigt alle paar Takte. Beim Stoppen geht es zurück zum Anfangstempo.';

  @override
  String get rampUpBpm => 'Erhöhen (BPM)';

  @override
  String get rampEveryBars => 'Alle (Takte)';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get practiceTools => 'Übungswerkzeuge';

  @override
  String get practiceToolsHelp =>
      'Zeigt den verschobenen Klick und den Tempo-Trainer im Werkzeuge-Bereich.';

  @override
  String get countInHelp =>
      'Takte Klick in anderer Tonhöhe vor jedem Song. Als Mitspieler hörst du den Vorzähler des Leaders.';

  @override
  String get flash => 'Bildschirmblitz';

  @override
  String get flashHelp =>
      'Das Metronom blinkt bei jedem Schlag. Über 180 BPM nur auf dem ersten Schlag des Takts.';

  @override
  String get flashCountIn => 'Blitz beim Vorzähler';

  @override
  String get flashCountInHelp =>
      'Ob es beim Vorzähler blinkt, unabhängig vom Blitz auf jedem Schlag.';

  @override
  String get sessionCode => 'Session-Code';

  @override
  String sessionCodeIs(String code) {
    return 'Session-Code: $code';
  }

  @override
  String get sessionCodeOffHelp =>
      'Kein Code: Standard-Link, kompatibel mit Ableton Live und anderen Apps. Setze einen, wenn eine andere Band im selben Netzwerk ist.';

  @override
  String get sessionCodeOnHelp =>
      'Nur Geräte mit genau diesem Code teilen einen Klick. Ableton Live und andere Link-Apps sehen euch erst, wenn du ihn entfernst.';

  @override
  String get sessionCodeReset => 'Code entfernen (zurück zu Standard-Link)';

  @override
  String get sessionCodeLabel => 'Für die ganze Band gleich';

  @override
  String latencyAdjust(int ms) {
    return 'Latenzausgleich: $ms ms';
  }

  @override
  String get latencyHelp =>
      'Erhöhe ihn, wenn dein Klick später als bei den anderen klingt (z. B. mit Bluetooth-Kopfhörern), oder kalibriere ihn unten.';

  @override
  String latencyCompensated(String ms) {
    return 'Bereits ausgeglichene Ausgabelatenz: $ms ms';
  }

  @override
  String get calibrate => 'Mit dem Leader kalibrieren';

  @override
  String get calibrateListening => 'Hört zu… 8 Sekunden lang nichts berühren.';

  @override
  String get calibrateHelp =>
      'Mit diesem Gerät als Mitspieler und dem Leader in der Nähe hört das Mikrofon beide Klicks und stellt die Latenz ein. Am besten ohne andere klickende Mitspieler und bei mittlerem Tempo.';

  @override
  String get calibrateAligned => 'Du warst schon synchron mit dem Leader.';

  @override
  String calibrateLate(int ms) {
    return 'Du warst $ms ms zu spät.';
  }

  @override
  String calibrateEarly(int ms) {
    return 'Du warst $ms ms zu früh.';
  }

  @override
  String get calibrateFixed => 'Ausgleich korrigiert.';

  @override
  String calibrateLimit(int ms) {
    return 'Der Ausgleich hat sein Limit erreicht ($ms ms); prüfe die Audioausgabe dieses Geräts.';
  }

  @override
  String get calibrateNotFollowing =>
      'Wechsle zu Mitspieler, während der Leader spielt.';

  @override
  String get calibrateNoPermission =>
      'Die Berechtigung für das Mikrofon wird benötigt.';

  @override
  String get calibrateMicFailed => 'Das Mikrofon konnte nicht geöffnet werden.';

  @override
  String get calibrateNotHeard =>
      'Die beiden Klicks waren nicht deutlich zu hören. Geh näher an den Leader, dreh die Lautstärke auf, lass nur den Leader spielen (ohne verschobenen Klick) und versuch es noch einmal.';

  @override
  String get cannotUndo => 'Das kann nicht rückgängig gemacht werden.';

  @override
  String get newSong => 'Neuer Song';

  @override
  String get editSong => 'Song bearbeiten';

  @override
  String get noSongs =>
      'Noch keine Songs. Tippe auf +, um einen mit Tempo, Taktart und Dauer anzulegen.';

  @override
  String get options => 'Optionen';

  @override
  String get searchSong => 'Song suchen';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String get noMatch => 'Kein Song passt.';

  @override
  String get tempoBpm => 'Tempo (BPM)';

  @override
  String get durationOptional => 'Dauer (optional)';

  @override
  String get durationHelp =>
      'Minuten:Sekunden. In einer Setlist beginnt danach der nächste Song.';

  @override
  String get durationInvalid => 'Minuten:Sekunden verwenden, z. B. 3:30';

  @override
  String get sectionsOptional => 'Abschnitte (optional)';

  @override
  String get sectionsHelp =>
      'Teile mit ihren Takten und, wenn du willst, eigenem Tempo und eigener Taktart. Sie laufen der Reihe nach und ergeben die Dauer des Songs.';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get removeSection => 'Abschnitt entfernen';

  @override
  String get keyOptional => 'Tonart (optional)';

  @override
  String get noteOptional => 'Notiz (optional)';

  @override
  String get noteHint => 'Schlagzeug kommt allein rein';

  @override
  String get noteHelp =>
      'Wird auf dem Metronom angezeigt, auch bei den Mitspielern.';

  @override
  String get lyricsOptional => 'Text (optional)';

  @override
  String lyricsHelp(String example) {
    return 'ChordPro-Format: Akkorde in eckigen Klammern, [Am], und Hinweise wie $example.';
  }

  @override
  String get lyricsHelpCue => 'Ganze Band setzt ein';

  @override
  String get newSection => 'Neuer Abschnitt';

  @override
  String get editSection => 'Abschnitt bearbeiten';

  @override
  String get sectionNameHint => 'Refrain';

  @override
  String get barsLabel => 'Takte';

  @override
  String get between1and999 => 'Zwischen 1 und 999';

  @override
  String get tempoOptional => 'Tempo (optional)';

  @override
  String get tempoOptionalHelp => 'Leer: das Tempo des Songs.';

  @override
  String get useSongMeter => 'Taktart des Songs verwenden';

  @override
  String get songMeter => 'Wie der Song';

  @override
  String get newSetlist => 'Neue Setlist';

  @override
  String get noSetlists =>
      'Noch keine Setlists. Tippe auf +, um eine anzulegen und Songs hinzuzufügen.';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return '$_temp0';
  }

  @override
  String get createSongsFirst => 'Lege zuerst Songs unter Songs an.';

  @override
  String get renameSetlist => 'Setlist umbenennen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get setlistDeleteKeepsSongs => 'Die Songs bleiben erhalten.';

  @override
  String get exportSetlist => 'Setlist exportieren';

  @override
  String get deleteSetlist => 'Setlist löschen';

  @override
  String get autoAdvance => 'Automatisch zum nächsten Song';

  @override
  String get autoAdvanceHelp =>
      'Wenn die Dauer eines Songs vorbei ist, beginnt der nächste genau auf dem Takt. Am Ende der Setlist stoppt es.';

  @override
  String get pauseBetween => 'Pause zwischen Songs';

  @override
  String get pauseBetweenHelp =>
      'Stille Takte im Tempo des nächsten Songs, bevor er beginnt.';

  @override
  String get setlistCountInHelp =>
      'Takte Klick in anderer Tonhöhe vor jedem Song, nach der Pause.';

  @override
  String countInFromSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Einstellungen ($count)',
      zero: 'Einstellungen (aus)',
    );
    return '$_temp0';
  }

  @override
  String noDurationManual(String summary) {
    return '$summary · ohne Dauer: manuell weiter';
  }

  @override
  String get removeFromSetlist => 'Aus der Setlist entfernen';

  @override
  String get addSongs => 'Songs hinzufügen';

  @override
  String addCount(int count) {
    return 'Hinzufügen ($count)';
  }

  @override
  String songsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs importiert.',
      one: '1 Song importiert.',
    );
    return '$_temp0';
  }

  @override
  String filesWithoutSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien ohne Songs.',
      one: '1 Datei ohne Songs.',
    );
    return '$_temp0';
  }

  @override
  String get cannotRead => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get cannotSave => 'Die Datei konnte nicht gespeichert werden.';

  @override
  String savedFile(String file) {
    return 'Gespeichert: $file';
  }

  @override
  String get songsFileName => 'songs';

  @override
  String get notASetlist => 'Diese Datei ist keine PrronClick-Setlist.';

  @override
  String setlistImported(String name) {
    return 'Setlist „$name“ importiert.';
  }

  @override
  String get beatsPerBar => 'Schläge pro Takt';

  @override
  String get beatUnit => 'Notenwert des Schlags';

  @override
  String get meterHelp =>
      'Der Klick ertönt einmal pro Schlag und das Tempo zählt diese Schläge: 6/8 bei 180 BPM spielt 180 Achtel pro Minute.';

  @override
  String useMeter(String meter) {
    return '$meter verwenden';
  }

  @override
  String get chorus => 'Refrain';

  @override
  String get verse => 'Strophe';

  @override
  String get bridge => 'Bridge';

  @override
  String get accentStrong => 'Stark';

  @override
  String get accentMedium => 'Mittel';

  @override
  String get accentNormal => 'Normal';

  @override
  String get accentSilent => 'Stumm';

  @override
  String accentBeat(int beat, String level) {
    return 'Schlag $beat: $level';
  }

  @override
  String get accentsHelp =>
      'Tippe auf einen Schlag, um seine Betonung zu ändern: normal, stark, mittel oder stumm. Auch auf dem Metronom.';

  @override
  String get voiceCount => 'Gesprochener Einzähler';

  @override
  String get voiceCountHelp =>
      'Eine Stimme zählt ein: „eins, zwei, drei, vier“.';

  @override
  String get voiceSections => 'Gesprochene Teile';

  @override
  String get voiceSectionsHelp =>
      'Einen Takt vorher sagt eine Stimme den nächsten Teil an: „Refrain“, „Strophe zwei“.';

  @override
  String get voicesMissing => 'Diese Version hat keine Stimmen.';

  @override
  String get transpose => 'Transponieren';

  @override
  String get transposeDown => 'Halbton tiefer';

  @override
  String get transposeUp => 'Halbton höher';

  @override
  String get saveLeaderSetlist =>
      'Diese Setlist in meiner Bibliothek speichern';
}
