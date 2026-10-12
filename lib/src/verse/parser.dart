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
  bool currentChordsConsumed = false;

  // A chord line that no lyric line followed is itself a chord-only line.
  void addPendingChords() {
    if (currentChords.isEmpty || currentChordsConsumed) return;
    currentVerseParts.add((
      lineIndex: "",
      versePart: parseLineFromSeparate(currentChords, ""),
    ));
  }

  void finalizeTag() {
    addPendingChords();

    // Get unique line indexes
    Set<String> lineIndexes = {};
    lineIndexes.addAll(currentVerseParts.map((e) => e.lineIndex));

    // TODO trim whitespace everywhere?
    for (String lineIndex in lineIndexes) {
      List<VersePart> lines =
          currentVerseParts
              .where((e) => e.lineIndex == lineIndex)
              .map((e) => e.versePart)
              .toList();
      verses.add(
        Verse(currentTagType, int.tryParse(currentTagIndex + lineIndex), lines),
      );
    }

    currentTagType = "";
    currentTagIndex = "";
    currentChords = "";
    currentChordsConsumed = false;
    currentVerseParts = [];
  }

  for (String line in string.split('\n')) {
    // Trim empty lines
    if (line.trim().isEmpty) {
      continue;
    } else if (line.startsWith('.')) {
      addPendingChords();
      // Both leading and trailing whitespace are column offsets that align the
      // chords with the lyric line (see parseLineFromSeparate).
      currentChords = line.substring(1);
      currentChordsConsumed = false;
    }
    //! New tag
    else if (line.startsWith('[')) {
      finalizeTag();

      var typeMatch = RegExp(
        r"[\p{L}]+",
        unicode: true,
      ).firstMatch(line.substring(1));
      currentTagType = typeMatch?[0] ?? "";

      var indexMatch = RegExp(
        r"[0-9]+",
      ).firstMatch(line.substring(1).substring(typeMatch?.end ?? 0));
      currentTagIndex = indexMatch?[0] ?? "";
    }
    //! Comment
    else if (line.startsWith(';')) {
      currentVerseParts.add((
        lineIndex: "",
        versePart: VersePart.comment(line.substring(1).trim()),
      ));
    }
    //! Unhandled line type (printing instructions)
    else if (line.startsWith('-')) {
      currentVerseParts.add((lineIndex: "", versePart: UnsupportedLine(line)));
      //! Lyrics line
    } else {
      String lineIndex = "";

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
          currentVerseParts.add((
            lineIndex: lineIndex,
            versePart: VersePart.newSlide(),
          ));
        } else {
          currentVerseParts.add((
            lineIndex: lineIndex,
            versePart: VersePart.emptyLine(),
          ));
        }
      } else {
        currentVerseParts.add((
          lineIndex: lineIndex,
          versePart: parseLineFromSeparate(currentChords, line.substring(1)),
        ));
        currentChordsConsumed = true;
      }
    }
  }

  finalizeTag();

  return verses;
}

/// Aligns a chord line and a lyric line into [VerseLineSegment]s.
VerseLine parseLineFromSeparate(String chords, String lyrics) {
  final length = chords.length > lyrics.length ? chords.length : lyrics.length;

  // Read the chord and lyric lines together, column by column. A chord token
  // opens a segment and the next one closes it. The first lyric character
  // starts the voice: a chord struck before it is an intro chord that forms its
  // own (chord-only) segment, unless the voice starts in the chord's own column,
  // where the chord keeps the syllable under it.
  List<VerseLineSegment> lineSegments = [];
  VerseLineSegment? current;
  bool voiceStarted = false;

  for (var column = 0; column < length; column++) {
    final startsChord =
        column < chords.length &&
        chords[column] != ' ' &&
        (column == 0 || chords[column - 1] == ' ');

    String? chord;
    if (startsChord) {
      var end = column;
      while (end < chords.length && chords[end] != ' ') {
        end++;
      }
      chord = chords.substring(column, end);
    }

    final character = column < lyrics.length ? lyrics[column] : ' ';

    if (!voiceStarted && character != ' ') {
      if (chord == null &&
          current != null &&
          current.chord != null &&
          current.lyrics.trim().isEmpty) {
        current = null;
      }
      voiceStarted = true;
    }

    if (chord != null) {
      current = VerseLineSegment(chord, '');
      lineSegments.add(current);
    } else if (current == null) {
      current = VerseLineSegment(null, '');
      lineSegments.add(current);
    }

    // '_' is part of the syllable but is not rendered.
    if (character != '_') current.lyrics += character;
  }

  // Get hyphenation and leading spaces in order
  for (var i = 0; i < lineSegments.length; i++) {
    VerseLineSegment segment = lineSegments[i];

    // Cancel hyphen if next has leading space or is end of line
    bool nextCancelsHyphen =
        (lineSegments.length > i + 1)
            ? lineSegments[i + 1].lyrics.startsWith(' ')
            : true;

    if (!segment.lyrics.endsWith(' ') && !nextCancelsHyphen) {
      segment.hyphenAfter = true;
    }

    // Remove leading space from current if previous already has trailing or is empty
    if (i > 0 &&
        (lineSegments[i - 1].lyrics.endsWith(' ') ||
            lineSegments[i - 1].lyrics.isEmpty)) {
      segment.lyrics = segment.lyrics.replaceAll(RegExp(r'^[ ]+'), '');
    }

    // Replace two or more spaces with a single one
    segment.lyrics = segment.lyrics.replaceAll(RegExp(r'[ ]{2,}'), ' ');
    if (segment.lyrics == ' ') segment.lyrics = '';
  }

  // A segment with neither a chord nor lyrics carries no information.
  lineSegments.removeWhere(
    (segment) => segment.chord == null && segment.lyrics.isEmpty,
  );

  if (lineSegments.isNotEmpty) {
    // Trim alignment/padding whitespace from the start and end of the line.
    lineSegments.first.lyrics = _trimAlignmentSpaces(
      lineSegments.first.lyrics,
      trailing: false,
    );
    lineSegments.last.lyrics = _trimAlignmentSpaces(
      lineSegments.last.lyrics,
      leading: false,
    );
  }

  return VerseLine(lineSegments);
}

/// Removes the alignment/padding whitespace from the start and/or end of [text].
String _trimAlignmentSpaces(
  String text, {
  bool leading = true,
  bool trailing = true,
}) {
  var result = text;
  if (leading) result = result.replaceAll(RegExp(r'^[ ]+'), '');
  if (trailing) result = result.replaceAll(RegExp(r'[ ]+$'), '');
  return result;
}
