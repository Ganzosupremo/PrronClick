# SPDX-License-Identifier: GPL-3.0-or-later
# PLACEHOLDER voice cues for development, spoken by the Windows voices
# installed on this PC. Their license does not allow shipping them: the files
# are git-ignored and must be replaced by real recordings before any release.
#   powershell -ExecutionPolicy Bypass -File tool/make_placeholder_voices.ps1
# The words and file names match cueWords in lib/cues.dart.
Add-Type -AssemblyName System.Speech

$words = [ordered]@{
  es = @('uno','dos','tres','cuatro','cinco','seis','siete','ocho',
         'Intro','Verso','Precoro','Coro','Puente','Instrumental','Solo',
         'Interludio','Outro','Final','Breakdown','Tag')
  en = @('one','two','three','four','five','six','seven','eight',
         'Intro','Verse','Pre-chorus','Chorus','Bridge','Instrumental','Solo',
         'Interlude','Outro','Ending','Breakdown','Tag')
  # "f$([char]0xFC)nf" = fünf: Windows PowerShell reads this file as ANSI.
  de = @('eins','zwei','drei','vier',"f$([char]0xFC)nf",'sechs','sieben','acht',
         'Intro','Strophe','Pre-Chorus','Refrain','Bridge','Instrumental','Solo',
         'Zwischenspiel','Outro','Schluss','Breakdown','Tag')
}
$files = @('1','2','3','4','5','6','7','8',
           'intro','verse','pre_chorus','chorus','bridge','instrumental','solo',
           'interlude','outro','ending','breakdown','tag')

$root = Join-Path $PSScriptRoot '..\assets\voices'
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$installed = $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo }
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050,
  [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,
  [System.Speech.AudioFormat.AudioChannel]::Mono)

foreach ($lang in $words.Keys) {
  $voice = $installed | Where-Object { $_.Culture.TwoLetterISOLanguageName -eq $lang } |
    Select-Object -First 1
  if (-not $voice) {
    # No voice for this language here: an English one reads the words.
    $voice = $installed | Where-Object { $_.Culture.TwoLetterISOLanguageName -eq 'en' } |
      Select-Object -Last 1
    Write-Warning "no $lang voice installed; using $($voice.Name)"
  }
  $synth.SelectVoice($voice.Name)
  $synth.Rate = 2  # cues are short and fast
  $dir = Join-Path $root $lang
  New-Item -ItemType Directory -Force $dir | Out-Null
  for ($i = 0; $i -lt $files.Count; $i++) {
    $synth.SetOutputToWaveFile((Join-Path $dir "$($files[$i]).wav"), $format)
    $synth.Speak($words[$lang][$i])
  }
  $synth.SetOutputToNull()
  Write-Output "$lang : $($files.Count) cues, voice $($voice.Name)"
}
$synth.Dispose()
