(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  Jean-Christophe Filliatre, Romain Bardou and Francois Bobot           *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

let standardencoding = [|
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; "space"; "exclam"; "quotedbl";
  "numbersign"; "dollar"; "percent"; "ampersand"; "quoteright";
  "parenleft"; "parenright"; "asterisk"; "plus"; "comma";
  "hyphen"; "period"; "slash"; "zero"; "one";
  "two"; "three"; "four"; "five"; "six";
  "seven"; "eight"; "nine"; "colon"; "semicolon";
  "less"; "equal"; "greater"; "question"; "at";
  "A"; "B"; "C"; "D"; "E";
  "F"; "G"; "H"; "I"; "J";
  "K"; "L"; "M"; "N"; "O";
  "P"; "Q"; "R"; "S"; "T";
  "U"; "V"; "W"; "X"; "Y";
  "Z"; "bracketleft"; "backslash"; "bracketright"; "asciicircum";
  "underscore"; "quoteleft"; "a"; "b"; "c";
  "d"; "e"; "f"; "g"; "h";
  "i"; "j"; "k"; "l"; "m";
  "n"; "o"; "p"; "q"; "r";
  "s"; "t"; "u"; "v"; "w";
  "x"; "y"; "z"; "braceleft"; "bar";
  "braceright"; "asciitilde"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; "exclamdown"; "cent"; "sterling"; "fraction";
  "yen"; "florin"; "section"; "currency"; "quotesingle";
  "quotedblleft"; "guillemotleft"; "guilsinglleft"; "guilsinglright"; "fi";
  "fl"; ".notdef"; "endash"; "dagger"; "daggerdbl";
  "periodcentered"; ".notdef"; "paragraph"; "bullet"; "quotesinglbase";
  "quotedblbase"; "quotedblright"; "guillemotright"; "ellipsis"; "perthousand";
  ".notdef"; "questiondown"; ".notdef"; "grave"; "acute";
  "circumflex"; "tilde"; "macron"; "breve"; "dotaccent";
  "dieresis"; ".notdef"; "ring"; "cedilla"; ".notdef";
  "hungarumlaut"; "ogonek"; "caron"; "emdash"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  "AE"; ".notdef"; "ordfeminine"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; "Lslash"; "Oslash"; "OE";
  "ordmasculine"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; "ae"; ".notdef"; ".notdef"; ".notdef";
  "dotlessi"; ".notdef"; ".notdef"; "lslash"; "oslash";
  "oe"; "germandbls"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"
|]

let isoencoding = [|
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; "space"; "exclam"; "quotedbl";
  "numbersign"; "dollar"; "percent"; "ampersand"; "quotesingle";
  "parenleft"; "parenright"; "asterisk"; "plus"; "comma";
  "hyphen"; "period"; "slash"; "zero"; "one";
  "two"; "three"; "four"; "five"; "six";
  "seven"; "eight"; "nine"; "colon"; "semicolon";
  "less"; "equal"; "greater"; "question"; "at";
  "A"; "B"; "C"; "D"; "E";
  "F"; "G"; "H"; "I"; "J";
  "K"; "L"; "M"; "N"; "O";
  "P"; "Q"; "R"; "S"; "T";
  "U"; "V"; "W"; "X"; "Y";
  "Z"; "bracketleft"; "backslash"; "bracketright"; "asciicircum";
  "underscore"; "grave"; "a"; "b"; "c";
  "d"; "e"; "f"; "g"; "h";
  "i"; "j"; "k"; "l"; "m";
  "n"; "o"; "p"; "q"; "r";
  "s"; "t"; "u"; "v"; "w";
  "x"; "y"; "z"; "braceleft"; "bar";
  "braceright"; "asciitilde"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; ".notdef";
  ".notdef"; ".notdef"; ".notdef"; ".notdef"; "dotlessi";
  "quoteleft"; "quoteright"; "circumflex"; "tilde"; "macron";
  "breve"; "dotaccent"; "dieresis"; ".notdef"; "ring";
  "cedilla"; ".notdef"; "hungarumlaut"; "ogonek"; "caron";
  "space"; "exclamdown"; "cent"; "sterling"; "currency";
  "yen"; "brokenbar"; "section"; "dieresis"; "copyright";
  "ordfeminine"; "guillemotleft"; "logicalnot"; "hyphen";
  "registered";
  "macron"; "degree"; "plusminus"; "twosuperior"; "threesuperior";
  "acute"; "mu"; "paragraph"; "periodcentered"; "cedilla";
  "onesuperior"; "ordmasculine"; "guillemotright"; "onequarter";
  "onehalf";
  "threequarters"; "questiondown"; "Agrave"; "Aacute"; "Acircumflex";
  "Atilde"; "Adieresis"; "Aring"; "AE"; "Ccedilla";
  "Egrave"; "Eacute"; "Ecircumflex"; "Edieresis"; "Igrave";
  "Iacute"; "Icircumflex"; "Idieresis"; "Eth"; "Ntilde";
  "Ograve"; "Oacute"; "Ocircumflex"; "Otilde"; "Odieresis";
  "multiply"; "Oslash"; "Ugrave"; "Uacute"; "Ucircumflex";
  "Udieresis"; "Yacute"; "Thorn"; "germandbls"; "agrave";
  "aacute"; "acircumflex"; "atilde"; "adieresis"; "aring";
  "ae"; "ccedilla"; "egrave"; "eacute"; "ecircumflex";
  "edieresis"; "igrave"; "iacute"; "icircumflex"; "idieresis";
  "eth"; "ntilde"; "ograve"; "oacute"; "ocircumflex";
  "otilde"; "odieresis"; "divide"; "oslash"; "ugrave";
  "uacute"; "ucircumflex"; "udieresis"; "yacute"; "thorn";
  "ydieresis"
|]

