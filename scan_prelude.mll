{
  open Lexing

  let buffer = Buffer.create 1024
}
(* scan the main LaTeX file to extract its prelude *)

rule scan = parse
  | "\\%" as s
      { Buffer.add_string buffer s; scan lexbuf }
  | "%" [^'\n']* '\n'
      { Buffer.add_char buffer '\n'; scan lexbuf }
  | _ as c
      { Buffer.add_char buffer c; scan lexbuf }
  | "\\begin{document}"
      { Buffer.contents buffer }
  | eof 
      { Buffer.contents buffer }

