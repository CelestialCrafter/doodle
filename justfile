run:
   (cd core && cargo build)
   mkdir -p lib
   ln -sf "$(realpath core/target/debug/libdoodle_core.so)" lib/
   (cd server && gleam run)
