import '../verse/verse.dart';

/// An OpenSong song.
class Song {
  /// The verses of the song, in reading order.
  List<Verse> verses;

  // TODO Other fields
  // TODO Styles, verse styles, etc

  // TODO File reader, xml parser

  /// Creates a song from its [verses].
  Song(this.verses);
}
