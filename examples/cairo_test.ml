open Mlpost
open Command
open Picture
open Point
open Path
module H = Helpers

(*parse <<togglescript>> *)

(*parse <<other27 *)

let a = Point.pt (Num.bp 0., Num.bp 0.)
let pen = Pen.scale (Num.bp 4.) Pen.circle
let other27 = 
  seq [
    draw (Path.pathp [a]) ~pen;
    label ~pos:`Top (Picture.tex "Au dessus") a;
    label ~pos:`Bot (Picture.tex "En dessous") a;
    label ~pos:`Right (Picture.tex "\\`A droite") a;
    label ~pos:`Left (Picture.tex "\\`A gauche") a;
  ]

(*parse >> <<handbook3 *)
let z0 = 0.,0.
let z1 = 60.,40.
let z2 = 40.,90.
let z3 = 10.,70.
let z4 = 30.,50.
let l1 = z0::z1::z2::z3::z4::[]

let labels1 =
  seq [H.dotlabels ~pos:`Top ["0";"2";"4"] (map_bp [z0;z2;z4]);
       dotlabel ~pos:`Left (tex "3") (bpp z3);
       dotlabel ~pos:`Right (tex "1") (bpp z1) ]

let handbook3 = seq [ draw (path ~style:jCurve  l1); labels1 ]
(*parse >> *)

let _ = 
  List.iter (fun (name,fig) -> Cairost.emit_pdf name fig)
  [ "other27.pdf", other27;
    "handbook3.pdf", handbook3;
  ]
