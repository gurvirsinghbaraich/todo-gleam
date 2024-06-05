import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

import app/auth
import app/controllers
import app/middleware

pub fn handle_request(request: Request) -> Response {
  use request <- middleware.apply(request)
  // The code below matches the requested path and runs
  // the specified controller function for the following request.
  // Additionally, this block of code automatically returns a 404
  // response if no match is found.
  case request.method, wisp.path_segments(request) {
    // Listing all the GET methods
    Get, [] -> controllers.landing_page(request)
    Get, ["login"] -> controllers.login_page(request)
    Get, ["register"] -> controllers.register_page(request)
    Get, ["logout"] -> auth.logout_user(request)

    // Listing all the POST methods
    Post, [] -> controllers.add_todo(request)
    Post, ["login"] -> auth.login_controller(request)
    Post, ["register"] -> auth.register_user(request)
    Post, ["api", "edit-todo"] -> controllers.edit_todo(request)

    // Forcing that the request method can only be GET or POST.
    Get, _ -> wisp.not_found()
    Post, _ -> wisp.not_found()
    _, _ -> wisp.method_not_allowed([Get, Post])
  }
}
