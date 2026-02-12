use std::{
    collections::{BTreeMap, HashMap},
    error::Error,
    fs,
    path::{Path, PathBuf},
};

use claxon::{FlacReader, FlacReaderOptions};
use rustler::{NifRecord, SerdeTerm, Term};
use serde::Serialize;
use smol_str::SmolStr;

trait ErrorCompat<T> {
    fn compat(self) -> Result<T, String>;
}

impl<T, E: Error> ErrorCompat<T> for Result<T, E> {
    fn compat(self) -> Result<T, String> {
        self.map_err(|err| err.to_string())
    }
}

#[derive(Debug, Serialize)]
struct Metadata {
    tags: BTreeMap<SmolStr, SmolStr>,
}

#[rustler::nif(schedule = "DirtyIo")]
pub fn flac_metadata(path: &Path) -> Result<SerdeTerm<Metadata>, String> {
    let reader = FlacReader::open_ext(
        path,
        FlacReaderOptions {
            metadata_only: true,
            ..Default::default()
        },
    )
    .compat()?;

    let tags = reader
        .tags()
        .map(|(k, v)| (k.into(), v.into()))
        .collect();
    Ok(SerdeTerm(Metadata { tags }))
}

rustler::init!("doodle_core");
