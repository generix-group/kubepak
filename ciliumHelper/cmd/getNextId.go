package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var getNextIdCmd = &cobra.Command{
	Use:   "getNextId",
	Short: "Will return the next available id to be used in the cilium cluster meshing configuration.",
	Long:  "Will return the next available id to be used in the cilium cluster meshing configuration.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(args)
		fmt.Println("getNextId called")
	},
}

func init() {
	rootCmd.AddCommand(getNextIdCmd)
}
