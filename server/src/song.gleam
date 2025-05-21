import gleam/bit_array
import gleam/crypto
import gleam/string

pub type SongId {
  MusicBrainz(String)
  Custom(String)
}

pub type Song {
  Song(id: SongId, title: String, artist: String, album: String, length: Int)
}

pub fn generate_id(title, artist) {
  Custom(
    "cstm|"
    <> bit_array.from_string(title <> artist)
    |> crypto.hash(crypto.Sha1, _)
    |> bit_array.base16_encode
    // uppercase hex reminds me of mi*rosoft idk why
    |> string.lowercase,
  )
}

pub fn id_to_string(id: SongId) {
  case id {
    MusicBrainz(id) -> id
    Custom(id) -> id
  }
}
