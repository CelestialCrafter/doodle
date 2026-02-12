//// https://mpd.readthedocs.io/en/latest/protocol.html#responses

import gleam/bit_array
import gleam/int
import gleam/string
import gleam/string_tree

pub type ErrorKind {
  NotList
  Arg
  Password
  Permission
  Unknown
  NoExist
  PlaylistMax
  System
  PlaylistLoad
  UpdateAlready
  PlayerSync
  Exist
}

fn error_kind_to_int(kind) {
  case kind {
    NotList -> 1
    Arg -> 2
    Password -> 3
    Permission -> 4
    Unknown -> 5

    NoExist -> 50
    PlaylistMax -> 51
    System -> 52
    PlaylistLoad -> 53
    UpdateAlready -> 54
    PlayerSync -> 55
    Exist -> 56
  }
}

pub type ErrorCommand {
  ErrorCommand(offset: Int, name: String)
}

pub type Response {
  Init(version: String)
  Status
  Binary(BitArray)
  Ack(kind: ErrorKind, message: String, command: ErrorCommand)
}

fn append_kv(tree, key, value) {
  string_tree.append_tree(tree, string_tree.from_strings([key, ": ", value]))
}

fn encode_ack(kind, message, command: ErrorCommand) {
  string.join(
    [
      "ACK",
      "["
        <> int.to_string(error_kind_to_int(kind))
        <> "@"
        <> int.to_string(command.offset)
        <> "]",
      "{" <> command.name <> "}",
      message,
    ],
    " ",
  )
}

pub fn encode_response(response) {
  case response {
    Init(version) -> string_tree.from_strings(["OK MPD ", version])
    Binary(data) ->
      string_tree.new()
      |> append_kv("binary", int.to_string(bit_array.byte_size(data)))
      |> string_tree.append("\nOK")
    Status -> string_tree.from_string("OK")
    Ack(kind, message, command) ->
      string_tree.from_string(encode_ack(kind, message, command))
  }
  |> string_tree.append("\n")
}
