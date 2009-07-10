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

open Path
open Point
open Num
open Command

(*  puts labels at given points with given text *)
let dotlabels ?(pos=`Center) ls lp =
  seq (List.map2 (fun s p -> dotlabel ~pos:pos (Picture.tex s) p) ls lp)

let draw_simple_arrow ?color ?pen ?dashed ?style ?outd ?ind a b =
  Arrow.simple ?color ?pen ?dashed 
    (Arrow.simple_point_point ?style ?outd ?ind a b)

let draw_label_arrow ?color ?pen ?dashed ?style ?outd ?ind ?pos lab a b =
  let p = Arrow.simple_point_point ?style ?outd ?ind a b in
  Arrow.simple ?color ?pen ?dashed p ++
  label ?pos lab (Path.point 0.5 p)

let draw_labelbox_arrow ?color ?pen ?dashed ?style ?outd ?ind ?pos lab a b =
  draw_label_arrow ?color ?pen ?dashed ?style ?outd ?ind ?pos 
    (Picture.make (Box.draw lab)) a b

let box_arrow ?color ?pen ?dashed ?style ?outd ?ind ?sep a b =   
  Arrow.simple ?color ?pen ?dashed (Box.cpath ?style ?outd ?ind ?sep a b)

let box_line ?color ?pen ?dashed ?style ?outd ?ind ?sep a b =   
  draw ?color ?pen ?dashed (Box.cpath ?style ?outd ?ind ?sep a b)

let box_label_line ?color ?pen ?dashed ?style ?outd ?ind ?sep ?pos lab a b =
  let p = Box.cpath ?style ?outd ?ind ?sep a b in
  draw ?color ?pen ?dashed p ++
  label ?pos lab (Path.point 0.5 p)

let box_label_arrow ?color ?pen ?dashed ?style ?outd ?ind ?sep ?pos lab a b =
  let p = Box.cpath ?style ?outd ?ind ?sep a b in
  Arrow.simple ?color ?pen ?dashed p ++
  label ?pos lab (Path.point 0.5 p)

(* TODO unify all these functions *)
let box_labelbox_arrow ?color ?pen ?dashed ?style ?outd ?ind ?sep ?pos lab a b =
  box_label_arrow ?color ?pen ?dashed ?style ?outd ?ind ?sep ?pos 
    (Picture.make (Box.draw lab)) a b

(***

let hboxjoin ?color ?pen ?dashed ?dx ?dy ?pos ?spacing pl =
  (* align the pictures in pl, put them in boxes and connect these boxes *)
  let bl = Box.halign_to_box ?dx ?pos ?spacing pl in
    match bl with
    | [] -> nop
    | hd::tl -> 
        let cmd,_ = 
          List.fold_left
          (fun (cmd,b1) b2 ->
            Box.draw b2 ++ box_arrow ?color ?pen ?dashed b1 b2 ++ cmd,b2 )
          (Box.draw hd,hd) tl
        in 
          cmd

***)
