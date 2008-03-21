
(** This is Mlpost *)

module rec Path : sig

  (** Paths *)

  (** A direction, which is useful to put constraints on paths on points
      {ul {- [Vec p] defines a direction by a point (interpreted as a vector)}
      {- [Curl f] Change the curling factor of the extremity of a path}
      {- [NoDir] means no particular direction} } *)
  type direction =
      | Vec of Point.t
      | Curl of float
      | NoDir 

  (** A [knot] is simply a point with an incoming and outgoing
      direction constraint *)
  type knot = direction * Point.t * direction

  (** A joint is the connection between two knots in a path. It is either
      {ul {- [JLine] is a straight line}
      {- [JCurve] is a spline curve}
      {- [JCurveNoInflex] avoids inflection}
      {- [JTension] permits "tension" on the joint; [JCurve] uses a default
      tension of 1. Higher tension means less "wild" curves}
      {- [JControls] permits to give control points by hand}} *)
  type joint =
      | JLine
      | JCurve
      | JCurveNoInflex
      | JTension of float * float
      | JControls of Point.t * Point.t

  (** the abstract type of paths *)
  type t

  (** {2 labelled path constructors} *)
  (** build a knot from a pair of floats 
      @param l an incoming direction
      @param r an outgoing direction *)
  val knot :
    ?l:direction -> ?r:direction -> 
    ?scale:(float -> Num.t) -> float * float -> knot

  (** build a knot from a point; the optional arguments are as in {!knot} *)
  val knotp :
    ?l:direction -> ?r:direction -> Point.t -> knot

  (** build a path from a list of floatpairs
      @param style the joint style used for all joints of the path
      @param cycle if given, the path is closed using the given style
      @param scale permits to scale the whole path *)
  val path : 
    ?style:joint -> ?cycle:joint -> ?scale:(float -> Num.t) -> 
    (float * float) list -> t

  (** same as [path], but uses a knot list *)
  val pathk :
    ?style:joint -> ?cycle:joint -> knot list -> t

  (** same as [path] but uses a point list *)
  val pathp :
    ?style:joint -> ?cycle:joint -> Point.t list -> t

  (** build a path from [n] knots and [n-1] joints *)
  val jointpathk : knot list -> joint list -> t

  (** build a path from [n] points and [n-1] joints, with default directions *)
  val jointpathp : Point.t list -> joint list -> t

  (** build a path from [n] float_pairs and [n-1] joints, with default 
      * directions *)
  val jointpath : 
    ?scale:(float -> Num.t) -> (float * float) list -> 
    joint list -> t

  (** close a path using direction [dir] and style [style] *)
  val cycle : ?dir:direction -> ?style:joint -> t -> t


  (** {2 Primitive path constructors} *)
  (** add a knot at the end of a path  *)
  val concat : ?style:joint -> t -> knot -> t

  (** lift a knot to a path *)
  val start : knot -> t

  (** append a path to another using joint [style] *)
  val append : ?style:joint -> t -> t -> t


  (** {2 More complex constructions on paths} *)

  (** [point f p] returns a certain point on the path [p]; [f] is
      given "in control points": [1.] means the first control point,
      [2.] the second and so on; intermediate values are accepted. *)

  val point : float -> t -> Point.t

  (** [subpath start end path] selects the subpath of [path] that lies
      between [start] and [end]. [start] and [end] are given in
      control points, as in {!point}. *)
    
  val subpath : float -> float -> t -> t

  (** apply a transformation to a path *)
  val transform : Transform.t -> t -> t

  (** get the bounding path of a box *)
  val bpath : Box.t -> t

  (** [cut_after p1 p2] cuts [p2] after the intersection with [p1]. To memorize
      the order of the arguments, you can read: "cut after [p1]" *)
  val cut_after : t -> t -> t

  (** same as {!cut_after}, but cuts before *)
  val cut_before: t -> t -> t

  (** builds a cycle from a set of intersecting paths *)
  val build_cycle : t list -> t


  (** {2 Predefined values} *)

  val defaultjoint : joint
  val fullcircle : t
  val halfcircle : t
  val quartercircle: t
  val unitsquare: t

end

