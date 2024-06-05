import wisp.{type Request, type Response}

pub fn apply(
  request: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  // Allows different types requests to be processed instead of just (GET, POST).
  let request = wisp.method_override(request)

  // Logs information about the current request to the console.
  use <- wisp.log_request(request)

  // Returns a 500 response by default if the request handler crashes.
  use <- wisp.rescue_crashes
  use request <- wisp.handle_head(request)

  // Using a middleware function to server static assets as well.
  let assert Ok(installation_path) = wisp.priv_directory(".")
  use <- wisp.serve_static(
    request,
    under: "/static",
    from: installation_path <> "/static",
  )

  handle_request(request)
}
