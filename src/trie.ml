open! Core

type t = unit

let create () = ()

let insert t ~word =
  ignore t;
  ignore word
;;

let get_longest_valid_prefix t str =
  ignore (t : t);
  ignore (str : string);
  None
;;
