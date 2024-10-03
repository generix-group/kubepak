package utils

import (
	"fmt"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/clientcmd/api"
)

var configAccess *clientcmd.PathOptions
var cmd *api.Config

func InitializeCMD() {
	var err error
	configAccess = clientcmd.NewDefaultPathOptions()
	cmd, err = configAccess.GetStartingConfig()
	CheckErr(err)
}

func SwitchContext(context string) {
	if cmd.CurrentContext == context {
		fmt.Printf("\nAlready on context %s\n", context)
		return
	}
	fmt.Printf("\nSwitching context from %s to %s\n", cmd.CurrentContext, context)
	err := validateContextExists(context)
	CheckErr(err)

	cmd.CurrentContext = context
	err = clientcmd.ModifyConfig(configAccess, *cmd, true)
	CheckErr(err)
}

func validateContextExists(context string) error {
	for name := range cmd.Contexts {
		if name == context {
			return nil
		}
	}

	// TODO make az cli command to get?
	return fmt.Errorf("no context exists with the name: %q", context)
}
