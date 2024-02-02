/*
Copyright © 2024 mannk khacman98@gmail.com
*/
package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"github.com/huntelaar112/goutils/utils"
	log "github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

type Global struct {
	logDir   string
	entryDir string

	procs          *Procs
	prim           *Primary
	etc_minit_cmds []*exec.Cmd

	timeout2Kill time.Duration
}

var (
	cfgFile        string
	Logger         = log.New()
	LogLevel       = log.ErrorLevel
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
	utils.InitLoggerStdout(Logger, log.InfoLevel)
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.minit.yaml)")

	viper.SetDefault("logDir", "/var/log/minit")
	viper.SetDefault("entryDir", "/etc/minit")

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
		viper.AddConfigPath("./")
		viper.SetConfigType("toml")
		viper.SetConfigName(cfgFile)
	}

	viper.AutomaticEnv() // read in environment variables that match

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			Logger.Error("config.toml file at ./ folder is not exist. Create it first.")
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

	// create logDir
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

	listDirEtcMinit, _ := utils.DirAllChild(global.entryDir)
	global.etc_minit_cmds, err = GetCommandsFormFilesofDir(global.entryDir)
	if err != nil {
		Logger.Error(err)
	} else {
		Logger.Info("List file at: ", global.entryDir, ":", listDirEtcMinit)
	}

	RunCmds(global.etc_minit_cmds, global.procs)

	if os.Getpid() == 1 {
		go Reap()
	}

	Wait(global.procs)

}

func GetCommandsFormFilesofDir(dirPath string) ([]*exec.Cmd, error) {
	var cmd *exec.Cmd
	var cmds []*exec.Cmd
	// search file in entryDir
	listEntryFile, err := utils.DirAllChild(global.entryDir)
	if err != nil {
		Logger.Error(err)
		err := utils.DirCreate(global.entryDir, 0664)
		if err != nil {
			return cmds, err
		} else {
			Logger.Infof("Folder %s is created", global.entryDir)
		}
	}
	if len(listEntryFile) <= 0 {
		//Logger.Info(global.logDir, ": Entry_directory is empty.")
		return cmds, fmt.Errorf("entry_directory is empty")
	}

	for _, fileName := range listEntryFile {
		os.Chmod(fileName, 0775)
		cmd = exec.Command("bash", "-c", fileName)
		cmds = append(cmds, cmd)
	}
	return cmds, err
}

// run all cmd, if one end or error die --> print log
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

func Wait(procs *Procs) {
	defer func() { Logger.Info("all processes exited, goodbye!") }()

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
