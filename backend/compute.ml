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

let default_labeloffset = 3.5 (* should be 2. but not enough*)

open Types
open Hashcons
module P = Point_lib
module M = Matrix
module S = Spline_lib
module Pi = Picture_lib
module MP = Cairo_metapath

let debug = false

let memoize f fname memoize =
  fun arg -> 
    try
      Hashtbl.find memoize arg.tag
    with
        Not_found -> 
          let result = 
            try 
              f arg.node 
            with exn -> 
              if debug then
                Format.printf "Compute.%s raises : %s@.@?" fname (Printexc.to_string exn);
              raise exn
          in
          Hashtbl.add memoize arg.tag result;
          result
              

let nop = Picture_lib.empty

let option_compile f = function
  | None -> None
  | Some obj -> Some (f obj)

let middle x y = (x/.2.)+.(y/.2.)

let point_of_position ecart
  ({ P.x = xmin; y = ymin}, { P.x = xmax; y = ymax}) = 
    function
      | `Top -> {P.x=middle xmin xmax; y=ymax+.ecart}
      | `Bot -> {P.x=middle xmin xmax; y=ymin-.ecart}
      | `Left -> {P.x=xmin-.ecart; y=middle ymin ymax}
      | `Right -> {P.x=xmax+.ecart; y=middle ymin ymax}
      | `Upleft -> {P.x=xmin-.ecart;y=ymax+.ecart}
      | `Upright -> {P.x=xmax+.ecart;y=ymax+.ecart}
      | `Lowleft -> {P.x=xmin-.ecart;y=ymin-.ecart}
      | `Lowright -> {P.x=xmax+.ecart;y=ymin-.ecart}
      | `Center -> {P.x = middle xmin xmax; P.y = middle ymin ymax }

let anchor_of_position = function
  | `Top -> `Bot
  | `Bot -> `Top
  | `Left -> `Right
  | `Right -> `Left
  | `Upleft -> `Lowright
  | `Upright -> `Lowleft
  | `Lowleft -> `Upright
  | `Lowright -> `Upleft
  | `Center -> `Center

let num_memoize = Hashtbl.create 50
let point_memoize = Hashtbl.create 50
let metapath_memoize = Hashtbl.create 50
let path_memoize = Hashtbl.create 50
let picture_memoize = Hashtbl.create 50
let command_memoize = Hashtbl.create 50

let prelude = ref ""
let set_prelude = (:=) prelude

let rec num' = function
  | F f -> f
  | NXPart p -> 
      let p = point p in
      p.P.x
  | NYPart p ->
      let p = point p in
      p.P.y
  | NAdd(n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        n1 +. n2
  | NSub(n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        n1 -. n2
  | NMult (n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        n1*.n2
  | NDiv (n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        n1/.n2
  | NMax (n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
       max n1 n2
  | NMin (n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        min n1 n2
  | NGMean (n1,n2) ->
      let n1 = num n1 in
      let n2 = num n2 in
        sqrt (n1*.n1+.n2*.n2)
  | NLength p ->
      let p = path p in
      Spline_lib.length p
and num n = memoize num' "num" num_memoize n
and point' = function
  | PTPair (f1,f2) -> 
      let f1 = num f1 in
      let f2 = num f2 in 
      {P.x=f1;y=f2}
  | PTPointOf (f,p) -> 
      let f = num f in
      let p = path p in
      Spline_lib.abscissa_to_point p f
  | PTDirectionOf (f,p) -> 
      let f = num f in
      let p = path p in
      Spline_lib.direction_of_abscissa p f
  | PTAdd (p1,p2) -> 
      let p1 = point p1 in
      let p2 = point p2 in
      P.add p1 p2
  | PTSub (p1,p2) ->
      let p1 = point p1 in
      let p2 = point p2 in
        P.sub p1 p2
  | PTMult (f,p) ->
      let f = num f in
      let p1 = point p in
        P.mult f p1
  | PTRotated (f,p) ->
      let p1 = point p in
      P.rotated f p1
  | PTPicCorner (pic, corner) ->
      let p = commandpic pic in
      point_of_position 0. (Picture_lib.bounding_box p) corner
  | PTTransformed (p,tr) ->
      let p = point p in
      let tr = transform tr in
      P.transform tr p
and point p = memoize point' "point" point_memoize p
and knot k =
  match k.Hashcons.node with
    | { knot_in = d1 ; knot_p = p ; knot_out = d2 } ->
        let d1 = direction d1 in
        let p = point p in
        let d2 = direction d2 in
        d1,Cairo_metapath.knot p,d2

and joint dl j dr = 
  match j.Hashcons.node with
  | JLine -> MP.line_joint
  | JCurve -> MP.curve_joint dl dr
  | JCurveNoInflex -> MP.curve_no_inflex_joint dl dr
  | JTension (a,b) -> MP.tension_joint dl a b dr
  | JControls (p1,p2) ->
      let p1 = point p1 in
      let p2 = point p2 in
      MP.controls_joint p1 p2
and direction d = 
  match d.Hashcons.node with
  | Vec p -> 
      let p = point p in
      MP.vec_direction p
  | Curl f -> MP.curl_direction f
  | NoDir  -> MP.no_direction
and metapath' = function
  | MPAConcat (pa,j,p) ->
      let pdl,p,pdr = metapath p in
      let dl,pa,dr = knot pa in
      let j = joint pdr j dl in
      pdl,MP.concat p j pa,dr
  | MPAAppend (p1,j,p2) ->
      let p1dl,p1,p1dr = metapath p1 in
      let p2dl,p2,p2dr = metapath p2 in
      let j = joint p1dr j p2dl in
      p1dl,MP.append p1 j p2,p2dr
  | MPAKnot k -> 
      let dl,p,dr = knot k in
      dl,MP.start p, dr
  | MPAofPA p -> 
      MP.no_direction, MP.from_path (path p), MP.no_direction

and metapath p = memoize metapath' "metapath" metapath_memoize p
and path' = function
  | PAofMPA p -> 
      let _,mp,_ = (metapath p) in
      MP.to_path mp
  | MPACycle (d,j,p) ->
      let d = direction d in
      let dl,p,_ = metapath p in
      let j = joint d j dl in
      MP.cycle j p
  | PATransformed (p,tr) ->
      let p = path p in
      let tr = transform tr in
      Spline_lib.transform tr p
  | PACutAfter (p1,p2) ->
      let p1 = path p1 in
      let p2 = path p2 in
      Spline_lib.cut_after p1 p2
  | PACutBefore (p1,p2) ->
      let p1 = path p1 in
      let p2 = path p2 in
      Spline_lib.cut_before p1 p2
  | PABuildCycle pl ->
(*       let npl = List.map path pl in *)
      (* TODO *) assert false
(*       Spline_lib.buildcycle npl *)
  | PASub (f1, f2, p) ->
      let f1 = num f1 in
      let f2 = num f2 in
      let p = path p in
      Spline_lib.subpath p f1 f2
  | PABBox p ->
      let p = commandpic p in
      let pmin,pmax = Picture_lib.bounding_box p in
      Spline_lib.close 
        (Spline_lib.create_lines [{P.x = pmin.P.x; y = pmin.P.y};
                                  {P.x = pmin.P.x; y = pmax.P.y};
                                  {P.x = pmax.P.x; y = pmax.P.y};
                                  {P.x = pmax.P.x; y = pmin.P.y}])
                          
  | PAUnitSquare -> MP.Approx.unitsquare 1.
  | PAQuarterCircle -> MP.Approx.quartercircle 1.
  | PAHalfCircle -> MP.Approx.halfcirle 1.
  | PAFullCircle -> MP.Approx.fullcircle 1.
and path p = (*Format.printf "path : %a@.@?" Print.path p;*) memoize path' "path" path_memoize p
and picture' = function
  | PITransformed (p,tr) ->
      let tr = transform tr in
      let pic = commandpic p in
      Picture_lib.transform tr pic
  | PITex s -> 
      (* With lookfortex we never pass this point *)
      let tex = List.hd (Gentex.create !prelude [s]) in
      Picture_lib.tex tex
  | PIClip (pic,pth) ->
      let pic = commandpic pic in
      let pth = path pth in
      Picture_lib.clip pic pth

and picture p = memoize picture' "picture" picture_memoize p
and transform t = 
  match t.Hashcons.node with
  | TRRotated f -> Matrix.rotation f
  | TRScaled f -> Matrix.scale (num f)
  | TRSlanted f -> Matrix.slanted (num f)
  | TRXscaled f -> Matrix.xscaled (num f)
  | TRYscaled f -> Matrix.yscaled (num f)
  | TRShifted p -> 
      let p = point p in
      Matrix.translation p
  | TRZscaled p -> Matrix.zscaled (point p)
  | TRReflect (p1,p2) -> Matrix.reflect (point p1) (point p2)
  | TRRotateAround (p,f) -> Matrix.rotate_around (point p) f

and commandpic p =
  match p.Hashcons.node with
  | Picture p -> picture p
  | Command c -> command c
  | Seq l ->
      begin match l with
      | [] -> Picture_lib.empty
      | [x] -> commandpic x
      | (x::r) -> 
          List.fold_left 
          (fun acc c -> Picture_lib.on_top acc (commandpic c)) (commandpic x) r
      end

and dash d = 
    match d.Hashcons.node with
  | DEvenly -> Picture_lib.Dash.line
  | DWithdots -> Picture_lib.Dash.dots
  | DScaled (f, d) -> 
      let d = dash d in
      Picture_lib.Dash.scale f d
  | DShifted (p,d) ->
      let p = point p in
      let d = dash d in
      Picture_lib.Dash.shifted p.P.x d
  | DPattern l ->
      let l = List.map dash_pattern l in
      Picture_lib.Dash.pattern l

and dash_pattern o = 
    match o.Hashcons.node with
      | On f -> Picture_lib.Dash.On (num f)
      | Off f -> Picture_lib.Dash.Off (num f)
	
and command' = function
  | CDraw (p, c, pe, dsh) ->
      let p = path p in
      let pe = (option_compile pen) pe in
      let dsh = (option_compile dash) dsh in
      Picture_lib.stroke_path p c pe dsh
  | CDrawArrow (p, color, pe, dsh) -> (*TODO*) command (mkCDraw p color pe dsh)
  | CFill (p, c) -> 
      let p = path p in
      Picture_lib.fill_path p c
  | CDotLabel (pic, pos, pt) -> 
      Picture_lib.on_top (Picture_lib.draw_point (point pt)) (command (mkCLabel pic pos pt))
  | CLabel (pic, pos ,pt) -> 
      let pic = commandpic pic in
      let pt = point pt in
      let mm = (Picture_lib.bounding_box pic) in
      let anchor = anchor_of_position pos in
      let pos = (point_of_position default_labeloffset mm anchor) in
      let tr = Matrix.translation (P.sub pt pos) in
      Picture_lib.transform tr pic
  | CExternalImage (filename,sp) -> 
      Picture_lib.external_image filename (spec sp)
and spec = function
  | `Exact (n1,n2) -> `Exact (num n1, num n2)
  | `Height n -> `Height (num n)
  | `Width n -> `Width (num n)
  | `Inside (n1,n2) -> `Inside (num n1, num n2)
  | `None -> `None
and pen p = 
  (* TODO : the bounding box is not aware of the pen size *)
  match p.Hashcons.node with
    | PenCircle -> Matrix.identity
    | PenSquare -> (*TODO not with cairo...*)assert false
        (*Picture_lib.PenSquare*)
    | PenFromPath p -> (*TODO : very hard*)assert false
        (*Picture_lib.PenFromPath (path p)*)
    | PenTransformed (p, tr) ->
        Matrix.multiply (transform tr) (pen p)

and command c = memoize command' "command" command_memoize c