and SimplePoint : sig

  type t = Point.t
      (* construct a point with the right measure *)
  val bpp : float * float -> Point.t
  val inp : float * float -> Point.t
  val cmp : float * float -> Point.t
  val mmp : float * float -> Point.t
  val ptp : float * float -> Point.t

  (* construct a list of points with the right measure *)
  val map_bp : (float * float) list -> Point.t list
  val map_in: (float * float) list -> Point.t list
  val map_cm: (float * float) list -> Point.t list
  val map_mm: (float * float) list -> Point.t list
  val map_pt: (float * float) list -> Point.t list

  (* might be useful to give another measure *)
  val p : ?scale:(float -> Num.t) -> float * float -> Point.t
  val ptlist : ?scale:(float -> Num.t) -> (float * float) list -> Point.t list


  (* the other functions of Point duplicated *)
  val dir : float -> t
  val up : t
  val down : t
  val left : t
  val right : t

  val north : Name.t -> t
  val south : Name.t -> t
  val west  : Name.t -> t
  val east  : Name.t -> t
  val north_west : Name.t -> t
  val south_west : Name.t -> t
  val north_east : Name.t -> t
  val south_east : Name.t -> t

  val segment : float -> t -> t -> t

  (* operations on points *)
  val add : t -> t -> t
  val sub : t -> t -> t
  val mult : float -> t -> t
  val rotated : float -> t -> t

end

and Point : sig

  type t

  val p : Num.t * Num.t -> t
    (* These functions create points of "unspecified" size, ie vectors
       to use with Vec for instance *)
  val dir : float -> t
  val up : t
  val down : t
  val left : t
  val right : t

  val north : Name.t -> t
  val south : Name.t -> t
  val west  : Name.t -> t
  val east  : Name.t -> t
  val north_west : Name.t -> t
  val south_west : Name.t -> t
  val north_east : Name.t -> t
  val south_east : Name.t -> t

  val segment : float -> t -> t -> t

  (* operations on points *)
  val add : t -> t -> t
  val sub : t -> t -> t
  val mult : float -> t -> t
  val rotated : float -> t -> t

end

and Box : sig

  (** Boxes *)

  type t
      (** the abstract type of boxes *)

  (** {2 Creating boxes} *)

  type circle_style =
      | Padding of Num.t * Num.t (** dx , dy *)
      | Ratio of float           (** dx / dy *)

  val circle : ?style:circle_style -> Point.t -> Picture.t -> t
    (** [circle p pic] creates a circle box of center [p] and of contents
	[pic] *)

  val rect : Point.t -> Picture.t -> t
    (** [rect p pic] creates a rectangular box of center [p] and of contents
	[pic] *)

  (** {2 Special points of a box} *)

  val center : t -> Point.t
  val north : t -> Point.t
  val south : t -> Point.t
  val west  : t -> Point.t
  val east  : t -> Point.t 
  val north_west : t -> Point.t
  val south_west : t -> Point.t
  val north_east : t -> Point.t
  val south_east : t -> Point.t

end

and Num : sig

  (** The Mlpost Num module *)

  type t = float
      (** The Mlpost numeric type is just a float *)

  (** {2 Conversion functions} *)
  (** The base unit in Mlpost are bp. The following functions permit to specify
      values in other common units *)

  val bp : float -> t
  val pt : float -> t
  val cm : float -> t
  val mm : float -> t
  val inch : float -> t

  type scale = float -> t

  module Scale : sig
    val bp : float -> scale
    val pt : float -> scale
    val cm : float -> scale
    val mm : float -> scale
    val inch : float -> scale
  end

end

and Transform : sig

  type t'

  val scaled : ?scale:(float -> Num.t) -> float -> t'
  val rotated : float -> t'
  val shifted : Point.t -> t'
  val slanted : Num.t -> t'
  val xscaled : Num.t -> t'
  val yscaled : Num.t -> t'
  val zscaled : Point.t -> t'
  val reflect : Point.t -> Point.t -> t'
  val rotate_around : Point.t -> float -> t'

  type t = t' list
  val id : t


end

and Picture : sig

  type t

  val tex : string -> t

  val make : Command.t list -> t
  val currentpicture : t

  val transform : Transform.t -> t -> t

  val bbox : t -> Path.t
  val ulcorner : t -> Point.t
  val llcorner : t -> Point.t
  val urcorner : t -> Point.t
  val lrcorner : t -> Point.t

