package main

import (
	"errors"
	"io"
	"net/http"
	"net/url"
	"reflect"
	"strconv"
	"time"

	"github.com/charmbracelet/log"
)

type scrobbleState struct {
	song    *song
	elapsed int64
	start   *int64
}

func emitSong(song song, duration int64) error {
	log.Infof("emitting \"%v - %v\" on \"%v\" at %vms", song.title, song.artist, song.album, duration)

	form := url.Values{
		"title":     {song.title},
		"artist":    {song.artist},
		"album":     {song.album},
		"duration":  {strconv.FormatInt(duration, 10)},
		"timestamp": {strconv.FormatInt(time.Now().UnixMilli(), 10)},
	}

	resp, err := http.PostForm("http://localhost:8540/scrobble", form)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		message, err := io.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		return errors.New(string(message))
	}

	return nil
}

func handleStatus(state *scrobbleState, status mpdStatus, time int64) {
	flush := func() {
		state.elapsed += time - *state.start
	}

	// song change
	if !reflect.DeepEqual(state.song, status.song) {
		if state.start != nil {
			flush()
		}

		if state.song != nil {
			err := emitSong(*state.song, state.elapsed)
			if err != nil {
				log.Warnf("could not emit scrobble: %s", err)
			}
		}

		state.song = status.song
		state.elapsed = 0
		state.start = nil
	}

	// player resume/pause
	if status.player == playing && state.start == nil {
		state.start = &time
	} else if status.player != playing && state.start != nil {
		flush()
		state.start = nil
	}
}
