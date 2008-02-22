type numtype = BP | PT | CM | MM | IN

val draw : 
    ?style:Path.joint -> ?cycle:Path.joint -> ?scale:numtype ->
      ?color:Color.t -> ?pen:Pen.t -> (float * float) list -> Mlpost.command

val path : 
    ?style:Path.joint -> ?cycle:Path.joint -> ?scale:numtype -> 
      (float * float) list -> Path.t

val jointpath : 
    ?scale:numtype -> (float * float) list -> Path.joint list -> Path.t

val p :
    ?l:Path.direction -> ?r:Path.direction -> 
      ?scale:numtype -> float * float -> Path.knot
