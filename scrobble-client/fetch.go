package main

import (
	"errors"
	"fmt"
	"os/exec"
	"strconv"
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

func formattedToSeconds(formatted string) (int, error) {
	mins_str, secs_str, found := strings.Cut(formatted, ":")
	if !found {
		return 0, errors.New("could not find : separator")
	}

	mins, err := strconv.Atoi(mins_str)
	if err != nil {
		return 0, err
	}

	secs, err := strconv.Atoi(secs_str)
	if err != nil {
		return 0, err
	}

	return (mins * 60) + secs, nil
}

func fetchSong() (*song, error) {
	songOutput, err := exec.Command("mpc", "status", "-f", "%title%\n%artist%\n%album%\n%time%").Output()
	if err != nil {
		return nil, err
	}

	split := strings.Split(string(songOutput), "\n")
	if len(split) < 4 {
		panic("mpd status is not \"playing\", but not enough data in song output")
	}

	length, err := formattedToSeconds(split[3])
	if err != nil {
		panic("could not convert song length to string")
	}

	return &song{
		title:  split[0],
		artist: split[1],
		album:  split[2],
		length: length,
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
