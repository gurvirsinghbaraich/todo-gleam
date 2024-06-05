import gleam/int
import gleam/list
import gleam/string_builder.{type StringBuilder}
import wisp.{type Request}

import app/auth
import app/database

pub fn todos(parts: #(String, String), request: Request) -> StringBuilder {
  let cookie = auth.cookie(request)
  let assert Ok(userid) = cookie |> int.parse
  let assert Ok(todos) = database.get_todos(userid) |> database.pipe

  let todo_items =
    todos
    |> list.map(fn(todo_item) {
      ""
      |> string_builder.from_string
      |> string_builder.append(
        {
          "<li class='border-b p-2 capitalize cursor-pointer"
          <> case todo_item.1 {
            0 -> ""
            _ -> " line-through"
          }
          <> "'>"
        }
        <> {
          "<div title='toogle status' onclick='toggle(this)' "
          <> { "data-todo-id='" <> todo_item.0 |> int.to_string <> "' " }
          <> { "data-status='" <> todo_item.1 |> int.to_string <> "'>" }
          <> todo_item.2
          <> "</div>"
        }
        <> "</li>",
      )
    })

  let insertion = case list.length(todos) {
    0 -> "You haven't added a todo yet!"
    _ -> string_builder.concat(todo_items) |> string_builder.to_string
  }

  { parts.0 <> insertion <> parts.1 }
  |> string_builder.from_string
}