end

and Convenience : sig

  (** the Convenience Module *)

  val draw : 
    ?style:Path.joint -> ?cycle:Path.joint -> ?scale:(float -> Num.t) ->
    ?color:Color.t -> ?pen:Pen.t -> (float * float) list -> Command.t
    (** a convenient method to draw a simple path
	@param style the joint style used for all joints of the path
	@param cycle if given, the path is closed using the given style
	@param scale permits to scale the whole path
	@param color permits to give a color to draw the path; default is black
	@param pen the pen to draw the path *)

end

and Command : sig

  (** General Commands to build figures *)

  type t
      (** the abstract commands type *)

  type figure = t list
      (** a figure is a list of commands *)


  (** {2 Drawing Commands} *)

  val draw : ?color:Color.t -> ?pen:Pen.t -> ?dashed:Dash.t -> Path.t -> t
    (** draw a path 
	@param color the color of the path; default is black
	@param pen the pen used to draw the path; default is {!Pen.default}
	@param dashed if given, the path is drawn using that dash_style. *)

  val draw_arrow : ?color:Color.t -> ?pen:Pen.t -> ?dashed:Dash.t -> Path.t -> t
    (** draw a path with an arrow head; the optional arguments are the same as for
	{!draw} *)

  val fill : ?color:Color.t -> Path.t -> t
    (** fill a contour given by a closed path 
	@param color the color used to fill the area; default is black *)

  val draw_box : ?fill:Color.t -> Box.t -> t
    (** draw a box 
	@param fill the color used to fill the box *)

  val draw_pic : Picture.t -> t
    (** draws a picture *) 

  (** {2 Manipulating Commands} *)

  val iter : int -> int -> (int -> t list) -> t
    (** [iter m n f] builds a command that corresponds to the sequence
	f m; f (m+1); ... ; f(n) of commands *)

  val append : t -> t -> t
    (** append two commands to form a compound command *)

  val (++) : t -> t -> t
    (** abbreviation for [append] *)
  val seq : t list -> t
    (** group a list of commands to a single command *)

  (** {2 Labels} *)

  (** Positions; useful to place labels *)
  type position =
      | Pcenter
      | Pleft
      | Pright
      | Ptop
      | Pbot
      | Pupleft
      | Pupright
      | Plowleft
      | Plowright

  (** [label ~pos:Pleft pic p] puts picture [pic] at the left of point [p] *)
  val label : ?pos:position -> Picture.t -> Point.t -> t

  (** works like [label], but puts a dot at point [p] as well *)
  val dotlabel : ?pos:position -> Picture.t -> Point.t -> t

end

and Helpers : sig
  val dotlabels :
    ?pos:Command.position -> string list -> Point.t list -> Command.t list
  val draw_simple_arrow :
    ?color:Color.t ->
    ?pen:Pen.t -> ?style:Path.joint -> Point.t -> Point.t -> Command.t
  val draw_label_arrow :
    ?color:Color.t ->
    ?pen:Pen.t ->
    ?style:Path.joint ->
    ?pos:Command.position -> Picture.t -> Point.t -> Point.t -> Command.t
  val box_path :
    style:PrimPath.joint ->
    outd:PrimPath.direction ->
    ind:PrimPath.direction -> Box.t -> Box.t -> Path.t
  val box_arrow :
    ?color:Color.t ->
    ?pen:Pen.t ->
    ?style:Path.joint ->
    ?outd:Path.direction -> ?ind:Path.direction -> Box.t -> Box.t -> Command.t
  val box_line :
    ?color:Color.t ->
    ?pen:Pen.t ->
    ?style:Path.joint ->
    ?outd:Path.direction -> ?ind:Path.direction -> Box.t -> Box.t -> Command.t
  val box_simple_arrow :
    ?color:Color.t -> ?pen:Pen.t -> Box.t -> Box.t -> Command.t
  val box_label_arrow :
    ?color:Color.t ->
    ?pen:Pen.t ->
    ?style:Path.joint ->
    ?outd:Path.direction ->
    ?ind:Path.direction ->
    ?pos:Command.position -> Picture.t -> Box.t -> Box.t -> Command.t

end

