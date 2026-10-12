## 0.0.1

- Initial release of lyrics format parsing

## 0.0.2

#### Lyrics parsing:
- Treat lines with no content except spaces as empty
- Treat all unrecognized lines as lyrics

## 0.0.3

#### Lyrics parsing:
- Add `.hyphenAfter` to `VerseLinePart`s

## 0.0.6
#### Lyrics parsing:
- Keep all input whitespace while aligning chords and lyrics, and trim only the
  trailing alignment padding from parsed lines

## 0.0.5
#### Lyrics parsing:
- Preserve the leading indentation of chord lines so chords stay aligned over
  their syllables ([#4](https://github.com/reformatus/dart_opensong/issues/4))

## 0.0.4
- Trim whitespace from chords and comments