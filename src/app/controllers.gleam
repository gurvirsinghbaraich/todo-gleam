import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string_builder.{type StringBuilder}
import sqlight
import wisp.{type Request}

import app/auth
import app/database
import app/views

// A helper function that returns a 200 response with
// the contents specified.
fn send(view_fn: fn() -> Result(StringBuilder, StringBuilder)) {
  // Getting the contents that would be sent back to the client. 
  let contents =
    view_fn()
    |> result.unwrap_both

  // Returning a 200 response with the loaded contents.
  wisp.ok()
  |> wisp.html_body(contents)
}

// A controller function that is used to handle the logic
// for the home page.
pub fn landing_page(request: Request) {
  // Trying to get the authentication cookie from the request.
  let cookie = auth.is_cookie_valid(request)

  // Routing based on whether the cookie has been provided or not.
  case cookie {
    True -> fn() { views.landing_page_contents(request) } |> send
    False -> wisp.redirect("/login")
  }
}

// A controller funciton that is used to handle the logic
// for the login page.
pub fn login_page(request: Request) {
  // Trying to get the authentication cookie from the request.
  let cookie = auth.is_cookie_valid(request)

  // Routing based on whether the cookie has been provided or not.
  case cookie {
    True -> wisp.redirect("/")
    False -> views.login_page_contents |> send
  }
}

// A controlller function that is used to handle the logic
// for the register page.
pub fn register_page(request: Request) {
  // Trying to get the authentication cookie from the request.
  let cookie = auth.is_cookie_valid(request)

  // Routing based on whether the cookie has been provided or not.
  case cookie {
    True -> wisp.redirect("/")
    False -> views.register_page_contents |> send
  }
}

pub fn add_todo(request: Request) {
  use formdata <- wisp.require_form(request)
  let cookie = auth.is_cookie_valid(request)
  let assert Ok(userid) = auth.cookie(request) |> int.parse

  case cookie {
    False ->
      wisp.html_response("Unauthorized!!" |> string_builder.from_string, 401)
    True -> {
      let assert Ok(title) = formdata.values |> list.key_find("title")

      let assert Ok(_) =
        fn(connection) {
          sqlight.query(
            "INSERT INTO todos (userid, title, description, completed) VALUES (?, ?, '...', 0)",
            on: connection,
            with: [sqlight.int(userid), sqlight.text(title)],
            expecting: dynamic.dynamic,
          )
        }
        |> database.pipe

      wisp.redirect("/")
    }
  }
}

pub type Todo {
  Todo(title: String, status: Int, todo_id: Int)
}

fn decode_todo(json: Dynamic) {
  let decoder =
    dynamic.decode3(
      Todo,
      dynamic.field("title", dynamic.string),
      dynamic.field("status", dynamic.int),
      dynamic.field("todo_id", dynamic.int),
    )

  decoder(json)
}

pub fn edit_todo(request) {
  let cookie = auth.is_cookie_valid(request)
  use json <- wisp.require_json(request)

  case cookie {
    False ->
      wisp.json_response(
        "{'status': 'unauthorized'}" |> string_builder.from_string,
        401,
      )
    True -> {
      let assert Ok(userid) = auth.cookie(request) |> int.parse
      let assert Ok(todo_item) = {
        use todo_item <- result.try(decode_todo(json))
        Ok(todo_item)
      }

      // Saving the todo
      let assert Ok(_) =
        fn(connection) {
          sqlight.query(
            "UPDATE todos SET title = ?, completed = ? WHERE id = ? AND userid = ?",
            on: connection,
            with: [
              sqlight.text(todo_item.title),
              sqlight.int(todo_item.status),
              sqlight.int(todo_item.todo_id),
              sqlight.int(userid),
            ],
            expecting: dynamic.dynamic,
          )
        }
        |> database.pipe

      wisp.json_response(
        {
          json.object([
            #("todo_id", json.int(todo_item.todo_id)),
            #("completed", json.int(todo_item.status)),
            #("title", json.string(todo_item.title)),
          ])
          |> json.to_string
          |> string_builder.from_string
        },
        200,
      )
    }
  }
}
