import 'package:dart_opensong/dart_opensong.dart';
import 'package:test/test.dart';

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
      expect((verses[0].parts[0] as VerseLine).segments[0].lyrics, equals("abcd"));
      expect((verses[0].parts[0] as VerseLine).segments[2].chord, equals("A#"));
      expect((verses[0].parts[0] as VerseLine).segments[2].lyrics, equals("k "));
      expect((verses[0].parts[0] as VerseLine).segments[3].chord, equals("C"));
      expect((verses[0].parts[0] as VerseLine).segments[3].lyrics, isEmpty);
      expect((verses[0].parts[0] as VerseLine).lyrics, equals("abcdefghijk "));
      expect((verses[0].parts[1] as VerseLine).lyrics, equals("hello "));

      expect(verses[1].tag, equals("V2"));
      expect(verses[1].parts, hasLength(2));
      expect(verses[1].parts[0], TypeMatcher<VerseLine>());
      expect((verses[1].parts[0] as VerseLine).segments, hasLength(4));
      expect((verses[1].parts[0] as VerseLine).segments[0].chord, equals("C"));
      expect((verses[1].parts[0] as VerseLine).segments[0].lyrics, equals("ijkl"));
      expect((verses[1].parts[0] as VerseLine).segments[2].chord, equals("A#"));
      expect((verses[1].parts[0] as VerseLine).segments[2].lyrics, equals("s "));
      expect((verses[1].parts[0] as VerseLine).segments[3].chord, equals("C"));
      expect((verses[1].parts[0] as VerseLine).segments[3].lyrics, isEmpty);
      expect((verses[1].parts[0] as VerseLine).lyrics, equals("ijklmnopqrs "));
      expect((verses[1].parts[1] as VerseLine).lyrics, equals("hello "));

      expect((verses[2].parts[0] as VerseLine).segments, hasLength(5));
      expect(verses[2].lyrics, isEmpty);

      expect((verses[5].parts[0] as VerseLine).segments[3].hyphenAfter, isTrue);
      expect((verses[5].parts[0] as VerseLine).segments[4].hyphenAfter, isTrue);
      expect((verses[5].parts[0] as VerseLine).segments[5].hyphenAfter, isTrue);

      expect((verses[5].parts[1] as VerseLine).segments[3].hyphenAfter, isFalse);
      expect((verses[5].parts[1] as VerseLine).segments[4].hyphenAfter, isFalse);
      expect((verses[5].parts[1] as VerseLine).segments[5].hyphenAfter, isFalse);

      expect((verses[6].parts[0] as VerseLine).segments[2].hyphenAfter, isFalse);
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
!This literally does not exist
 ||
 Last line on a new slide
""");
      var verse = verses[0];
      expect(verse.errorCount, equals(3));
      expect((verse.parts.whereType<PartWithError>()).every((e) => e is UnsupportedLine), isTrue);

      expect(verse.parts[0], TypeMatcher<VerseLine>());
      expect(verse.parts[1], TypeMatcher<EmptyLine>());
      expect(verse.parts[2], TypeMatcher<VerseLine>());
      expect(verse.parts[3], TypeMatcher<NewSlide>());
      expect(verse.parts[4], TypeMatcher<VerseLine>());

      expect(verse.parts[5], TypeMatcher<CommentLine>());
      expect((verse.parts[5] as CommentLine).comment, equals("This is a comment"));

      expect(verse.parts[6], TypeMatcher<VerseLine>());
      expect(verse.parts[8], TypeMatcher<VerseLine>());
      expect(verse.parts[10], TypeMatcher<VerseLine>());
      expect(verse.parts[12], TypeMatcher<NewSlide>());
    });
  });
}
