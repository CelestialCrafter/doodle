import gleam/option.{type Option}

pub type Error =
  String

pub type FileType {
  Device
  Directory
  Other
  Regular
  Symlink
}

pub type FileInfo {
  FileInfo(size: Option(Int), ty: Option(FileType))
}

@external(erlang, "file", "list_dir")
pub fn list_dir(directory: String) -> Result(List(String), Error)

@external(erlang, "file", "get_cwd")
pub fn get_cwd() -> Result(String, Error)

@external(erlang, "file", "read_file_info")
pub fn file_info(file: String) -> Result(FileInfo, Error)

pub fn walk_directory(directory: String) -> List(Result(String, Error)) {
  todo
}
