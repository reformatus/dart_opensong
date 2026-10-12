## 0.0.1

- Initial release of lyrics format parsing

## 0.0.2

#### Lyrics parsing:
- Treat lines with no content except spaces as empty
- Treat all unrecognized lines as lyrics

## 0.0.3

#### Lyrics parsing:
- Add `.hyphenAfter` to `VerseLinePart`s

## 0.0.4
- Trim whitespace from chords and comments

## 0.0.5
#### Lyrics parsing:
- Preserve the leading indentation of chord lines so chords stay aligned over
  their syllables ([#4](https://github.com/reformatus/dart_opensong/issues/4))

## 0.0.6
#### Lyrics parsing:
- Keep all input whitespace while aligning chords and lyrics, and trim only the
  trailing alignment padding from parsed lines

## 0.0.7
#### Lyrics parsing:
- Parse chord and lyric lines together, column by column: a chord struck before
  the singing starts forms its own chord-only segment, and alignment padding at
  the start/end of a line is trimmed
- Drop segments that carry neither a chord nor lyrics

## 0.0.8
#### Lyrics parsing:
- Keep chord lines that are not followed by a lyric line instead of dropping
  them
- Handle CRLF line endings

## 0.0.9
#### Lyrics parsing:
- Skip chord lines that contain only whitespace
- Keep a chord line's reading order relative to comments and unsupported lines
