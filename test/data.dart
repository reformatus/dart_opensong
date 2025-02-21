import 'package:dart_opensong/src/types/song.dart';

String normal = """
[P1]
.B A C H
 012
.C A#  C# C
 0123456789abc
[V1]
.C    D    Hm
 Ez egy dalszöveg
 Jaj de jó
[P]
 Ez a prechorus juhú
[C]
 Éééénekeljük a refrént
 Ó-ó-ó
 Ééééénekeljük ma a refrén
 A-a-a
""";

String multiIndexTag = """
[V]
.C  D   Hmsus4add9 Ab
1Ez egy vers_______szak
2Ez a második
3Ez a harmadik
.D   G             Ebm
1Első második sora
2Második második sora
3Harmadik harmadik sora
[P1]
.B A C H
.C A#  C# C
 Ó-ó-ó
[C]
Ez itt a refrén
Szóköz nélkül
""";

void main() {
  Song normalSong = parseFromString(normal);
  Song multiIndexTagSong = parseFromString(multiIndexTag);

  return;
}
