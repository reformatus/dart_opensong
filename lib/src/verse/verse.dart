class Verse {
  String type;
  int? index;

  List<VersePart> parts;

  Verse(this.type, this.index, this.parts);

  String get tag => "$type${index ?? ""}";
  String get lyrics => parts.whereType<VerseLine>().map((e) => e.lyrics).join("\n");
  int get errorCount => parts.whereType<PartWithError>().length;
}

sealed class VersePart {
  factory VersePart.newSlide() => NewSlide();
  factory VersePart.emptyLine() => EmptyLine();
  factory VersePart.line(List<VerseLineSegment> parts) => VerseLine(parts);
  factory VersePart.comment(String comment) => CommentLine(comment);
}

class VerseLine implements VersePart {
  List<VerseLineSegment> segments;

  VerseLine(this.segments);

  /// Initializes a Line from a single String without chords.
  VerseLine.justLyrics(String lyrics) : segments = [VerseLineSegment.justLyrics(lyrics)];

  String get lyrics => segments.map((e) => e.lyrics).join();
}

class NewSlide implements VersePart {}

class EmptyLine implements VersePart {}

class CommentLine implements VersePart {
  String comment;

  CommentLine(this.comment);
}

sealed class PartWithError implements VersePart {
  String original;
  PartWithError(this.original);
}

class UnsupportedLine extends PartWithError {
  UnsupportedLine(super.original);
}

class VerseLineSegment {
  String? chord;
  String lyrics;

  VerseLineSegment(this.chord, this.lyrics);
  VerseLineSegment.justLyrics(this.lyrics);
  VerseLineSegment.justChord(this.chord) : lyrics = "";
}
