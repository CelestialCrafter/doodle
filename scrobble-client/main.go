package main

import (
	"bufio"
	"os/exec"
	"time"

	"github.com/charmbracelet/log"
)

type playerState uint
const (
	playing playerState = iota
	paused
	stopped
)

type song struct {
	title  string
	artist string
	album  string
}

type mpdStatus struct {
	player playerState
	song   *song
}

func main() {
	log.Default().SetLevel(log.DebugLevel)
	cmd := exec.Command("mpc", "idleloop", "player")

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatalf("could not open pipe: %v\n", err)
	}

	log.Info("starting idle loop")
	err = cmd.Start()
	if err != nil {
		log.Fatalf("could not run idle loop: %v\n", err)
	}

	scanner := bufio.NewScanner(stdout)
	state := new(scrobbleState)

	for scanner.Scan() {
		status, err := fetchStatus()
		if err != nil {
			log.Warnf("could not get status: %v", err)
		}

		handleStatus(state, *status, time.Now().UnixMilli())
	}
}
