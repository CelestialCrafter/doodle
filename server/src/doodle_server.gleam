import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/list
import mist
import scrobble
import sqlight

pub fn main() {
  use conn <- sqlight.with_connection("file:database.db")
  let assert Ok(_) = initialize_database(conn)

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_tree.from_string("not found!!")))

  let assert Ok(_) =
    fn(req) {
      case request.path_segments(req) {
        ["scrobble"] -> scrobble.scrobble(req, conn)
        _ -> not_found
      }
    }
    |> mist.new()
    |> mist.port(8540)
    |> mist.start_http

  process.sleep_forever()
}

fn initialize_database(conn) {
  [
    "CREATE TABLE IF NOT EXISTS songs (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		artist TEXT NOT NULL,
		album TEXT NOT NULL,
		length INT NOT NULL
	)",
    "CREATE TABLE IF NOT EXISTS plays (
		timestamp INT PRIMARY KEY,
		duration INT NOT NULL,
		id TEXT NOT NULL
	)",
  ]
  |> list.try_fold(Nil, fn(_, sql) { sqlight.exec(sql, conn) })
}
