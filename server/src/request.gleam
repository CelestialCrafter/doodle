//// https://mpd.readthedocs.io/en/latest/protocol.html#requests

import gleam/bit_array
import gleam/result
import gleam/string
import response

pub type DecodingErrorKind {
  InvalidUTF8
  UnknownCommand
  InvalidArguments
}

pub type DecodingError {
  DecodeError(command: String, kind: DecodingErrorKind)
}

pub fn error_to_response(error: DecodingError) {
  let kind = case error.kind {
    InvalidUTF8 -> response.Unknown
    UnknownCommand -> response.NoExist
    InvalidArguments -> response.Arg
  }

  response.Ack(
    kind,
    error_to_string(error),
    command: response.ErrorCommand(0, error.command),
  )
}

pub fn error_to_string(error: DecodingError) {
  case error.kind {
    InvalidUTF8 -> "invalid utf-8 in input"
    UnknownCommand -> "unknown command"
    InvalidArguments -> "invalid command arguments"
  }
}

pub type Request {
  Status
}

pub fn request_name(request) {
  case request {
    Status -> "status"
  }
}

pub fn decode_request(data: BitArray) {
  use data <- result.try(
    bit_array.to_string(data)
    |> result.map_error(fn(_) { DecodeError("", InvalidUTF8) }),
  )

  let data = string.trim_end(data)
  // TODO: handle string quoting
  let #(command, args) = case
    data
    |> string.trim_end
    |> string.split(" ")
  {
    [] -> panic as "string.split should not return an empty array"
    [command] -> #(command, [])
    [command, ..args] -> #(command, args)
  }

  case command {
    "status" -> {
      case args {
        [] -> Ok(Status)
        _ -> Error(DecodeError(command, InvalidArguments))
      }
    }
    command -> Error(DecodeError(command, UnknownCommand))
  }
}
