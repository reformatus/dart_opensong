import '../verse/verse.dart';

enum SongParseErrorType { unsupportedLineType }

class Song {
  List<Verse> verses;
  // TODO Other fields
  // TODO Styles, verse styles, etc

  // TODO File reader, xml parser

  Song(this.verses);
}