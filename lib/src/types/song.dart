part '../parser.dart';

class Song {
  List<Verse> verses;

  Song(this.verses);
}

class Verse {
  String? type;
  int? index;

  List<VerseLine> lines;

  Verse(this.type, this.index, this.lines);

  String get lyrics => lines.map((e) => e.lyrics).join("\n");
}

class VerseLine {
  List<LinePart> parts;

  VerseLine(this.parts);

  /// Initializes a Line from a single String without chords.
  VerseLine.justLyrics(String lyrics) : parts = [LinePart.justLyrics(lyrics)];

  String get lyrics => parts.map((e) => e.lyrics).join();
}

class LinePart {
  String? chord;
  String? lyrics;

  LinePart(this.chord, this.lyrics);
  LinePart.justLyrics(this.lyrics);
  LinePart.justChord(this.chord);
}
