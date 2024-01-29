/*
Copyright © 2024 mannk khacman98@gmail.com
*/
package cmd

import (
	"os"

	"github.com/huntelaar112/goutils/utils"
	log "github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile        string
	Logger         = log.New()
	LogLevel       = log.ErrorLevel
	LogFile        = "minit.log"
	cfgFileDefault = ".minit"

	global Global
)

type Global struct {
	logDir   string
	entryDir string
}

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
	viper.SetDefault("entryDir", "/etc/minit-start")
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
	if os.Getpid() == 1 {
		go Reap()
	}

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

	// search file in entryDir
	listEntryFile, err := utils.DirAllChild(global.entryDir)
	if err != nil {
		Logger.Error(err)
	}
	if len(listEntryFile) <= 0 {
		Logger.Info(global.logDir, ": Entry_directory is empty.")
	} else {

	}
}
