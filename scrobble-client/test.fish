#!/usr/bin/env fish

# assumptions:
# 3 songs in mpd's music library
# first song is 10 seconds long
# second and third songs are 6 seconds long

function setup
	mpc add /
	mpc play
end

function cleanup
	mpc clear
end

cleanup

# case 1 (expect: 5s)
setup
sleep 5
mpc pause
sleep 2
cleanup

# case 2 (expect: 8s)
setup
sleep 3
mpc pause
sleep 2
mpc play
sleep 5
cleanup

# case 3 (expect: 1s)
setup
sleep 5
mpc seek 50%
sleep 5
cleanup

# case 4 (expect: 7s, 4s)
setup
sleep 7
mpc next
sleep 4
cleanup

# case 5 (expect: 100ms, 100ms, 6s)
setup
sleep 0.1
mpc next
sleep 0.1
mpc next
sleep 6
cleanup

# case 6 (expect: 4s, 6s)
setup
sleep 4
mpc pause
sleep 2
mpc next
sleep 6
cleanup
