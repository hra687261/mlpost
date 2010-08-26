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

open Format

let print fmt i c =
  (* resetting is actually not needed; variables other than
     x,y are not local to figures *)
(*   Compile.reset (); *)
  let () = Duplicate.commandpic c in
  let c = Compile.commandpic_cmd c in
  fprintf fmt "@[beginfig(%d)@\n  @[%a@] endfig;@]@."
    i MPprint.command c

let print_prelude s fmt () =
  fprintf fmt "input mp-tool ; %% some initializations and auxiliary macros
input mp-spec ; %% macros that support special features
@\n";
 fprintf fmt "prologues := 0;@\n";
 fprintf fmt "mpprocset := 0;@\n";
 fprintf fmt "verbatimtex@\n";
 fprintf fmt "%%&latex@\n";
 fprintf fmt "%s" s;
 fprintf fmt "\\begin{document}@\n";
 fprintf fmt "etex@\n"
   (* fprintf fmt "input boxes;@\n" *)

let defaultprelude = "\\documentclass{article}\n\\usepackage[T1]{fontenc}\n"

let prelude_ref = ref defaultprelude
let set_prelude x = prelude_ref := x

(** take a list of figures [l] and write the code to the formatter in argument
 *)

let mp bn ?prelude l =
  let prelude =
    match prelude with
    | None -> !prelude_ref
    | Some s -> s in
  let f = File.set_ext (File.from_string bn) "mp" in
  File.write_to_formatted f (fun fmt ->
    print_prelude prelude fmt ();
    let i = ref 1 in
    let m = List.fold_left (fun acc (t,f) ->
      let acc = Misc.IntMap.add !i t acc in
      print fmt !i f; incr i; acc) Misc.IntMap.empty l in
    fprintf fmt "end@.";
    f,m)

(* batch processing *)

let figuren = ref 0
let figures = Queue.create ()

let filename_prefix = ref ""
let set_filename_prefix = (:=) filename_prefix

let required_files : File.t list ref = ref []
let set_required_files l = required_files := List.map File.from_string l

let emit s f =
  let fn =
    File.set_ext (File.from_string (!filename_prefix^s)) "mps" in
  Queue.add (fn, f) figures

let read_prelude_from_tex_file = Metapost_tool.read_prelude_from_tex_file

let dump_tex ?prelude f =
  let c = open_out (f ^ ".tex") in
  let fmt = formatter_of_out_channel c in
  begin match prelude with
    | None ->
	fprintf fmt "\\documentclass[a4paper]{article}"
    | Some s ->
        fprintf fmt "%s@\n" s
  end;
      fprintf fmt "\\usepackage{graphicx}";
      fprintf fmt "%%%%%%%%
%% For specials in mps
\\LoadMetaPostSpecialExtensions
%%%%%%%%
";
  fprintf fmt "\\begin{document}@\n";
  fprintf fmt "\\begin{center}@\n";
  Queue.iter
    (fun (s,_) ->
       fprintf fmt "\\hrulefill\\verb!%s!\\hrulefill\\\\[1em]@\n"
       (File.to_string s);
       fprintf fmt "\\includegraphics{%s}\\\\@\n" (File.to_string s);
       fprintf fmt "\\hrulefill\\\\@\n@\n\\medskip@\n";)
    figures;
  fprintf fmt "\\end{center}@\n";
  fprintf fmt "\\end{document}@.";
  close_out c

let call_latex ?inv ?outv ?verbose f =
  let cmd = Misc.sprintf "latex -interaction=nonstopmode %s" f in
  Misc.call_cmd ?inv ?outv ?verbose cmd

let call_mpost ?inv ?outv ?verbose f =
  let cmd =
    Misc.sprintf "mpost -interaction=nonstopmode %s" (File.to_string f) in
  Misc.call_cmd ?inv ?outv ?verbose cmd

