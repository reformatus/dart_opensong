/// A parsed OpenSong verse (or section) of a song.
class Verse {
  /// The section type, e.g. `"V"` for a verse or `"C"` for a chorus.
  String type;

  /// The numeric suffix of the section tag, e.g. `1` in `[V1]`.
  ///
  /// `null` when the tag has no number.
  int? index;

  /// The parts (lines) that make up this verse, in reading order.
  List<VersePart> parts;

  /// Creates a verse from its [type], optional [index] and [parts].
  Verse(this.type, this.index, this.parts);

  /// The original section tag, e.g. `"V1"`.
  String get tag => "$type${index ?? ""}";

  /// The plain lyrics of every [VerseLine] in this verse, joined with newlines.
  String get lyrics =>
      parts.whereType<VerseLine>().map((e) => e.lyrics).join("\n");

  /// The number of parts that could not be parsed.
  int get errorCount => parts.whereType<PartWithError>().length;
}

/// A single rendered piece of a [Verse].
sealed class VersePart {
  /// A marker that the following content starts on a new slide.
  factory VersePart.newSlide() => NewSlide();

  /// A blank line.
  factory VersePart.emptyLine() => EmptyLine();

  /// A line of chords and/or lyrics.
  factory VersePart.line(List<VerseLineSegment> parts) => VerseLine(parts);

  /// A comment line.
  factory VersePart.comment(String comment) => CommentLine(comment);
}

/// A line made up of [segments] of chords and lyrics.
class VerseLine implements VersePart {
  /// The segments of this line, in reading order.
  List<VerseLineSegment> segments;

  /// Creates a line from its [segments].
  VerseLine(this.segments);

  /// Initializes a Line from a single String without chords.
  VerseLine.justLyrics(String lyrics)
    : segments = [VerseLineSegment.justLyrics(lyrics)];

  /// The concatenated lyrics of every segment.
  String get lyrics => segments.map((e) => e.lyrics).join();
}

/// A marker that the following content starts on a new slide.
class NewSlide implements VersePart {}

/// A blank line.
class EmptyLine implements VersePart {}

/// A comment line, introduced by `;`.
class CommentLine implements VersePart {
  /// The comment text, without the leading `;`.
  String comment;

  /// Creates a comment line from its [comment] text.
  CommentLine(this.comment);
}

/// A part that could not be parsed and is kept verbatim.
sealed class PartWithError implements VersePart {
  /// The original, unparsed line.
  String original;

  /// Creates an error part from the [original] line.
  PartWithError(this.original);
}

/// A line the parser does not understand, kept verbatim.
class UnsupportedLine extends PartWithError {
  /// Creates an unsupported line from the [original] input.
  UnsupportedLine(super.original);
}

/// A run of lyrics together with the chord played over it.
class VerseLineSegment {
  /// The chord played over [lyrics], or `null` when there is none.
  String? chord;

  /// The lyrics under [chord].
  String lyrics;

  /// Whether a hyphen should be drawn after this segment.
  bool hyphenAfter = false;

  /// Creates a segment from a [chord] and its [lyrics].
  VerseLineSegment(this.chord, this.lyrics);

  /// Creates a segment with lyrics but no chord.
  VerseLineSegment.justLyrics(this.lyrics);

  /// Creates a segment with a chord but no lyrics.
  VerseLineSegment.justChord(this.chord) : lyrics = "";
}
