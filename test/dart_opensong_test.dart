import 'package:dart_opensong/dart_opensong.dart';
import 'package:test/test.dart';

/// The chords of every segment in [input], in order (`null` for chord-less).
List<String?> _chordsOf(String input) =>
    getVersesFromString(input)
        .expand((verse) => verse.parts)
        .whereType<VerseLine>()
        .expand((line) => line.segments)
        .map((segment) => segment.chord)
        .toList();

void main() {
  group('Validate lyrics parsing for', () {
    test('Basic tags', () {
      var verses = getVersesFromString("""
[V1]
 First Verse
 With two lines
[C]
 Chorus!
""");
      expect(verses.every((e) => e.errorCount == 0), isTrue);

      expect(verses, hasLength(2));
      expect(verses[0].tag, equals("V1"));
      expect(verses[0].parts, hasLength(2));
      expect(verses[1].tag, equals("C"));
    });

    test('Multi-index tags with chords', () {
      var verses = getVersesFromString("""
[V]
.C   Gsus4add9 A# C
1abcdefghij____k
2ijklmnopqr____s
.B A C H
1hello
2hello
[P]
.B A C# H B
[T1]
.B A C# H B
     Text that starts later
[T2]
.    B A C#   H        B
 Chord_s that  start   later
[T3]
.C     D     E    F G E/H C     D
 Multi-chord word se______paration
 Multi-chord              space
[T4]
.C   D       E        G    H
 Non-standard    chord placement
""");
      expect(verses.every((e) => e.errorCount == 0), isTrue);
      expect(verses, hasLength(7));

      expect(verses[0].tag, equals("V1"));
      expect(verses[0].parts, hasLength(2));
      expect(verses[0].parts[0], TypeMatcher<VerseLine>());
      expect((verses[0].parts[0] as VerseLine).segments, hasLength(4));
      expect((verses[0].parts[0] as VerseLine).segments[0].chord, equals("C"));
      expect(
        (verses[0].parts[0] as VerseLine).segments[0].lyrics,
        equals("abcd"),
      );
      expect((verses[0].parts[0] as VerseLine).segments[2].chord, equals("A#"));
      expect(
        (verses[0].parts[0] as VerseLine).segments[2].lyrics,
        equals("k "),
      );
      expect((verses[0].parts[0] as VerseLine).segments[3].chord, equals("C"));
      expect((verses[0].parts[0] as VerseLine).segments[3].lyrics, isEmpty);
      expect((verses[0].parts[0] as VerseLine).lyrics, equals("abcdefghijk "));
      expect((verses[0].parts[1] as VerseLine).lyrics, equals("hello "));

      expect(verses[1].tag, equals("V2"));
      expect(verses[1].parts, hasLength(2));
      expect(verses[1].parts[0], TypeMatcher<VerseLine>());
      expect((verses[1].parts[0] as VerseLine).segments, hasLength(4));
      expect((verses[1].parts[0] as VerseLine).segments[0].chord, equals("C"));
      expect(
        (verses[1].parts[0] as VerseLine).segments[0].lyrics,
        equals("ijkl"),
      );
      expect((verses[1].parts[0] as VerseLine).segments[2].chord, equals("A#"));
      expect(
        (verses[1].parts[0] as VerseLine).segments[2].lyrics,
        equals("s "),
      );
      expect((verses[1].parts[0] as VerseLine).segments[3].chord, equals("C"));
      expect((verses[1].parts[0] as VerseLine).segments[3].lyrics, isEmpty);
      expect((verses[1].parts[0] as VerseLine).lyrics, equals("ijklmnopqrs "));
      expect((verses[1].parts[1] as VerseLine).lyrics, equals("hello "));

      expect((verses[2].parts[0] as VerseLine).segments, hasLength(5));
      expect(verses[2].lyrics, isEmpty);

      expect((verses[5].parts[0] as VerseLine).segments[3].hyphenAfter, isTrue);
      expect((verses[5].parts[0] as VerseLine).segments[4].hyphenAfter, isTrue);
      expect((verses[5].parts[0] as VerseLine).segments[5].hyphenAfter, isTrue);

      expect(
        (verses[5].parts[1] as VerseLine).segments[3].hyphenAfter,
        isFalse,
      );
      expect(
        (verses[5].parts[1] as VerseLine).segments[4].hyphenAfter,
        isFalse,
      );
      expect(
        (verses[5].parts[1] as VerseLine).segments[5].hyphenAfter,
        isFalse,
      );

      expect(
        (verses[6].parts[0] as VerseLine).segments[2].hyphenAfter,
        isFalse,
      );
      expect((verses[6].parts[0] as VerseLine).segments[3].hyphenAfter, isTrue);
    });

    test('Non-standard tag definitions', () {
      var verses = getVersesFromString("""
 Test0
[]
 Test1
[1]
 Test2
[Árvíztűrő1]
 Test3
[Árvíztűrő 1]
 Test4
""");

      expect(verses.every((e) => e.errorCount == 0), isTrue);
      expect(verses, hasLength(5));

      expect(verses[0].type, isEmpty);
      expect(verses[0].index, isNull);
      expect((verses[0].parts[0] as VerseLine).lyrics, equals("Test0"));

      expect(verses[1].type, isEmpty);
      expect(verses[1].index, isNull);
      expect((verses[1].parts[0] as VerseLine).lyrics, equals("Test1"));

      expect(verses[2].type, isEmpty);
      expect(verses[2].index, equals(1));
      expect((verses[2].parts[0] as VerseLine).lyrics, equals("Test2"));

      expect(verses[3].type, equals("Árvíztűrő"));
      expect(verses[3].index, equals(1));
      expect((verses[3].parts[0] as VerseLine).lyrics, equals("Test3"));

      expect(verses[4].type, equals("Árvíztűrő"));
      expect(verses[4].index, equals(1));
      expect((verses[4].parts[0] as VerseLine).lyrics, equals("Test4"));
    });

    test('Leading indentation of chord lines is preserved', () {
      // Regression test for
      // https://github.com/reformatus/dart_opensong/issues/4
      // The whitespace between the leading '.' and the first chord is a
      // meaningful column offset, so it must not be trimmed away.
      var verses = getVersesFromString("""
[Verze]
.        G               D
 Megáldott az Úr a házamtelekén,
.      Em            C           G
 ki félte őtet szívvel és lélekkel.
""");
      expect(verses, hasLength(1));
      expect(verses[0].parts, hasLength(2));

      // First chord line has an 8-column offset, so the line starts with a
      // chord-less prefix and G lands at column 8.
      var firstLine = verses[0].parts[0] as VerseLine;
      expect(firstLine.segments.first.chord, isNull);
      expect(firstLine.segments.first.lyrics, equals("Megáldot"));
      expect(firstLine.segments[1].chord, equals("G"));
      expect(firstLine.lyrics, equals("Megáldott az Úr a házamtelekén,"));

      // Second chord line has a 6-column offset.
      var secondLine = verses[0].parts[1] as VerseLine;
      expect(secondLine.segments.first.chord, isNull);
      expect(secondLine.segments.first.lyrics, equals("ki fél"));
      expect(secondLine.segments[1].chord, equals("Em"));
      expect(secondLine.lyrics, equals("ki félte őtet szívvel és lélekkel."));
    });

    test('Leading gap between the first chord and the first syllable', () {
      // A chord strummed before the singing starts forms its own chord-only
      // segment, followed by the lyric segment.
      var verses = getVersesFromString("""
[V]
.C
   Hello
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.segments, hasLength(2));
      expect(line.segments[0].chord, equals("C"));
      expect(line.segments[0].lyrics, isEmpty);
      expect(line.segments[1].chord, isNull);
      expect(line.segments[1].lyrics, equals("Hello"));
    });

    test("'_' is part of the syllable under a chord", () {
      var verses = getVersesFromString("""
[V]
.C
 __Hello
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.segments, hasLength(1));
      expect(line.segments[0].chord, equals("C"));
      expect(line.segments[0].lyrics, equals("Hello"));
    });

    test('Leading whitespace is trimmed', () {
      var verses = getVersesFromString("""
[V]
.    C
  Hello
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.segments, hasLength(2));
      expect(line.segments[0].chord, isNull);
      expect(line.segments[0].lyrics, equals("Hel"));
      expect(line.segments[1].chord, equals("C"));
      expect(line.segments[1].lyrics, equals("lo"));
    });

    test('Completely empty segments are dropped', () {
      // The blank region before the first chord carries no information.
      var verses = getVersesFromString("""
[V]
.        G
         Megáldott
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.segments, hasLength(1));
      expect(line.segments[0].chord, equals("G"));
      expect(line.segments[0].lyrics, equals("Megáldott"));
    });

    test('Chord with no lyrics under it is kept', () {
      var verses = getVersesFromString("""
[V]
.C  G  A     G Asus4 B
 Hello There   Ge____neral
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.lyrics, equals("Hello There General"));
      expect(line.segments, hasLength(6));

      expect(line.segments[0].chord, equals("C"));
      expect(line.segments[0].lyrics, equals("Hel"));
      expect(line.segments[0].hyphenAfter, isTrue);

      expect(line.segments[1].chord, equals("G"));
      expect(line.segments[1].lyrics, equals("lo "));

      expect(line.segments[2].chord, equals("A"));
      expect(line.segments[2].lyrics, equals("There "));

      // Instrumental chord: a chord with no syllable under it.
      expect(line.segments[3].chord, equals("G"));
      expect(line.segments[3].lyrics, isEmpty);

      expect(line.segments[4].chord, equals("Asus4"));
      expect(line.segments[4].lyrics, equals("Ge"));
      expect(line.segments[4].hyphenAfter, isTrue);

      expect(line.segments[5].chord, equals("B"));
      expect(line.segments[5].lyrics, equals("neral"));
    });

    test('Trailing whitespace is trimmed', () {
      var verses = getVersesFromString("""
[V]
 Hello World   
""");
      var line = verses[0].parts[0] as VerseLine;
      expect(line.segments, hasLength(1));
      expect(line.segments[0].lyrics, equals("Hello World"));
    });

    test('Two consecutive chord lines keep both', () {
      expect(
        _chordsOf('[B1]\n.F C Gadd4\n.d7 a Gadd4\n'),
        equals(['F', 'C', 'Gadd4', 'd7', 'a', 'Gadd4']),
      );
    });

    test('Three consecutive chord lines keep all', () {
      expect(
        _chordsOf('.A B\n.C D\n.E F\n'),
        equals(['A', 'B', 'C', 'D', 'E', 'F']),
      );
    });

    test('Chord lines followed by a lyric line align to it', () {
      expect(
        _chordsOf('[B1]\n.F C Gadd4\n.d7 a Gadd4\n Szoveg\n'),
        equals(['F', 'C', 'Gadd4', 'd7', 'a', 'Gadd4']),
      );
    });

    test('Chord line at the end of a section is kept', () {
      var verses = getVersesFromString('[V]\n.C G\n[C]\n ccc\n');
      expect(verses.map((v) => v.tag), equals(['V', 'C']));
      expect(_chordsOf('[V]\n.C G\n[C]\n ccc\n'), equals(['C', 'G', null]));
    });

    test('Chord line at the end of the file is kept', () {
      var verses = getVersesFromString(' Szoveg itt\n.C   G\n');
      expect(verses, hasLength(1));
      expect(verses[0].parts, hasLength(2));
      expect(_chordsOf(' Szoveg itt\n.C   G\n'), equals([null, 'C', 'G']));
    });

    test('Chord line before a blank line and a new tag is kept', () {
      var verses = getVersesFromString('[V]\n.A B\n\n[C]\n ccc\n');
      expect(verses.map((v) => v.tag), equals(['V', 'C']));
      expect(_chordsOf('[V]\n.A B\n\n[C]\n ccc\n'), equals(['A', 'B', null]));
    });

    test('Chord-only section is unchanged', () {
      var verses = getVersesFromString('[Intro]\n.Am  F\n');
      expect(verses, hasLength(1));
      expect(verses[0].tag, equals('Intro'));
      expect(_chordsOf('[Intro]\n.Am  F\n'), equals(['Am', 'F']));
    });

    test('Numbered lyric lines ending in a chord line keep grouping', () {
      var verses = getVersesFromString('[V]\n1Hello\n.C G\n2World\n.C D\n');
      expect(verses.map((v) => v.tag), equals(['V1', 'V2', 'V']));
      expect(
        _chordsOf('[V]\n1Hello\n.C G\n2World\n.C D\n'),
        equals([null, 'C', 'G', 'C', 'D']),
      );
    });

    test('Consumed chord lines are not emitted twice', () {
      expect(_chordsOf('[V]\n1One\n.C G\n2Two\n'), equals([null, 'C', 'G']));
    });

    test('Special line types and errors', () {
      var verses = getVersesFromString("""
[V1]
 First line
 |
 Second line after empty line
 ||
 Line on a new slide
;This is a comment
 One more line
-!!
 This is supposed to be on a new printed page
---
 And this is supposed to be in a new column
!This literally does not exist (we still show it)
 ||
 Last line on a new slide
""");
      var verse = verses[0];
      expect(verse.errorCount, equals(2));
      expect(
        (verse.parts.whereType<PartWithError>()).every(
          (e) => e is UnsupportedLine,
        ),
        isTrue,
      );

      expect(verse.parts[0], TypeMatcher<VerseLine>());
      expect(verse.parts[1], TypeMatcher<EmptyLine>());
      expect(verse.parts[2], TypeMatcher<VerseLine>());
      expect(verse.parts[3], TypeMatcher<NewSlide>());
      expect(verse.parts[4], TypeMatcher<VerseLine>());

      expect(verse.parts[5], TypeMatcher<CommentLine>());
      expect(
        (verse.parts[5] as CommentLine).comment,
        equals("This is a comment"),
      );

      expect(verse.parts[6], TypeMatcher<VerseLine>());
      expect(verse.parts[8], TypeMatcher<VerseLine>());
      expect(verse.parts[10], TypeMatcher<VerseLine>());
      expect(verse.parts[12], TypeMatcher<NewSlide>());
    });
  });
}
