import gleam/dynamic
import gleam/int
import gleam/list
import gleam/result.{try}
import sqlight
import wisp.{type Request}

import app/database

pub fn cookie(request: Request) {
  let cookie = case wisp.get_cookie(request, "session", wisp.Signed) {
    Ok(cookie) -> cookie
    _ -> ""
  }

  cookie
}

pub fn is_cookie_valid(request: Request) {
  let cookie = cookie(request)

  let assert Ok(user) =
    fn(connection) {
      sqlight.query(
        "SELECT id, username FROM users WHERE id = ? LIMIT 1",
        on: connection,
        with: [sqlight.text(cookie)],
        expecting: dynamic.tuple2(dynamic.int, dynamic.string),
      )
    }
    |> database.pipe

  case list.first(user) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn login_controller(request: Request) {
  // The require_form middleware makes sure the incoming request,
  // has content type of `application/x-www-form-urlencoded` or
  // `multipart/form-data` as this controller should only work
  // with form submitions.
  use formdata <- wisp.require_form(request)

  let username = {
    use username <- try(formdata.values |> list.key_find("username"))
    Ok(username)
  }

  let password = {
    use password <- try(formdata.values |> list.key_find("password"))
    Ok(password)
  }

  case username, password {
    Ok(username), Ok(password) -> {
      let user_decoder =
        dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string)

      let user = {
        database.pipe(fn(connection) {
          sqlight.query(
            "SELECT id, username, password FROM users WHERE username = ? AND password = ? LIMIT 1",
            on: connection,
            expecting: user_decoder,
            with: [sqlight.text(username), sqlight.text(password)],
          )
        })
      }

      case user {
        Ok(user) -> {
          case list.first(user) {
            Ok(user) -> {
              wisp.redirect("/")
              |> wisp.set_cookie(
                request,
                "session",
                user.0 |> int.to_string,
                wisp.Signed,
                60 * 5,
              )
            }
            Error(_) -> wisp.redirect("/login?error=invalid_credentials")
          }
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
    _, _ -> wisp.bad_request()
  }
}

pub fn register_user(request: Request) {
  // The require_form middleware makes sure the incoming request,
  // has content type of `application/x-www-form-urlencoded` or
  // `multipart/form-data` as this controller should only work
  // with form submitions.
  use formdata <- wisp.require_form(request)

  let username = formdata.values |> list.key_find("username")
  let password = formdata.values |> list.key_find("password")

  case username, password {
    Ok(username), Ok(password) -> {
      let assert Ok(_) =
        database.pipe(fn(connection) {
          sqlight.query(
            "INSERT INTO users (username, password) VALUES (?, ?)",
            expecting: dynamic.dynamic,
            on: connection,
            with: [sqlight.text(username), sqlight.text(password)],
          )
        })

      wisp.redirect("/login")
    }
    _, _ -> wisp.bad_request()
  }
}

pub fn logout_user(request: Request) {
  wisp.redirect("/login")
  |> wisp.set_cookie(request, "session", "", wisp.Signed, 0)
}
