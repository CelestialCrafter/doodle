package main

import (
	"fmt"
	"os/exec"
	"strings"
)

func fetchPlayerState() (*playerState, error) {
	playerOutputBytes, err := exec.Command("mpc", "status", "%state%").Output()
	if err != nil {
		return nil, err
	}
	playerOutput := strings.TrimSpace(string(playerOutputBytes))

	var v playerState
	switch playerOutput {
	case "stopped":
		v = stopped
	case "playing":
		v = playing
	case "paused":
		v = paused
	default:
		panic(fmt.Sprint("invalid status: ", playerOutput))
	}

	return &v, nil
}

func fetchSong() (*song, error) {
	songOutput, err := exec.Command("mpc", "status", "-f", "%title%\n%artist%\n%album%").Output()
	if err != nil {
		return nil, err
	}

	split := strings.Split(string(songOutput), "\n")
	if len(split) < 3 {
		panic("mpd status is not \"playing\", but not enough data in song output")
	}

	return &song{
		title:  split[0],
		artist: split[1],
		album:  split[2],
	}, nil
}

func fetchStatus() (*mpdStatus, error) {
	status := new(mpdStatus)

	player, err := fetchPlayerState()
	if err != nil {
		return nil, err
	}

	status.player = *player
	if status.player == stopped {
		return status, nil
	}

	status.song, err = fetchSong()
	if err != nil {
		return nil, err
	}

	return status, nil
}
