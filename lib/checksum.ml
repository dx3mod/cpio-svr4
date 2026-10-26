let calculate_for_string_content content =
  String.fold_left (fun summa ch -> summa + int_of_char ch) 0 content

let calculate_for_bigstring_content content =
  Bstr.fold_left (fun summa ch -> summa + int_of_char ch) 0 content
