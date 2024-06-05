import gleam/erlang/process
import gleam/result.{try}

import glenvy/dotenv
import glenvy/env
import mist
import wisp

import app/migrations
import app/router

pub fn main() {
  // Making sure that the execution of the code only 
  // continues if the environment variables have been loaded.
  let assert Ok(_) = dotenv.load()
  use secret_key <- try(env.get_string("SECRET_KEY"))

  // Loading the tables into the database
  let assert Ok(Nil) = migrations.load_migrations()

  // Iniciating a process to configure INFO level logs for
  // the Wisp logger.
  wisp.configure_logger()

  // Trying to start the webserver on PORT 8080.
  let assert Ok(_) =
    wisp.mist_handler(router.handle_request, secret_key)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  // Once the code execution reaches here, we are sure that the
  // webserver has started listening on the specified server PORT,
  // When starting a new server using mist the server execution happens
  // on a new Erlang process that runs concurrently, so we put this
  // thread into sleep.
  process.sleep_forever()
  Ok(Nil)
}
