/*
Copyright © 2024 mannk khacman98@gmail.com
*/
package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sort"
	"syscall"
	"time"

	"github.com/huntelaar112/goutils/utils"
	log "github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

type Global struct {
	logDir      string
	entryDir    string
	preStartDir string

	//wgPostPreStart sync.WaitGroup

	procs                   *Procs
	prim                    *Primary
	etc_minit_cmds          []*exec.Cmd
	etc_minit_prestart_cmds []*exec.Cmd

	timeout2Kill time.Duration
}

var (
	cfgFile        string
	Logger         = log.New()
	LogLevel       = log.InfoLevel
	LogFile        = "minit.log"
	cfgFileDefault = ".minit"

	global Global
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "minit",
	Short: "A lightweight init system for docker container.",
	Long:  ``,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: rootRun,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	//utils.InitLogger(LogFile, Logger, LogLevel)
	utils.InitLoggerStdout(Logger, LogLevel)
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.minit)")

	viper.SetDefault("logDir", "/var/log/minit")
	viper.SetDefault("entryDir", "/etc/minit")
	viper.SetDefault("preStartDir", "/etc/minit_prestart")

	global.procs = NewProcs()
	global.prim = NewPrimary()
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := os.UserHomeDir()
		if err != nil {
			Logger.Error(err)
			os.Exit(1)
		}

		cfgFile = cfgFileDefault
		// Search config in home directory with name ".minit" (without extension).
		viper.AddConfigPath(home)
		//viper.AddConfigPath("./")
		viper.SetConfigType("toml")
		viper.SetConfigName(cfgFile)
	}

	viper.AutomaticEnv() // read in environment variables that match

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			home, _ := os.UserHomeDir()
			Logger.Infof("%s is not exist %s. Auto create at %s", cfgFileDefault, home, home)
			viper.WriteConfigAs(filepath.Join(home, cfgFileDefault))
		} else {
			Logger.Error(err)
		}
	} else {
		Logger.Info("Using config file:", viper.ConfigFileUsed())
	}
}

func rootRun(cmd *cobra.Command, args []string) {
	var err error
	global.logDir = viper.GetString("logDir")
	global.entryDir = viper.GetString("entryDir")
	global.preStartDir = viper.GetString("preStartDir")

	// create logDir (not use yet, log flush directly to stdout)
	if _, err := os.Stat(global.logDir); err != nil {
		if os.IsNotExist(err) {
			err := utils.DirCreate(global.logDir, 0755)
			if err != nil {
				Logger.Error(err)
			}
		} else {
			Logger.Error(err)
		}
	}

	Logger.Debug("Entry dir: ", global.entryDir)
	Logger.Debug("Pre start dir: ", global.preStartDir)
	global.etc_minit_cmds, err = GenExecCmds(global.entryDir)
	if err != nil {
		Logger.Error(err)
	}
	global.etc_minit_prestart_cmds, err = GenExecCmds(global.preStartDir)
	if err != nil {
		Logger.Error(err)
	}

	if os.Getpid() == 1 {
		go Reap()
	}

	Logger.Debugf("number of minit command: %d, ", len(global.etc_minit_cmds))
	Logger.Debugf("number of prestart command: %d, ", len(global.etc_minit_prestart_cmds))

	//if len(global.etc_minit_prestart_cmds) > 0 {
	/* 	global.wgPostPreStart.Add(1)
	   	go PreStartCmdsRun(global.etc_minit_prestart_cmds, global.procs, &global.wgPostPreStart)
	   	global.wgPostPreStart.Wait() */
	PreStartCmdsRun(global.etc_minit_prestart_cmds, global.procs)
	//}

	RunCmds(global.etc_minit_cmds, global.procs)
	Wait(global.procs)

	// grep all kill all process after quit
	ProcessKillAll()
}

/*
	run all cmd parallel

if one end or error die --> print log

if all die --> end function
*/
func RunCmds(cmds []*exec.Cmd, procs *Procs) {
	for i := range cmds {
		cmd := cmds[i]
		if err := cmd.Start(); err != nil {
			Logger.Error("process failed to start: ", err)
			//procs.Cleanup(syscall.SIGINT, global.timeout2Kill)
			continue
		}
		pid := cmd.Process.Pid
		Logger.Info("pid ", pid, " started: ", cmd.Args)
		procs.Insert(cmd)

		go func() {
			err := cmd.Wait()
			pid := cmd.Process.Pid

			switch err {
			default:
				// is not SyscallError type
				_, ok := err.(*os.SyscallError)
				if !ok {
					Logger.Errorf("pid %d finished: %v with error: %v", pid, cmd.Args, err)
					break
				}
				fallthrough
			case nil: // if nil or err is *os.SyscallError type.
				Logger.Infof("pid %d finished %v", pid, cmd.Args)
			}
			procs.Remove(cmd)
		}()
	}
}

