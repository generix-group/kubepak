package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var updateAllClustersForCmd = &cobra.Command{
	Use:   "updateAllClustersFor",
	Short: "Will go through all clusters and update them with the new cluster configuration passed in parameter.",
	Long:  "Will go through all clusters and update them with the new cluster configuration passed in parameter.",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("updateAllClustersFor called")
	},
}

func init() {
	rootCmd.AddCommand(updateAllClustersForCmd)
}
