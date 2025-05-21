import gleam/bit_array
import gleam/bytes_tree
import gleam/dict
import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/io
import gleam/result
import gleam/uri
import mist
import song
import sqlight

pub type Play {
  Play(duration: Int, timestamp: Int, song: song.Song)
}

type ScrobbleError {
  ReadError(mist.ReadError)
  DatabaseError(sqlight.Error)
  InvalidUtf8
  InvalidBody
  MissingFields
}

pub fn scrobble(req, conn) {
  case
    query_from_request(req)
    |> result.try(fn(query) {
      play_from_query(query)
      |> result.map_error(fn(_) { MissingFields })
    })
    |> result.try(fn(play) {
      save_play(play, conn)
      |> result.map_error(fn(err) { DatabaseError(err) })
    })
  {
    Ok(_) -> {
      response.new(200)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("success")))
    }
    Error(err) -> {
      let err = scrobble_error_to_string(err)
      io.println_error(err)

      response.new(400)
      |> response.set_body(mist.Bytes(bytes_tree.from_string(err)))
    }
  }
}

fn scrobble_error_to_string(err) {
  case err {
    ReadError(read_err) ->
      case read_err {
        mist.ExcessBody -> "excess body"
        mist.MalformedBody -> "malformed body"
      }
    DatabaseError(db_err) ->
      case db_err {
        sqlight.SqlightError(code, msg, _) ->
          "db error "
          <> int.to_string(sqlight.error_code_to_int(code))
          <> ": "
          <> msg
      }
    InvalidUtf8 -> "non utf-8 characters in body"
    InvalidBody -> "invalid body"
    MissingFields -> "missing field title/artist/album/length"
  }
}

fn query_from_request(req) {
  mist.read_body(req, 1024 * 1024 * 10)
  |> result.map_error(fn(err) { ReadError(err) })
  |> result.try(fn(req) {
    bit_array.to_string(req.body)
    |> result.map_error(fn(_) { InvalidUtf8 })
  })
  |> result.try(fn(query) {
    uri.parse_query(query)
    |> result.map_error(fn(_) { InvalidBody })
  })
  |> result.map(dict.from_list)
}

fn play_from_query(query) {
  use title <- result.try(dict.get(query, "title"))
  use artist <- result.try(dict.get(query, "artist"))
  use album <- result.try(dict.get(query, "album"))
  use length <- result.try(
    dict.get(query, "length")
    |> result.try(int.parse),
  )
  use timestamp <- result.try(
    dict.get(query, "timestamp")
    |> result.try(int.parse),
  )
  use duration <- result.map(
    dict.get(query, "duration")
    |> result.try(int.parse),
  )

  Play(
    duration,
    timestamp,
    song.Song(
      title:,
      artist:,
      album:,
      length:,
      id: dict.get(query, "mbid")
        |> result.map(fn(id) { song.MusicBrainz(id) })
        |> result.unwrap(song.generate_id(title, artist)),
    ),
  )
}

fn save_play(play: Play, conn) {
  let song = play.song
  io.println_error(
    "scrobbling \""
    <> song.title
    <> " - "
    <> song.artist
    <> "\" at "
    <> int.to_string(play.duration)
    <> "ms",
  )

  sqlight.query(
    "INSERT INTO songs (id, title, artist, album, length) VALUES (?, ?, ?, ?, ?) ON CONFLICT DO NOTHING",
    on: conn,
    with: [
      sqlight.text(song.id_to_string(song.id)),
      sqlight.text(song.title),
      sqlight.text(song.artist),
      sqlight.text(song.album),
      sqlight.int(song.length),
    ],
    expecting: decode.success(#()),
  )
  |> result.try(fn(_) {
    sqlight.query(
      "INSERT INTO plays (timestamp, duration, id) VALUES (?, ?, ?)",
      on: conn,
      with: [
        sqlight.int(play.timestamp),
        sqlight.int(play.duration),
        sqlight.text(song.id_to_string(song.id)),
      ],
      expecting: decode.success(#()),
    )
  })
}
