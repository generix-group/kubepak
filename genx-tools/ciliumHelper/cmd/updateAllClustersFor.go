package cmd

import (
	"ciliumHelper/utils"
	"fmt"
	"github.com/spf13/cobra"
)

var updateAllClustersForCmd = &cobra.Command{
	Use:   "updateAllClustersFor",
	Short: "Will go through all clusters and update them with the new cluster configuration passed in parameter.",
	Long:  "Will go through all clusters and update them with the new cluster configuration passed in parameter.",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Updating all the clusters for the new cluster")

		var database = utils.InitializeDB()
		defer database.Close()

		fromCluster := utils.GetByName(args[0])
		println("Validated source cluster: ", fromCluster.Name)
		allClusterToDo := utils.GetAllClustersToDo(fromCluster.Name, fromCluster.IsProd)

		utils.InitializeCMD()

		for _, item := range allClusterToDo {
			fmt.Println("--------------------------------------------------------------------------------------------------")
			fmt.Println("Currently doing:")
			fmt.Printf("ID\tName\t\tClusterID\tIP Address\tPort\tSubscription\t\t\t\tResource Group\t\t\t\tManagement?\n")
			isManagement := 'N'
			if item.Key != "" {
				isManagement = 'Y'
			}
			fmt.Printf("%d\t%s\t\t%d\t%s\t%s\t%s\t%s\t%c\n", item.ID, item.Name, item.ClusterID, item.IP, item.Port, item.Subscription, item.ResourceGroup, isManagement)
			//utils.SwitchContext(item.Name)
			config := utils.ReadConfigYaml()
			modifiedConfig := utils.AddAllClusterInfoToConfig(config, utils.GetAllClustersToDo(item.Name, item.IsProd))
			utils.WriteConfigYaml(modifiedConfig)

		}

		fmt.Println("Updating all the clusters for the new cluster... done")
	},
}

func init() {
	rootCmd.AddCommand(updateAllClustersForCmd)
}
