package cmd

import (
	"ciliumHelper/utils"
	"fmt"

	"github.com/spf13/cobra"
)

var listAllCmd = &cobra.Command{
	Use:   "listAll",
	Short: "Will print all the cluster data.",
	Long:  "Will print all the cluster data.",
	Args:  cobra.ExactArgs(0),
	Run: func(cmd *cobra.Command, args []string) {
		var database = utils.InitializeDB()
		defer database.Close()

		clusters := utils.ListAllClusters()

		fmt.Printf("ID\tName\t\tClusterID\tIP Address\tPort\tSubscription\t\t\t\tResource Group\t\t\t\tProduction?\tManagement?\n")
		for _, item := range clusters {
			isProd := 'N'
			if item.IsProd {
				isProd = 'Y'
			}
			isManagement := 'N'
			if item.Key != "" {
				isManagement = 'Y'
			}
			fmt.Printf("%d\t%s\t\t%d\t%s\t%s\t%s\t%s\t%c\t\t%c\n", item.ID, item.Name, item.ClusterID, item.IP, item.Port, item.Subscription, item.ResourceGroup, isProd, isManagement)
		}

	},
}

func init() {
	rootCmd.AddCommand(listAllCmd)
}
