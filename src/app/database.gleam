import gleam/dynamic
import sqlight.{type Connection}

pub fn pipe(query_fn) {
  sqlight.with_connection("db.sql", query_fn)
}

pub fn get_todos(userid: Int) {
  fn(connection: Connection) {
    let decoder =
      dynamic.tuple4(dynamic.int, dynamic.int, dynamic.string, dynamic.string)

    sqlight.query(
      "SELECT id, completed, title, description FROM todos WHERE userid = ? ORDER BY id DESC;",
      on: connection,
      with: [sqlight.int(userid)],
      expecting: decoder,
    )
  }
}
