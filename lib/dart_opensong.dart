// @Projekt https://dart.dev/tools/pub/create-packages

/// This package provides partial support for reading/writing [OpenSong](https://opensong.org/development/file-formats/) Song files.
/// *Still under early development. Expect breaking changes until 1.0 is released.*
library;

export 'src/song/song.dart';
export 'src/verse/verse.dart';
export 'src/verse/parser.dart' show getVersesFromString;
