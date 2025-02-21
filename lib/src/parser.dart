part of 'types/song.dart';

enum SongParseErrorType { unsupportedLineType }

// TODO add legend of what each part of opensong syntax is named
Song parseFromString(String string) {
  List<Verse> verses = [];
  List<(SongParseErrorType type, int? lineNumber, String? offendingLine)> errors = [];

  List<(String, VerseLine)> currentVerseLines = [];
  String currentTagType = "";
  String currentTagIndex = "";

  String currentChords = "";

  void finalizeTag() {
    // Get unique line indexes
    Set<String> lineIndexes = {};
    lineIndexes.addAll(currentVerseLines.map((e) => e.$1));

    for (String lineIndex in lineIndexes) {
      List<VerseLine> lines = currentVerseLines.where((e) => e.$1 == lineIndex).map((e) => e.$2).toList();
      verses.add(Verse(currentTagType, int.tryParse(currentTagIndex + lineIndex), lines));
    }

    currentTagType = "";
    currentTagIndex = "";
    currentChords = "";
    currentVerseLines = [];
  }

  int i = -1;
  String prevLine = "";
  for (String line in string.split('\n')) {
    // Trim empty lines
    if (line.length < 2) continue;

    if (line.startsWith(RegExp(r'[\p{L}0-9 ]', unicode: true))) {
      String lineIndex = "";
      // Lyrics line
      // Add space to beginning of line if missing
      if (!line.startsWith(RegExp(r'[0-9 ]'))) {
        line = ' $line';
      }
      if (line.startsWith(RegExp(r'[0-9]'))) {
        lineIndex = line.substring(0, 1);
      }
      if (line.startsWith('|', 1)) {
        if (line.startsWith('||', 1)) {
          // new slide
          // TODO implement VerseLine superclass with NewSlide line type OR constructor??
        } else {
          VerseLine.justLyrics("");
        }
      } else {
        currentVerseLines.add((lineIndex, parseLineFromSeparate(currentChords, line.substring(1))));
      }
    } else if (line.startsWith('.')) {
      // If we already had current chords, then add them as a line without lyrics (Vamp)
      if (prevLine.startsWith('.')) {
        currentVerseLines.add(("", parseLineFromSeparate(currentChords, "")));
      }
      currentChords = line.substring(1);
    } else if (line.startsWith('[')) {
      finalizeTag();

      var typeMatch = RegExp(r"[\p{L}]+", unicode: true).firstMatch(line.substring(1));
      currentTagType = typeMatch?[0] ?? "";

      var indexMatch = RegExp(r"[0-9]+").firstMatch(line.substring(1).substring(typeMatch?.end ?? 0));
      currentTagIndex = indexMatch?[0] ?? "";
    } else {
      errors.add((SongParseErrorType.unsupportedLineType, i, line));
    }

    prevLine = "$line";
    i++;
  }

  // TODO This adds redundant last chords line when not necessary - fix pls
  finalizeTag();

  return Song(verses);
}

VerseLine parseLineFromSeparate(String chords, String lyrics) {
  List<LinePart> lineParts = [];
  var chordMatches = RegExp(r'[^ ]+').allMatches(chords).toList();

  if (chordMatches.isEmpty) {
    return VerseLine.justLyrics(lyrics);
  }

  for (var i = 0; i < chordMatches.length; i++) {
    int start = chordMatches[i].start;
    if (start >= lyrics.length) {
      lineParts.add(LinePart.justChord(chordMatches[i][0]));
      continue;
    }

    int end = lyrics.length;
    if (i < chordMatches.length - 1) {
      end = chordMatches[i + 1].start;
      if (end > lyrics.length) {
        end = lyrics.length;
      }
    }

    lineParts.add(LinePart(chordMatches[i][0], lyrics.substring(start, end).replaceAll('_', '')));
  }

  return VerseLine(lineParts);
}
