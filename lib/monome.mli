type device

val create : ?address:string -> unit -> device option
val destroy : device -> unit
val get_name : device -> string
