import 'verse.dart';

/// Parses chords and lyrics to verses. Returns a List of Verses and a List of errors encountered to display for the user.

// Explanation of parsing variables below:
//[V] <- tag
//.C  D    Hmsus4add9 Ab <- chords
//1This is a ver______se <- verse lines
//2<- line indexes
//[P1] <- "P" tagType; "1" tagIndex
// This is the pre-chorus
List<Verse> getVersesFromString(String string) {
  List<Verse> verses = [];

  List<({String lineIndex, VersePart versePart})> currentVerseParts = [];
  String currentTagType = "";
  String currentTagIndex = "";

  String currentChords = "";

  void finalizeTag() {
    // Get unique line indexes
    Set<String> lineIndexes = {};
    lineIndexes.addAll(currentVerseParts.map((e) => e.lineIndex));

    if (lineIndexes.isEmpty && currentChords.isNotEmpty) {
      verses.add(
        Verse(currentTagType, int.tryParse(currentTagIndex), [parseLineFromSeparate(currentChords, "")]),
      );
    } else {
      // TODO trim whitespace everywhere?
      for (String lineIndex in lineIndexes) {
        List<VersePart> lines =
            currentVerseParts.where((e) => e.lineIndex == lineIndex).map((e) => e.versePart).toList();
        verses.add(Verse(currentTagType, int.tryParse(currentTagIndex + lineIndex), lines));
      }
    }
    currentTagType = "";
    currentTagIndex = "";
    currentChords = "";
    currentVerseParts = [];
  }

  String prevLine = "";
  for (String line in string.split('\n')) {
    // Trim empty lines
    if (line.length < 2) continue;

    if (line.startsWith(RegExp(r'[\p{L}0-9 ]', unicode: true))) {
      String lineIndex = "";

      //! Lyrics line
      // Add space to beginning of line if missing
      if (!line.startsWith(RegExp(r'[0-9 ]'))) {
        line = ' $line';
      }
      if (line.startsWith(RegExp(r'[0-9]'))) {
        lineIndex = line.substring(0, 1);
      }
      // Presentation markers
      if (line.startsWith('|', 1)) {
        if (line.startsWith('||', 1)) {
          currentVerseParts.add((lineIndex: lineIndex, versePart: VersePart.newSlide()));
        } else {
          currentVerseParts.add((lineIndex: lineIndex, versePart: VersePart.emptyLine()));
        }
      } else {
        currentVerseParts.add((
          lineIndex: lineIndex,
          versePart: parseLineFromSeparate(currentChords, line.substring(1)),
        ));
      }
    }
    //! Chords line
    else if (line.startsWith('.')) {
      // If we already had current chords, then add them as a line without lyrics (Vamp)
      if (prevLine.startsWith('.')) {
        currentVerseParts.add((lineIndex: "", versePart: parseLineFromSeparate(currentChords, "")));
      }
      currentChords = line.substring(1);
    }
    //! New tag
    else if (line.startsWith('[')) {
      finalizeTag();

      var typeMatch = RegExp(r"[\p{L}]+", unicode: true).firstMatch(line.substring(1));
      currentTagType = typeMatch?[0] ?? "";

      var indexMatch = RegExp(r"[0-9]+").firstMatch(line.substring(1).substring(typeMatch?.end ?? 0));
      currentTagIndex = indexMatch?[0] ?? "";
    }
    //! Comment
    else if (line.startsWith(';')) {
      currentVerseParts.add((lineIndex: "", versePart: VersePart.comment(line.substring(1))));
    }
    //! Unhandled line type (printing instructions)
    else {
      currentVerseParts.add((lineIndex: "", versePart: UnsupportedLine(line)));
    }

    prevLine = line;
  }

  finalizeTag();

  return verses;
}

VerseLine parseLineFromSeparate(String chords, String lyrics) {
  lyrics = lyrics.padRight(chords.length);

  List<VerseLineSegment> lineSegments = [];
  List<({int start, String? chord})> chordMatches =
      RegExp(r'[^ ]+').allMatches(chords).map((e) => (start: e.start, chord: e[0])).toList();

  if (chordMatches.isEmpty) {
    return VerseLine.justLyrics(lyrics);
  }

  if (chordMatches[0].start != 0) {
    chordMatches.insert(0, (start: 0, chord: null));
  }

  for (var i = 0; i < chordMatches.length; i++) {
    int start = chordMatches[i].start;
    if (start >= lyrics.length) {
      lineSegments.add(VerseLineSegment.justChord(chordMatches[i].chord));
      continue;
    }

    int end = lyrics.length;
    if (i < chordMatches.length - 1) {
      end = chordMatches[i + 1].start;
      if (end > lyrics.length) {
        end = lyrics.length;
      }
    }

    var resultLyrics = lyrics.substring(start, end);

    // Remove chord alignment padding
    resultLyrics = resultLyrics.replaceAll('_', '');

    lineSegments.add(VerseLineSegment(chordMatches[i].chord, resultLyrics));
  }

  // Get hyphenation and leading spaces in order
  for (var i = 0; i < lineSegments.length; i++) {
    VerseLineSegment current = lineSegments[i];

    // Cancel hyphen if next has leading space or is end of line
    bool nextCancelsHyphen =
        (lineSegments.length > i + 1) ? lineSegments[i + 1].lyrics.startsWith(' ') : true;

    if (!current.lyrics.endsWith(' ') && !nextCancelsHyphen) current.hyphenAfter = true;

    // Remove leading space from current if previous already has trailing or is empty
    if (i > 0 && (lineSegments[i - 1].lyrics.endsWith(' ') || lineSegments[i - 1].lyrics.isEmpty)) {
      current.lyrics = current.lyrics.replaceAll(RegExp(r'^[ ]+', multiLine: true), '');
    }

    // Replace two or more spaces with a single one
    current.lyrics = current.lyrics.replaceAll(RegExp(r'[ ]{2,}'), ' ');
    if (current.lyrics == ' ') current.lyrics = '';
  }

  // Clean up trailing spaces from last
  lineSegments.last.lyrics = lineSegments.last.lyrics.replaceAll(RegExp(r'[ ]+$', multiLine: true), '');

  return VerseLine(lineSegments);
}