/* func PreStartCmdsRun(cmds []*exec.Cmd, procs *Procs, wg *sync.WaitGroup) {
	defer wg.Done()
	var prestartProcessWg sync.WaitGroup
	for i := range cmds {
		cmd := cmds[i]
		if err := cmd.Start(); err != nil {
			Logger.Error("process failed to start: ", err)
			//procs.Cleanup(syscall.SIGINT, global.timeout2Kill)
			continue
		}
		pid := cmd.Process.Pid
		Logger.Info("pid ", pid, " started: ", cmd.Args)
		procs.Insert(cmd)

		// wait all prestart script done before exit PreStartCmdsRun function.
		prestartProcessWg.Add(1)
		go func() {
			defer prestartProcessWg.Done()
			err := cmd.Wait()
			pid := cmd.Process.Pid

			switch err {
			default:
				// is not SyscallError type
				_, ok := err.(*os.SyscallError)
				if !ok {
					Logger.Errorf("pid %d finished: %v with error: %v", pid, cmd.Args, err)
					break
				}
				fallthrough
			case nil: // if nil or err is *os.SyscallError type.
				Logger.Infof("pid %d finished %v", pid, cmd.Args)
			}
			procs.Remove(cmd)
		}()
	}
	prestartProcessWg.Wait()
} */

// start cmd sequentially
func PreStartCmdsRun(cmds []*exec.Cmd, procs *Procs) {
	for i := range cmds {
		cmd := cmds[i]
		if err := cmd.Run(); err != nil {
			Logger.Error("process failed to start: ", err)
			//procs.Cleanup(syscall.SIGINT, global.timeout2Kill)
			continue
		}
		pid := cmd.Process.Pid
		Logger.Info("pid ", pid, " started: ", cmd.Args)
		procs.Insert(cmd)
	}
}

func Wait(procs *Procs) {
	defer func() {
		Logger.Info("all processes (start at /etc/minit) exited --> start ProcessKillAll() --> goodbye!")
	}()

	// wait trigger of interrupt signal
	ints := make(chan os.Signal, 2)
	signal.Notify(ints, syscall.SIGINT, syscall.SIGTERM)

	// wait trigger of hang up signal
	other := make(chan os.Signal, 2)
	signal.Notify(other, syscall.SIGHUP)

	tick := time.Tick(100 * time.Millisecond) // 0.1 sec

	for {
		select {
		// if init have no process left
		case <-tick:
			if procs.Len() == 0 {
				return
			}
			// send sighup to all process
		case sig := <-other:
			procs.Signal(sig)
			// send sigint or sigterm to all process, after that is sigkill after timeout2Kill
		case sig := <-ints:
			procs.Cleanup(sig, global.timeout2Kill)
		}
	}
}

func GenExecCmds(dirPath string) ([]*exec.Cmd, error) {
	var cmd *exec.Cmd
	var cmds []*exec.Cmd
	// search file in entryDir
	listEntryFile, err := utils.DirAllChild(dirPath)
	if err != nil {
		Logger.Info(err)
		err := utils.DirCreate(dirPath, 0664)
		if err != nil {
			return cmds, err
		} else {
			Logger.Infof("Folder %s is created", dirPath)
		}
	}
	if len(listEntryFile) <= 0 {
		//Logger.Info(global.logDir, ": Entry_directory is empty.")
		return cmds, fmt.Errorf("%s is empty", dirPath)
	}

	sort.Strings(listEntryFile)

	for _, fileName := range listEntryFile {
		os.Chmod(fileName, 0775)
		cmd = exec.Command("bash", "-c", fileName)
		cmds = append(cmds, cmd)
	}

	if err != nil {
		Logger.Info(err)
	} else {
		Logger.Info("List file at: ", dirPath, ": ", listEntryFile)
	}

	return cmds, err
}
