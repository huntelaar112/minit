/*
Copyright © 2024 mannk khacman98@gmail.com
*/
package cmd

import (
	"strings"

	"github.com/spf13/cobra"
)

// runCmd represents the run command
var (
	runCmd = &cobra.Command{
		Use:   "run",
		Short: "minit run [OPTION...] -c \"CMD [OPTION..];[ CMD [OPTION...]]\"",
		Long:  ``,
		Run:   runRun,
	}

	commands string
)

func init() {
	rootCmd.AddCommand(runCmd)

	runCmd.Flags().StringVarP(&commands, "commands", "c", "", "List commands run directly with minit")
}

func runRun(cmd *cobra.Command, args []string) {
	listCmds := strings.Split(commands, ";")
	if len(listCmds) == 0 {
		Logger.Error("You run with no command, try to run again with commands or Run minit only.")
	}
}
