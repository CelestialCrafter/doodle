-module(doodle_core).
-export([walk_directory/1, flac_metadata/1]).
-nifs([walk_directory/1, flac_metadata/1]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("../lib/libdoodle_core", 0).

walk_directory(root) ->
    exit(nif_library_not_loaded).

flac_metadata(path) ->
    exit(nif_library_not_loaded).
