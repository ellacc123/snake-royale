open! Base
open! Snake_lib

let%expect_test "test basic trie functionality" =
  let trie = Trie.create () in
  let dictionary =
    [ "foo"
    ; "bar"
    ; "baz"
    ; "ba"
    ; "hello"
    ; "world"
    ; "a"
    ; "ado"
    ; "do"
    ; "dog"
    ; "dogs"
    ]
  in
  let () = List.iter dictionary ~f:(fun word -> Trie.insert trie ~word) in
  let tests =
    [ "dog", Some "dog"
    ; "dogba", Some "dog"
    ; "apple", Some "a"
    ; "adogs", Some "ado"
    ; "pear", None
    ; "bfoo", None
    ; "bazhello", Some "baz"
    ]
  in
  List.iter tests ~f:(fun (word, answer) ->
    let test_result = Trie.get_longest_valid_prefix trie word in
    assert ([%equal: string option] test_result answer))
;;
