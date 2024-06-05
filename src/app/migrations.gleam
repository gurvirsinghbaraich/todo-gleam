import app/database
import sqlight.{type Connection}

pub fn load_migrations() {
  let users_table = database.pipe(create_user_table)
  let todos_table = database.pipe(create_todos_table)

  case users_table, todos_table {
    Ok(Nil), Ok(Nil) -> Ok(Nil)

    Error(error), _ -> Error(error)
    _, Error(error) -> Error(error)
  }
}

// A helper function that is used to create `users` tables.
fn create_user_table(connection: Connection) {
  sqlight.exec(
    "
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username VARCHAR(255) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL
    );
  ",
    on: connection,
  )
}

// A helper function that is used to create `todos` tables.
fn create_todos_table(connection: Connection) {
  sqlight.exec(
    "
    CREATE TABLE IF NOT EXISTS todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userid INT NOT NULL,
      title VARCHAR(255) NOT NULL,
      description VARCHAR(255) NOT NULL DEFAULT NULL
    );
  ",
    on: connection,
  )
}
