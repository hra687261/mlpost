(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
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
open Arg

let files = 
  Queue.create ()

let add_file f = 
  if not (Filename.check_suffix f ".ml") then begin
    eprintf "mlpost: don't know what to do with %s@." f;
    exit 1
  end;
  if not (Sys.file_exists f) then begin
    eprintf "mlpost: %s: no such file@." f;
    exit 1
  end;
  Queue.add f files

let pdf = ref true
let latex_file = ref None
let set_latex_file f =
  if not (Sys.file_exists f) then begin
    eprintf "mlpost: %s: no such file@." f;
    exit 1
  end;
  latex_file := Some f
let xpdf = ref false
let use_ocamlbuild = ref false
let classic_display = ref false
let ccopt = ref ""
let execopt = ref ""
let eps = ref false
let verbose = ref false
let native = ref false
let libdir = ref Version.libdir
let cairo = ref false
let depend = ref false
let dumpable = ref false

let version () =
  print_string Version.version;
  print_newline ();
  exit 0

let add_ccopt x = ccopt := !ccopt ^ " " ^ x
let add_execopt x = execopt := !execopt ^ " " ^ x

let notcairo = Version.includecairo = ""

let give_lib () =
  if notcairo then ["","unix"] 
  else ("","unix")::("","bigarray")::Version.cairolibs

let get_include_compile s = 
  let aux = function
    | "cmxa" -> List.map (fun (x,y) -> Filename.concat x (y^".cmxa")) 
        (give_lib ())
    | "cma" -> List.map (fun (x,y) -> Filename.concat x (y^".cma")) 
        (give_lib ())
    | "dir" -> List.map fst (give_lib ())
    | "file" -> List.map snd (give_lib ())
    | _ -> assert false in
  print_string (String.concat "\n" (aux s))

let nocairo () =
  print_string "Mlpost has not been compiled with cairo\n";
  exit 1

let spec = Arg.align
  ([ "-pdf", Set pdf, " Generate .mps files (default)";
    "-ps", Clear pdf, " Generate .1 files";
    "-latex", String set_latex_file, "<main.tex> Scan the LaTeX prelude";
    "-eps", Set eps, " Generate encapsulated postscript files";
    "-xpdf", Set xpdf, " wysiwyg mode using xpdf remote server";
    "-v", Set verbose, " be a bit more verbose";
    "-ocamlbuild", Set use_ocamlbuild, " Use ocamlbuild to compile";
    "-classic-display", Set classic_display,
    " Call Ocamlbuild with -classic-display";
    "-native", Set native, " Compile to native code";
    "-ccopt", String add_ccopt, 
    "\"<options>\" Pass <options> to the Ocaml compiler";
    "-execopt", String add_execopt,
    "\"<options>\" Pass <options> to the compiled program";
    "-version", Unit version, " Print Mlpost version and exit";
    "-libdir", String ((:=) libdir), " Set path for mlpost.cma";
    "-depend", Set depend, " output dependency lines in a format suitable for the make(1) utility";
    "-dumpable", Set dumpable, " output one name of dumpable file by line";
    "-get-include-compile", Symbol (["cmxa";"cma";"dir";"file"],get_include_compile), " output the library which are needed by mlpost"
  ]@
  if notcairo 
  then ["-cairo" , Unit nocairo, " Mlpost has not been compiled with the cairo backend"]
  else ["-cairo" , Set cairo, " Use the experimental cairo backend instead of metapost"])

let () = 
  Arg.parse spec add_file "Usage: mlpost [options] files..."


exception Command_failed of int

let command' ?inv ?outv ?verbose s =
  let s, _ = Misc.call_cmd ?inv ?outv ?verbose s in
  if s <> 0 then raise (Command_failed s)

let command ?inv ?outv ?verbose s = 
  try command' ?inv ?outv ?verbose s with Command_failed s -> exit s

let ocaml args execopt =
  let cmd = "ocaml " ^ String.concat " " args ^ " " ^ execopt in
  command ~outv:true ~verbose:!verbose cmd

let ocamlopt args execopt =
  let exe = Filename.temp_file "mlpost" ".exe" in
  let cmd = Version.ocamlopt^" -o " ^ exe ^ " " ^ String.concat " " args in
  let () = if !verbose then Format.eprintf "%s@." cmd in
  command ~verbose:!verbose cmd;
  command ~outv:true ~verbose:!verbose (exe ^ " " ^ execopt)

let ocamlbuild args =
  let args = if !classic_display then "-classic-display" :: args else args in
  command' ~outv:true ~verbose:!verbose ("ocamlbuild " ^ String.concat " " args)

(** Return an unused file name which in the same directory as the prefix. *)
let temp_file_name prefix suffix =
  if not (Sys.file_exists (prefix ^ suffix)) then
    prefix ^ suffix
  else begin
    let i = ref 0 in
    while Sys.file_exists (prefix ^ string_of_int !i ^ suffix) do
      incr i
    done;
    prefix ^ string_of_int !i ^ suffix
  end


let compile f =
  let bn = Filename.chop_extension f in
  let mlf, cout = Filename.open_temp_file "mlpost" ".ml" in
  Printf.fprintf cout "# 1 \"%s\"\n" f;
  begin 
    let cin = open_in f in
    try while true do output_char cout (input_char cin) done
    with End_of_file -> ()
  end;
  let pdf = if !pdf || !xpdf then "~pdf:true" else "" in
  let eps = if !eps then "~eps:true" else "" in
  let verb = if !verbose then "~verbose:true" else "" in
  let prelude = match !latex_file with
    | None -> ""
    | Some f -> 
        sprintf "~prelude:%S" (Metapost_tool.read_prelude_from_tex_file f)
  in
  if !depend then
    Printf.fprintf cout 
      "\nlet () = Mlpost.Metapost.depend \"%s\" \n" bn
  else if !dumpable then
    Printf.fprintf cout 
      "\nlet () = Mlpost.Metapost.dumpable () \n"
  else if !cairo then
    begin
      if not (!xpdf) then 
        Printf.fprintf cout 
          "\nlet () = Mlpost.Cairost.dump_pdf () \n"
      else
        Printf.fprintf cout 
          "\nlet () = Mlpost.Cairost.dump_pdfs \"_mlpost\"\n"
    end
  else
    begin
      Printf.fprintf cout 
        "\nlet () = Mlpost.Metapost.dump %s %s %s %s \"%s\"\n" 
          prelude pdf eps verb bn;

      if !xpdf then 
        Printf.fprintf cout 
          "\nlet () = Mlpost.Metapost.dump_tex %s \"_mlpost\"\n" prelude
    end;
  close_out cout;


  if !use_ocamlbuild then begin
    (* Ocamlbuild cannot compile a file which is in /tmp *)
    let mlf2 = temp_file_name bn ".ml" in
    command ~verbose:!verbose ("cp " ^ mlf ^ " " ^ mlf2);
    let ext = if !native then ".native" else ".byte" in
    try
      let args = ["-lib unix"] in
      let args =
        if Version.libdir = "" then args else
          args@[sprintf "-cflags -I,%s -lflags -I,%s"
            Version.libdir Version.libdir] in
      let args = 
        if notcairo then args else
          let includecairos = 
            let cairolibs = List.map (fun (x,y) -> Filename.concat x y) Version.cairolibs in
            String.concat "," cairolibs in
          let iI = String.concat  ","
            (List.map (fun (x,_) -> "-I,"^x) Version.cairolibs) in
          args@[sprintf "-lflags %s -lib bigarray -libs %s" iI includecairos] in
      let args =
        args@["-lib mlpost";
           !ccopt;Filename.chop_extension mlf2 ^ ext;"--"; !execopt]
      in
      ocamlbuild args;
      Sys.remove mlf2
    with Command_failed out -> 
      Sys.remove mlf2;
      exit out
  end else begin
    if !native then
      let cairo_args = if notcairo then [] 
      else [Version.includecairo; "bigarray.cmxa"; "cairo.cmxa"; "bitstring.cmxa"] in
      ocamlopt ([!ccopt; "-I"; !libdir;"unix.cmxa"] @ cairo_args @ 
                  ["mlpost.cmxa"; mlf]) !execopt
    else
      let cairo_args = if notcairo then [] 
      else [Version.includecairo; "bigarray.cma"; "cairo.cma"; "bitstring.cma"] in
      ocaml ([!ccopt; "-I"; !libdir;"unix.cma"] @ cairo_args @
               ["mlpost.cma"; mlf]) !execopt
  end;

  Sys.remove mlf;
  if !xpdf then begin
    if not (!cairo) then
      begin
        begin try Sys.remove "_mlpost.aux" with _ -> () end;
        ignore (Sys.command "pdflatex _mlpost.tex");
      end;
(*     ignore (Sys.command "setsid xpdf -remote mlpost _mlpost.pdf &") *)
    if Sys.command "fuser _mlpost.pdf" = 0 then
      ignore (Sys.command "xpdf -remote mlpost -reload")
    else
      ignore (Sys.command "setsid xpdf -remote mlpost _mlpost.pdf &")
  end

let () = Queue.iter compile files
