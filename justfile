interact:
   socat - TCP4:0.0.0.0:6600

run:
   (cd core && cargo build)
   mkdir -p lib
   ln -sf "$(realpath core/target/debug/libdoodle_core.so)" lib/
   (cd server && gleam run)
