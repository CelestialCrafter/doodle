import gleam/dict.{type Dict}

pub type Metadata {
  Metadata(tags: Dict(String, String))
}

@external(erlang, "doodle_core", "flac_metadata")
pub fn flac_metadata(path: String) -> Result(Metadata, String)