let print_latex_error () =
  if Sys.file_exists "mpxerr.tex" then begin
    Printf.printf
      "############################################################\n";
    Printf.printf
      "LaTeX has found an error in your file. Here is its output:\n";
    ignore (call_latex ~outv:true "mpxerr.tex")
  end else
    Printf.printf "There was an error during execution of metapost. Aborting. \
      Execute with option -v to see the error.\n"

let mps ?prelude ?(verbose=false) bn figl =
  if figl <> [] then
    let targets = List.map fst figl in
    let f, m = mp bn ?prelude figl in
    let s = call_mpost ~verbose f in
    if s <> 0 then print_latex_error ();
    Misc.IntMap.iter (fun k to_ ->
      let from = File.set_ext f (string_of_int k) in
      File.move from to_) m;
    targets
    else []

let call_mptopdf ?inv ?outv ?verbose f =
  (** assume that f is ps file or sth like that *)
  ignore (Misc.call_cmd ?inv ?outv ?verbose
    (sprintf "mptopdf %s" (File.to_string f)));
  let out = File.set_ext f "pdf" in
  File.move (File.append out ("-"^File.extension f)) out;
  out

let call_convert ?inv ?outv ?verbose from to_ =
  ignore (Misc.call_cmd ?inv ?outv ?verbose
    (sprintf "convert -density 600x600 \"%s\" \"%s\"" (File.to_string from)
      (File.to_string to_)));
  to_

let pdf ?prelude ?verbose bn figl =
  let l = mps ?prelude ?verbose bn figl in
  List.map (fun f -> call_mptopdf ?verbose f) l

let emited () = Queue.fold (fun l t -> t :: l) [] figures

let png ?prelude ?verbose bn figl =
  let pdfl = pdf ?prelude ?verbose bn figl in
  List.map (fun f -> call_convert ?verbose f (File.set_ext f "png")) pdfl

let wrap_tempdir f suffix ?prelude ?verbose ?clean bn figl =
  let do_ from_ to_ =
    (** first copy necessary files, then do your work *)
    List.iter (fun f -> File.copy (File.place from_ f) (File.place to_ f))
      !required_files;
    let l = f ?prelude ?verbose bn figl in
    l, l
  in
  Metapost_tool.tempdir ?clean "mlpost" ("metapost-"^suffix) do_

let temp_mp ?prelude ?(verbose=false) ?(clean=true) = mp ?prelude
let temp_mps = wrap_tempdir mps "mps"
let temp_pdf = wrap_tempdir pdf "pdf"
let temp_png = wrap_tempdir png "png"

let wrap_dump f ?prelude ?verbose ?clean bn =
  let bn = Filename.basename bn in
  ignore (f ?prelude ?verbose ?clean bn (emited ()))

let dump_mp = wrap_dump temp_mp
let dump_mps = wrap_dump temp_mps
let dump_pdf = wrap_dump temp_pdf
let dump_png = wrap_dump temp_png
let dump = dump_mps

let generate ?prelude ?verbose ?clean bn figl =
  let figl = List.map (fun (s,f) ->
    let s = File.from_string s in
    File.set_ext s "mps", f) figl in
  ignore (temp_mps ?prelude ?verbose ?clean bn figl)

let slideshow l k =
  let l = List.map Picture.make l in
  let l' = Command.seq (List.map
                  (fun p -> Command.draw
                              ~color:Color.white
                              (Picture.bbox p)) l)
  in
  let x = ref (k-1) in
    List.map (fun p ->
                  incr x;
                  !x, Command.seq [l'; Command.draw_pic p]) l


let emit_slideshow s l =
  let l = slideshow l 0 in
  List.iter (fun (i,fig) -> emit (s^(string_of_int i)) fig) l


let dumpable () =
  Queue.iter (fun (s,_) ->
    let s = File.set_ext s "" in
    Printf.printf "%s\n" (File.to_string s)) figures

let depend myname =
  Queue.iter (fun (s,_) ->
    Printf.printf "%s" (File.to_string (File.set_ext s "fmlpost"))) figures;
  Printf.printf " : %s.cmlpost\n" myname



