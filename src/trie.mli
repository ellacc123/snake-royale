open! Core

type t

val create : unit -> t
val insert : t -> word:string -> unit
val get_longest_valid_prefix : t -> string -> string option
