package utils

import (
	"encoding/json"
	"gopkg.in/yaml.v3"
	"os"
	"strings"
)

var ConfigPath = "./genx-tools/ciliumHelper/config-dev.yaml"

func ReadConfigYaml() ClusterMesh {
	yamlData, err := os.ReadFile(ConfigPath)
	CheckErr(err)

	return parseYaml(yamlData)
}

func parseYaml(data []byte) ClusterMesh {
	var config Config
	err := yaml.Unmarshal(data, &config)
	CheckErr(err)

	for _, packageInfo := range config.Values {
		if strings.HasPrefix(packageInfo, "cilium") {
			packageInfo := strings.Trim(packageInfo, "cilium=")

			var clustermesh ClusterMesh
			err := yaml.Unmarshal([]byte(packageInfo), &clustermesh)
			CheckErr(err)

			return clustermesh
		}
	}
	// TODO HANDLE NO CILIUM CONFIG
	return ClusterMesh{}
}

func AddAllClusterInfoToConfig(config ClusterMesh, toAdd []Cluster) ClusterMesh {
	var clusterMeshValuesConfigClusters []ClusterMeshValuesConfigClusters

	for _, cluster := range toAdd {
		var clusterMeshValuesConfigCluster ClusterMeshValuesConfigClusters
		clusterMeshValuesConfigCluster.Name = cluster.Name
		clusterMeshValuesConfigCluster.Port = cluster.Port
		clusterMeshValuesConfigCluster.Ips = []string{cluster.IP}
		clusterMeshValuesConfigClusters = append(clusterMeshValuesConfigClusters, clusterMeshValuesConfigCluster)
	}

	config.Values.Config.Clusters = clusterMeshValuesConfigClusters

	return config
}

func WriteConfigYaml(config ClusterMesh) {
	configAsByte, err := json.Marshal(&config.Values)
	CheckErr(err)

	configAsString := "cilium=" + string(configAsByte[:])
	println(configAsString)
}

type Config struct {
	Values []string `yaml:"values"`
}

type ClusterMesh struct {
	Values ClusterMeshValues `yaml:"clustermesh" json:"clustermesh"`
}

type ClusterMeshValues struct {
	UseAPIServer bool                    `yaml:"useAPIServer" json:"useAPIServer"`
	Config       ClusterMeshValuesConfig `yaml:"config" json:"config"`
}

type ClusterMeshValuesConfig struct {
	Enabled  bool                              `yaml:"enabled" json:"enabled"`
	Clusters []ClusterMeshValuesConfigClusters `yaml:"clusters" json:"clusters"`
}

type ClusterMeshValuesConfigClusters struct {
	Name string   `yaml:"name" json:"name"`
	Port string   `yaml:"port" json:"port"`
	Ips  []string `yaml:"ips" json:"ips"`
}
