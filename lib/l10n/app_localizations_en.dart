// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get audioFailed => 'Could not open the audio output.';

  @override
  String get tabMetronome => 'Metronome';

  @override
  String get tabSongs => 'Songs';

  @override
  String get tabSetlists => 'Setlists';

  @override
  String get importExport => 'Import or export';

  @override
  String get importSongs => 'Import songs';

  @override
  String get exportSongs => 'Export songs';

  @override
  String get importSetlist => 'Import setlist';

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get no => 'Off';

  @override
  String get name => 'Name';

  @override
  String get meter => 'Time signature';

  @override
  String get countIn => 'Count-in';

  @override
  String bars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bars',
      one: '1 bar',
    );
    return '$_temp0';
  }

  @override
  String inBars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count bars',
      one: 'next bar',
    );
    return '$_temp0';
  }

  @override
  String get followerNoTempo => 'As a follower, the leader sets the tempo.';

  @override
  String deleteQuestion(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get between20and300 => 'Between 20 and 300';

  @override
  String get nameRequired => 'Give it a name';

  @override
  String comingUpSection(String section, String when) {
    return 'Next: $section $when';
  }

  @override
  String leaderPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Leader · $count connected',
      one: 'Leader · 1 connected',
    );
    return '$_temp0';
  }

  @override
  String get searchingLeader => 'Looking for the leader…';

  @override
  String get followingLeader => 'Following the leader';

  @override
  String get statusPause => 'Pause';

  @override
  String get statusSilence => 'Silent';

  @override
  String get tempoDown => 'Tempo down';

  @override
  String get tempoUp => 'Tempo up';

  @override
  String get tapTempo => 'Tap tempo';

  @override
  String get stop => 'Stop';

  @override
  String get start => 'Start';

  @override
  String get lyrics => 'Lyrics';

  @override
  String setlistEnds(String when) {
    return 'Ends $when';
  }

  @override
  String setlistNextIn(String song, String when) {
    return '\"$song\" starts $when';
  }

  @override
  String get lastSong => 'Last song';

  @override
  String nextSong(String song) {
    return 'Next: $song';
  }

  @override
  String get previousSongTooltip => 'Previous song';

  @override
  String get nextSongTooltip => 'Next song';

  @override
  String get leaveSetlist => 'Leave setlist';

  @override
  String get tools => 'Tools';

  @override
  String get shareClick => 'Share the click';

  @override
  String get modeSolo => 'Solo';

  @override
  String get modeLeader => 'Leader';

  @override
  String get modeFollower => 'Follower';

  @override
  String get myClick => 'My click';

  @override
  String get myClickHelp => 'This device only: each musician sets their own.';

  @override
  String get subdivision => 'Subdivision';

  @override
  String get volume => 'Volume';

  @override
  String get sound => 'Sound';

  @override
  String get soundBeep => 'Beep';

  @override
  String get soundWood => 'Wood';

  @override
  String get soundDigital => 'Digital';

  @override
  String get displacedClick => 'Displaced click';

  @override
  String displacedNow(String step) {
    return 'Now on: $step';
  }

  @override
  String everyBars(int count) {
    return 'Every $count';
  }

  @override
  String get displacedHelp =>
      'Moves a sixteenth note every 2 or 3 bars: 1, e, &, a.';

  @override
  String get gapTrainer => 'Gap trainer';

  @override
  String get gapTrainerHelp =>
      'The click plays for a few bars, then goes silent.';

  @override
  String get barsWithClick => 'Bars with click';

  @override
  String get barsSilent => 'Silent bars';

  @override
  String get tempoRamp => 'Tempo ramp';

  @override
  String get tempoRampHelp =>
      'The tempo goes up every few bars. Stopping brings it back to the start.';

  @override
  String get rampUpBpm => 'Raise (BPM)';

  @override
  String get rampEveryBars => 'Every (bars)';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get practiceTools => 'Practice tools';

  @override
  String get practiceToolsHelp =>
      'Shows the displaced click and the gap trainer in the Tools panel.';

  @override
  String get countInHelp =>
      'Bars of click at another pitch before each song. As a Follower you hear the leader\'s count-in.';

  @override
  String get flash => 'Screen flash';

  @override
  String get flashHelp =>
      'The metronome flashes on each beat. Above 180 BPM, only on the first beat of the bar.';

  @override
  String get flashCountIn => 'Flash during the count-in';

  @override
  String get flashCountInHelp =>
      'Whether it flashes during the count-in, whatever the beat flash is set to.';

  @override
  String get sessionCode => 'Session code';

  @override
  String sessionCodeIs(String code) {
    return 'Session code: $code';
  }

  @override
  String get sessionCodeOffHelp =>
      'No code: standard Link, works with Ableton Live and other apps. Set one if another band is on the same network.';

  @override
  String get sessionCodeOnHelp =>
      'Only devices with this same code share a click. Ableton Live and other Link apps won\'t see you until you remove it.';

  @override
  String get sessionCodeReset => 'Remove code (back to standard Link)';

  @override
  String get sessionCodeLabel => 'The same for the whole band';

  @override
  String latencyAdjust(int ms) {
    return 'Latency offset: $ms ms';
  }

  @override
  String get latencyHelp =>
      'Raise it if your click sounds late compared to the others (e.g. with Bluetooth headphones), or calibrate it below.';

  @override
  String latencyCompensated(String ms) {
    return 'Output latency already compensated: $ms ms';
  }

  @override
  String get calibrate => 'Calibrate with the leader';

  @override
  String get calibrateListening =>
      'Listening… don\'t touch anything for 8 seconds.';

  @override
  String get calibrateHelp =>
      'With this device as a Follower and the leader playing nearby, the microphone listens to both clicks and sets the latency. Works best with no other followers playing and at a moderate tempo.';

  @override
  String get calibrateAligned => 'You were already in time with the leader.';

  @override
  String calibrateLate(int ms) {
    return 'You were $ms ms late.';
  }

  @override
  String calibrateEarly(int ms) {
    return 'You were $ms ms early.';
  }

  @override
  String get calibrateFixed => 'Offset corrected.';

  @override
  String calibrateLimit(int ms) {
    return 'The offset hit its limit ($ms ms); check this device\'s audio output.';
  }

  @override
  String get calibrateNotFollowing =>
      'Switch to Follower with the leader playing.';

  @override
  String get calibrateNoPermission => 'Microphone permission is needed.';

  @override
  String get calibrateMicFailed => 'Could not open the microphone.';

  @override
  String get calibrateNotHeard =>
      'Couldn\'t hear both clicks clearly. Move closer to the leader, turn the volume up, let only the leader play (no displaced click) and try again.';

  @override
  String get cannotUndo => 'This can\'t be undone.';

  @override
  String get newSong => 'New song';

  @override
  String get editSong => 'Edit song';

  @override
  String get noSongs =>
      'No songs yet. Tap + to create one with its tempo, time signature and length.';

  @override
  String get options => 'Options';

  @override
  String get searchSong => 'Search songs';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noMatch => 'No songs match.';

  @override
  String get tempoBpm => 'Tempo (BPM)';

  @override
  String get durationOptional => 'Length (optional)';

  @override
  String get durationHelp =>
      'Minutes:seconds. In a setlist, the next song starts when it ends.';

  @override
  String get durationInvalid => 'Use minutes:seconds, e.g. 3:30';

  @override
  String get sectionsOptional => 'Sections (optional)';

  @override
  String get sectionsHelp =>
      'Parts with their bars and, if you like, their own tempo and time signature. They play in order and add up to the song\'s length.';

  @override
  String get moveUp => 'Move up';

  @override
  String get removeSection => 'Remove section';

  @override
  String get keyOptional => 'Key (optional)';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHint => 'Drums come in alone';

  @override
  String get noteHelp => 'Shown on the metronome, followers too.';

  @override
  String get lyricsOptional => 'Lyrics (optional)';

  @override
  String lyricsHelp(String example) {
    return 'ChordPro format: chords in brackets, [Am], and cues like $example.';
  }

  @override
  String get lyricsHelpCue => 'Whole band in';

  @override
  String get newSection => 'New section';

  @override
  String get editSection => 'Edit section';

  @override
  String get sectionNameHint => 'Chorus';

  @override
  String get barsLabel => 'Bars';

  @override
  String get between1and999 => 'Between 1 and 999';

  @override
  String get tempoOptional => 'Tempo (optional)';

  @override
  String get tempoOptionalHelp => 'Empty: the song\'s tempo.';

  @override
  String get useSongMeter => 'Use the song\'s time signature';

  @override
  String get songMeter => 'The song\'s';

  @override
  String get newSetlist => 'New setlist';

  @override
  String get noSetlists =>
      'No setlists yet. Tap + to create one and add songs to it.';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get createSongsFirst => 'Create some songs in Songs first.';

  @override
  String get renameSetlist => 'Rename setlist';

  @override
  String get rename => 'Rename';

  @override
  String get setlistDeleteKeepsSongs => 'The songs are kept.';

  @override
  String get exportSetlist => 'Export setlist';

  @override
  String get deleteSetlist => 'Delete setlist';

  @override
  String get autoAdvance => 'Go to the next song automatically';

  @override
  String get autoAdvanceHelp =>
      'When a song\'s length is up, the next one starts right on the bar. At the end of the setlist, it stops.';

  @override
  String get pauseBetween => 'Pause between songs';

  @override
  String get pauseBetweenHelp =>
      'Silent bars, at the next song\'s tempo, before it starts.';

  @override
  String get setlistCountInHelp =>
      'Bars of click at another pitch before each song, after the pause.';

  @override
  String countInFromSettings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Settings ($count)',
      zero: 'Settings (off)',
    );
    return '$_temp0';
  }

  @override
  String noDurationManual(String summary) {
    return '$summary · no length: move on by hand';
  }

  @override
  String get removeFromSetlist => 'Remove from setlist';

  @override
  String get addSongs => 'Add songs';

  @override
  String addCount(int count) {
    return 'Add ($count)';
  }

  @override
  String songsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs imported.',
      one: '1 song imported.',
    );
    return '$_temp0';
  }

  @override
  String filesWithoutSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files had no songs.',
      one: '1 file had no songs.',
    );
    return '$_temp0';
  }

  @override
  String get cannotRead => 'Could not read the file.';

  @override
  String get cannotSave => 'Could not save the file.';

  @override
  String savedFile(String file) {
    return 'Saved: $file';
  }

  @override
  String get songsFileName => 'songs';

  @override
  String get notASetlist => 'That file isn\'t a PrronClick setlist.';

  @override
  String setlistImported(String name) {
    return 'Setlist \"$name\" imported.';
  }

  @override
  String get beatsPerBar => 'Beats per bar';

  @override
  String get beatUnit => 'Beat unit';

  @override
  String get meterHelp =>
      'The click sounds once per beat and the tempo counts those beats: 6/8 at 180 BPM plays 180 eighth notes a minute.';

  @override
  String useMeter(String meter) {
    return 'Use $meter';
  }

  @override
  String get chorus => 'Chorus';

  @override
  String get verse => 'Verse';

  @override
  String get bridge => 'Bridge';

  @override
  String get accentStrong => 'Strong';

  @override
  String get accentMedium => 'Medium';

  @override
  String get accentNormal => 'Normal';

  @override
  String get accentSilent => 'Silent';

  @override
  String accentBeat(int beat, String level) {
    return 'Beat $beat: $level';
  }

  @override
  String get accentsHelp =>
      'Tap a beat to change its accent: normal, strong, medium or silent. Also on the metronome.';

  @override
  String get voiceCount => 'Spoken count-in';

  @override
  String get voiceCountHelp =>
      'A voice counts the count-in: “one, two, three, four”.';

  @override
  String get voiceSections => 'Spoken sections';

  @override
  String get voiceSectionsHelp =>
      'A bar ahead, a voice names the next section: “Chorus”, “Verse two”.';

  @override
  String get voicesMissing => 'This version has no voices.';

  @override
  String get transpose => 'Transpose';

  @override
  String get transposeDown => 'Half step down';

  @override
  String get transposeUp => 'Half step up';

  @override
  String get saveLeaderSetlist => 'Save this setlist to my library';

  @override
  String get history => 'Practice history';

  @override
  String get historyNoSong => 'No song';

  @override
  String get historyEmpty =>
      'No practice yet. Each time the click plays for at least 10 seconds, it is noted here.';

  @override
  String historyTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String historyBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String historyTempo(int first, int last, int best) {
    return '$first → $last BPM (best $best)';
  }

  @override
  String get historyClear => 'Clear history';

  @override
  String get historyClearAsk =>
      'Clear the whole practice history? This cannot be undone.';

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
  String get historyRangeDay => 'Day';

  @override
  String get historyRangeWeek => 'Week';

  @override
  String get historyRangeMonth => 'Month';

  @override
  String get historyPrevious => 'Previous';

  @override
  String get historyNext => 'Next';

  @override
  String get historyWholePeriod => 'Show the whole period';

  @override
  String get historyTime => 'Time';

  @override
  String get historySessionsLabel => 'Sessions';

  @override
  String get historyDaysLabel => 'Days practised';

  @override
  String get historyLongest => 'Longest session';

  @override
  String get historyStreak => 'Streak';

  @override
  String historyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String historyVsPrevDay(String change) {
    return '$change vs. the day before';
  }

  @override
  String historyVsPrevWeek(String change) {
    return '$change vs. the week before';
  }

  @override
  String historyVsPrevMonth(String change) {
    return '$change vs. the month before';
  }

  @override
  String get historyTapHour => 'Tap a bar to see that hour.';

  @override
  String get historyTapDay => 'Tap a day to see only that day.';

  @override
  String historyMax(String time) {
    return 'max. $time';
  }

  @override
  String get historySongs => 'Songs';

  @override
  String get historyTools => 'Tools';

  @override
  String get historyNoTools => 'Without tools';

  @override
  String get historyNothing => 'Nothing in this period.';

  @override
  String get historyBestBpm => 'Best tempo';

  @override
  String get historyTempoChange => 'Tempo change';

  @override
  String get historyTempoPerSession => 'Tempo per session';

  @override
  String get historyTapPoint =>
      'Tap or slide on the chart to see each session.';

  @override
  String get backupSave => 'Save a backup';

  @override
  String get backupSaveHelp =>
      'Songs, setlists, settings and practice history in one file.';

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreHelp =>
      'Replaces everything with a file saved before, on this or another device.';

  @override
  String get backupRestoreAsk => 'Replace everything?';

  @override
  String backupRestoreWhat(int songs, int setlists) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      setlists,
      locale: localeName,
      other: '$setlists setlists',
      one: '1 setlist',
    );
    return 'Your songs, setlists, settings and history are replaced by the file\'s: $_temp0 and $_temp1.';
  }

  @override
  String get backupReplace => 'Replace';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String get notABackup => 'That file is not a PrronClick backup.';

  @override
  String get undo => 'Undo';

  @override
  String get vibrate => 'Vibrate on the beat';

  @override
  String get vibrateHelp =>
      'The phone vibrates on each beat that sounds, harder on accents. Works with the screen off.';

  @override
  String get vibrateDownbeat => 'Vibrate only on 1';

  @override
  String get vibrateDownbeatHelp => 'Only on the first beat of each bar.';

  @override
  String get rampMaxBpm => 'Up to (BPM)';

  @override
  String get rampNoMax => 'No limit';

  @override
  String get rampMaxDown => 'Lower the top tempo';

  @override
  String get rampMaxUp => 'Raise the top tempo';

  @override
  String get rampMaxStep => '− and + buttons step (BPM)';
}
