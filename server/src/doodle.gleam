import action
import gleam/bytes_tree
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/result
import gleam/string
import glisten.{Packet}
import request
import response

/// https://mpd.readthedocs.io/en/latest/protocol.html#protocol-overview
pub const version = "0.25.0"

fn log_client_action(conn, func) {
  case glisten.get_client_info(conn) {
    Ok(info) -> io.println_error(func(info))
    Error(Nil) -> io.println_error("could not get client info")
  }
}

fn send_response(response, conn) {
  response
  |> response.encode_response
  |> bytes_tree.from_string_tree
  |> glisten.send(conn, _)
  |> fn(result) {
    case result {
      Error(error) ->
        io.println_error("could not send packet " <> string.inspect(error))
      Ok(_) -> Nil
    }
  }
}

pub fn main() -> Nil {
  let assert Ok(_) =
    glisten.new(
      fn(conn) {
        log_client_action(conn, fn(info) {
          "client "
          <> glisten.ip_address_to_string(info.ip_address)
          <> " connected on port "
          <> int.to_string(info.port)
        })

        send_response(response.Init(version), conn)

        #(Nil, None)
      },
      fn(state, msg, conn) {
        let assert Packet(msg) = msg

        msg
        |> request.decode_request
        |> result.map_error(request.error_to_response)
        |> result.try(action.request_to_response)
        |> fn(result) {
          case result {
            Ok(response) -> response
            Error(response) -> response
          }
        }
        |> send_response(conn)

        glisten.continue(state)
      },
    )
    |> glisten.bind("0.0.0.0")
    |> glisten.start(6600)

  process.sleep_forever()
}
