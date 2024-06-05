import gleam/result.{try}
import gleam/string
import gleam/string_builder
import simplifile
import wisp.{type Request}

import app/embed

// A helper function responsible for getting reading a file
// and retuting its contents as StringBuilder.
fn get_file_contents(path: String) {
  use contents <- try(
    simplifile.read(path)
    |> result.map_error(fn(a) {
      simplifile.describe_error(a)
      |> string_builder.from_string
    }),
  )

  Ok(string_builder.from_string(contents))
}

pub fn landing_page_contents(request: Request) {
  let assert Ok(contents) = get_file_contents("views/index.html")

  case string.split(contents |> string_builder.to_string, "...todos...") {
    [head, tail] -> Ok(#(head, tail) |> embed.todos(request))
    _ -> Ok(contents)
  }
}

pub fn login_page_contents() {
  get_file_contents("views/login.html")
}

pub fn register_page_contents() {
  get_file_contents("views/register.html")
}
