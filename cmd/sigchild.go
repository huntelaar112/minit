package cmd

// Adapted from https://github.com/ramr/go-reaper/blob/master/reaper.go
// No license published there...

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

// relay SIGCHID to minit to c channel.
func ChildSignal(notify chan bool) {
	var sigs = make(chan os.Signal, 3)
	signal.Notify(sigs, syscall.SIGCHLD)

	for {
		<-sigs
		select {
		case notify <- true:
		default:
			// Channel full, does not matter as we wait for all children.
		}
	}
}

func Reap() {
	var wstatus syscall.WaitStatus
	notify := make(chan bool, 1)

	go ChildSignal(notify)

	select {
	case signal := <-notify:
		if signal {
			pid, err := syscall.Wait4(-1, &wstatus, 0, nil)
			for err == syscall.EINTR {
				pid, err = syscall.Wait4(-1, &wstatus, 0, nil)
			}
			if err == syscall.ECHILD {
				// it's odd that we would get this and this used to 'break' the loop. Now
				// log this has happened, but keep waiting.
				Logger.Error("wait4() returned ECHILD")
			}
			Logger.Info("pid ", pid, "finished, wstatus: ", wstatus)
		}
	default:
		// Do nothing if no signal received
	}
}

func ProcessListAll() ([]string, error) {
	listAllProcessCmd := "ps aux | awk '{print $2}' | tail -n +3"
	cmd := exec.Command("bash", "-c", listAllProcessCmd)
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	pids := strings.Split(strings.TrimSpace(string(output)), "\n")

	return pids, err
}

func ProcessKillAll() error {
	pids, err := ProcessListAll()
	if err != nil {
		return err
	}
	for _, pid := range pids {
		cmd := exec.Command("bash", "-c", "kill ", pid)
		err := cmd.Start()
		if err != nil {
			fmt.Println("Error kill: ", err)
		}
	}

	time.Sleep(1 * time.Second)

	afterKillPids, err := ProcessListAll()
	if err != nil {
		return err
	}
	if len(afterKillPids) > 0 {
		for _, pid := range afterKillPids {
			cmd := exec.Command("bash", "-c", "kill - SIGKILL ", pid)
			err := cmd.Start()
			if err != nil {
				fmt.Println("Error kill: ", err)
			}
		}
	}
	return err
}
