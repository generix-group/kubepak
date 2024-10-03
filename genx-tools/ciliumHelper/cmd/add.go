package cmd

import (
	"ciliumHelper/utils"
	"errors"
	"fmt"
	"log"
	"net"
	"regexp"
	"strconv"

	"github.com/spf13/cobra"
)

var addCmd = &cobra.Command{
	Use:   "add",
	Short: "Will add a new cluster configuration to the sqlite database.",
	Long:  "Will add a new cluster configuration to the sqlite database.",
	Args:  cobra.RangeArgs(7, 9),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Adding the informations about the new cluster...")
		var database = utils.InitializeDB()
		defer database.Close()

		if len(args) == 8 {
			log.Fatal("Args 8 and 9 should be the cert and key, if needed.")
		}

		err := validateInput(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
		utils.CheckErr(err)

		if len(args) == 7 {
			utils.Insert(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
		} else {
			utils.InsertWithCertificate(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
		}

		fmt.Println("Adding the informations about the new cluster... Done")
	},
}

func validateInput(name string, clusterId string, ipAddress string, port string, subscription string, resourceGroup string, isProd string) error {
	fmt.Println("Validating the input...")
	if name == "" || clusterId == "" || ipAddress == "" || port == "" || subscription == "" || resourceGroup == "" || isProd == "" {
		return errors.New("all fields are required")
	}

	if utils.ClusterNameExists(name) {
		return errors.New("cluster name already exists")
	}

	id, err := strconv.Atoi(clusterId)
	if err != nil || utils.ClusterIdExists(id) {
		return errors.New("the clusterId already exists")
	}

	if !regexp.MustCompile(`^[a-zA-Z0-9]+[a-zA-Z0-9_-]*[a-zA-Z0-9]+$`).MatchString(name) {
		return errors.New("the name can contain only letters, numbers, underscores, and hyphens. The name must start and end with a letter or number")
	}

	if net.ParseIP(ipAddress) == nil || utils.IpAddressExists(ipAddress) {
		return errors.New("invalid IP address")
	}

	p, err := strconv.Atoi(port)
	if err != nil || p < 0 || p > 65535 {
		return errors.New("invalid port number")
	}

	_, err = strconv.ParseBool(isProd)
	if err != nil {
		return errors.New("invalid isProd value")
	}

	return nil
}

func init() {
	rootCmd.AddCommand(addCmd)
}