and Pen : sig

  type t

  val transform : Transform.t -> t -> t
  val default : ?tr:Transform.t -> unit -> t
  val circle : ?tr:Transform.t -> unit -> t
  val square : ?tr:Transform.t -> unit -> t
  val from_path : Path.t -> t

end

and Dash : sig

  type t

  val evenly : t
  val withdots : t

  val scaled : float -> t -> t
  val shifted : Point.t -> t -> t

  type on_off = On of Num.t | Off of Num.t

  val pattern : on_off list -> t


end

and Color : sig

  (** Colors *)

  type t
      (** the abstract type of Colors *)

  val default : t
    (** the default Color is black *)

  val rgb : float -> float -> float -> t
    (** [rgb r g b] constructs the color that corresponds to the color code 
	RGB(r,g,b)  *)

  (** {2 Predefined Colors} *)

  val red : t
  val orange : t
  val blue : t
  val purple : t
  val gray : float -> t
  val white : t
  val black : t
  val green : t
  val cyan : t
  val blue : t
  val yellow : t
  val magenta : t
  val orange : t
  val purple : t

end

module Tree : sig

  (** Trees *)

  type t
      (** the abstract type of trees *)

  (** {2 Creation} *)

  type node_style = Circle | Rect

  val leaf : ?style:node_style -> ?fill:Color.t -> string -> t
  val node : ?style:node_style -> ?fill:Color.t -> string -> t list -> t
  val bin  : ?style:node_style -> ?fill:Color.t -> string -> t -> t -> t

  (** variants to create trees with pictures at nodes *)
  module Pic : sig
    val leaf : ?style:node_style -> ?fill:Color.t -> Picture.t -> t
    val node : ?style:node_style -> ?fill:Color.t -> Picture.t -> t list -> t
    val bin  : ?style:node_style -> ?fill:Color.t -> Picture.t -> t -> t -> t
  end

  (** {2 Drawing} *)

  type arrow_style = Directed | Undirected

  type edge_style = Straight | Curve | Square | HalfSquare

  val draw : 
    ?scale:(float -> Num.t) -> 
    ?node_style:node_style -> ?arrow_style:arrow_style -> 
    ?edge_style:edge_style ->
    ?fill:Color.t -> ?stroke:Color.t -> ?pen:Pen.t ->
    ?ls:float -> ?nw:float -> ?cs:float -> 
    t -> Command.figure
    (** Default scale is [Num.cm]. 
	Drawing parameters are:
	- [ls] (level sep): vertical distance between levels.
        The default value is 1.0. A negative value draws the tree upward.
	- [nw] (node width): width of one node. The default value is 0.5.
	- [cs] (children sep): horizontal distance between siblings.
        The default value is 0.2.
    *)

end

module Diag : sig

  (** Diagrams. *)

  (** 1. Creation *)

  type node

  val node : float -> float -> string -> node
  val pic_node : float -> float -> Picture.t -> node

  type t

  val create : node list -> t

  type dir = Up | Down | Left | Right | Angle of float

  val arrow : 
    t -> ?lab:string -> ?pos:Command.position -> 
    ?outd:dir -> ?ind:dir -> node -> node -> unit

  (** 2. Drawing *)

  type node_style = Circle | Rect

  val draw : 
    ?scale:(float -> Num.t) -> ?style:node_style -> 
    ?fill:Color.t -> ?stroke:Color.t -> ?pen:Pen.t ->
    t -> Command.figure
    (** default scale is 40bp *)

end

(** {2 Metapost generation} *)

module Metapost : sig

  val generate_mp :
    string ->
    ?prelude:(Format.formatter -> unit -> unit) ->
    (int * Command.t list) list -> unit
  val emit : int -> Command.t list -> unit
  val dump : string -> unit

end

module Generate : sig
  val generate_tex : string -> string -> string -> (int * 'a) list -> unit
end

module Misc : sig
  val write_to_file : string -> (out_channel -> 'a) -> unit
  val write_to_formatted_file : string -> (Format.formatter -> 'a) -> unit
  val pi : float
  val deg2rad : float -> float
  val print_option :
    string ->
    (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a option -> unit
  val print_list :
    ('a -> unit -> 'b) -> ('a -> 'c -> unit) -> 'a -> 'c list -> unit
  val space : Format.formatter -> unit -> unit
  val comma : Format.formatter -> unit -> unit
end
