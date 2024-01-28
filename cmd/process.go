package cmd

import (
	"os"
	"os/exec"
	"sync"
	"syscall"
	"time"
)

// Primary holds which pid is considered the primary process. If that
// dies, the whole container should be killed.
type Primary struct {
	sync.RWMutex
	first map[int]bool
	all   bool
}

func NewPrimary() *Primary {
	return &Primary{first: make(map[int]bool)}
}

func (p *Primary) Set(pid int) {
	p.Lock()
	defer p.Unlock()
	p.first[pid] = true
}

func (p *Primary) Primary(pid int) bool {
	p.RLock()
	defer p.RUnlock()
	_, ok := p.first[pid]
	return ok
}

func (p *Primary) All() bool {
	p.RLock()
	defer p.RUnlock()
	return p.all
}

func (p *Primary) SetAll(all bool) {
	p.Lock()
	defer p.Unlock()
	p.all = all
}

// Procs holds the processes that we run.
type Procs struct {
	sync.RWMutex
	pids map[int]*exec.Cmd
}

func NewProcs() *Procs {
	return &Procs{pids: make(map[int]*exec.Cmd)}
}

func (c *Procs) Insert(cmd *exec.Cmd) {
	c.Lock()
	defer c.Unlock()
	c.pids[cmd.Process.Pid] = cmd
}

func (c *Procs) Remove(cmd *exec.Cmd) {
	c.Lock()
	defer c.Unlock()
	delete(c.pids, cmd.Process.Pid)
}

// Signal sends sig to all processes in Procs.
func (c *Procs) Signal(sig os.Signal) {
	c.RLock()
	defer c.RUnlock()
	for pid, cmd := range c.pids {
		Logger.Info("signal ", sig, "sent to pid ", pid)
		cmd.Process.Signal(sig)
	}
}

// Cleanup will send signal sig to the processes and after a short timeout send a SIGKKILL.
func (c *Procs) Cleanup(sig os.Signal, timeout time.Duration) {
	c.Signal(sig)

	time.Sleep(2 * time.Second)

	if c.Len() > 0 {
		Logger.Info(c.Len(), " processes still alive after SIGINT/SIGTERM")
		time.Sleep(timeout)
	}
	c.Signal(syscall.SIGKILL)
}

// Len returns the number of processs in Procs.
func (c *Procs) Len() int {
	c.RLock()
	defer c.RUnlock()
	return len(c.pids)
}
